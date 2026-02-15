"""CLI entrypoint for dbt Guardian."""

from pathlib import Path

import click
from rich.console import Console
from rich.table import Table

from .analyzers import TestCoverageAnalyzer
from .generators import SchemaYamlGenerator
from .parsers import CatalogParser, ManifestParser, ProjectParser

console = Console()


@click.group()
@click.version_option(version="0.1.0")
def cli() -> None:
    """dbt Guardian — Autonomous reliability agents for dbt projects."""
    pass


@cli.command()
@click.argument("project_path", type=click.Path(exists=True, path_type=Path))
@click.option(
    "--priority",
    type=int,
    default=3,
    help="Show gaps with priority <= N (1=critical, 5=low)",
)
def analyze(project_path: Path, priority: int) -> None:
    """Analyze a dbt project for test coverage gaps.

    PROJECT_PATH: Path to dbt project root directory
    """
    console.print(f"[bold]Analyzing dbt project:[/bold] {project_path}")

    # Find manifest and catalog
    manifest_path = project_path / "target" / "manifest.json"
    catalog_path = project_path / "target" / "catalog.json"

    if not manifest_path.exists():
        console.print(
            "[red]Error:[/red] manifest.json not found. "
            "Run 'dbt compile' or 'dbt run' first.",
            style="red",
        )
        raise click.Abort()

    # Parse files
    try:
        manifest_parser = ManifestParser()
        manifest = manifest_parser.parse(manifest_path)

        # Parse catalog if available
        catalog = None
        if catalog_path.exists():
            catalog_parser = CatalogParser()
            catalog = catalog_parser.parse(catalog_path)
            console.print("[dim]Found catalog.json — using warehouse metadata[/dim]")

        # Analyze coverage
        analyzer = TestCoverageAnalyzer()
        report = analyzer.analyze(manifest, catalog)

        # Display summary
        summary_table = Table(title="Coverage Summary")
        summary_table.add_column("Metric", style="cyan")
        summary_table.add_column("Value", style="green")

        summary_table.add_row("Models", str(report.total_models))
        summary_table.add_row("Columns", str(report.total_columns))
        summary_table.add_row("Tested Columns", str(report.tested_columns))
        summary_table.add_row("Coverage", f"{report.coverage_percentage:.1f}%")
        summary_table.add_row("Gaps Found", str(len(report.gaps)))
        summary_table.add_row("High Priority Gaps", str(len(report.high_priority_gaps)))

        console.print(summary_table)

        # Display top gaps
        filtered_gaps = [g for g in report.gaps if g.priority <= priority]
        if filtered_gaps:
            console.print(
                f"\n[bold]Top Gaps (priority <= {priority}):[/bold]"
            )
            gaps_table = Table()
            gaps_table.add_column("Priority", style="yellow")
            gaps_table.add_column("Model", style="cyan")
            gaps_table.add_column("Column", style="blue")
            gaps_table.add_column("Suggested Tests", style="green")
            gaps_table.add_column("Rationale", style="dim")

            for gap in filtered_gaps[:20]:  # Show top 20
                tests = ", ".join(t.value for t in gap.suggested_tests)
                gaps_table.add_row(
                    str(gap.priority),
                    gap.model_name,
                    gap.column_name,
                    tests,
                    gap.rationale,
                )

            console.print(gaps_table)

            if len(filtered_gaps) > 20:
                console.print(
                    f"\n[dim]... and {len(filtered_gaps) - 20} more gaps[/dim]"
                )

        console.print(
            "\n[green]✓[/green] Analysis complete! "
            "Run 'dbt-guardian generate-tests' to create schema.yml"
        )

    except Exception as e:
        console.print(f"[red]Error:[/red] {e}", style="red")
        raise click.Abort()


@cli.command()
@click.argument("project_path", type=click.Path(exists=True, path_type=Path))
@click.option(
    "--output",
    "-o",
    type=click.Path(path_type=Path),
    help="Output file path (default: schema_suggestions.yml)",
)
@click.option(
    "--priority",
    type=int,
    default=3,
    help="Include gaps with priority <= N (1=critical, 5=low)",
)
@click.option(
    "--merge/--no-merge",
    default=False,
    help="Merge with existing schema.yml instead of creating new file",
)
@click.option(
    "--existing-schema",
    type=click.Path(exists=True, path_type=Path),
    help="Path to existing schema.yml (required if --merge)",
)
def generate_tests(
    project_path: Path,
    output: Path | None,
    priority: int,
    merge: bool,
    existing_schema: Path | None,
) -> None:
    """Generate schema.yml with test suggestions.

    PROJECT_PATH: Path to dbt project root directory
    """
    console.print(f"[bold]Generating test suggestions:[/bold] {project_path}")

    # Find manifest and catalog
    manifest_path = project_path / "target" / "manifest.json"
    catalog_path = project_path / "target" / "catalog.json"

    if not manifest_path.exists():
        console.print(
            "[red]Error:[/red] manifest.json not found. "
            "Run 'dbt compile' or 'dbt run' first.",
            style="red",
        )
        raise click.Abort()

    # Parse files
    try:
        manifest_parser = ManifestParser()
        manifest = manifest_parser.parse(manifest_path)

        catalog = None
        if catalog_path.exists():
            catalog_parser = CatalogParser()
            catalog = catalog_parser.parse(catalog_path)

        # Analyze coverage
        analyzer = TestCoverageAnalyzer()
        report = analyzer.analyze(manifest, catalog)

        # Generate YAML
        generator = SchemaYamlGenerator()
        output_path = output or (project_path / "schema_suggestions.yml")

        if merge:
            if not existing_schema:
                console.print(
                    "[red]Error:[/red] --existing-schema required when using --merge",
                    style="red",
                )
                raise click.Abort()

            yaml_content = generator.generate_incremental(
                report, existing_schema, output_path, priority
            )
            console.print(f"[green]✓[/green] Merged suggestions into: {output_path}")
        else:
            yaml_content = generator.generate(report, output_path, priority)
            console.print(f"[green]✓[/green] Generated: {output_path}")

        # Show summary
        filtered_gaps = [g for g in report.gaps if g.priority <= priority]
        console.print(
            f"\n[cyan]Coverage:[/cyan] {report.coverage_percentage:.1f}%"
        )
        console.print(
            f"[cyan]Suggestions:[/cyan] {len(filtered_gaps)} tests "
            f"(priority <= {priority})"
        )
        console.print(
            "\n[yellow]Next steps:[/yellow]\n"
            "1. Review schema_suggestions.yml\n"
            "2. Customize accepted_values and relationships tests\n"
            "3. Remove [AUTO] prefixes from descriptions\n"
            "4. Copy relevant tests to your models/ directory\n"
            "5. Run 'dbt test' to validate"
        )

    except Exception as e:
        console.print(f"[red]Error:[/red] {e}", style="red")
        raise click.Abort()


@cli.command()
@click.argument("project_path", type=click.Path(exists=True, path_type=Path))
def info(project_path: Path) -> None:
    """Show dbt project information.

    PROJECT_PATH: Path to dbt project root directory
    """
    console.print(f"[bold]dbt Project Info:[/bold] {project_path}")

    # Parse project file
    project_file = project_path / "dbt_project.yml"
    if not project_file.exists():
        console.print(
            "[red]Error:[/red] dbt_project.yml not found. "
            "Is this a dbt project?",
            style="red",
        )
        raise click.Abort()

    try:
        parser = ProjectParser()
        project = parser.parse_project(project_file)

        console.print(f"\n[cyan]Name:[/cyan] {project.name}")
        console.print(f"[cyan]Version:[/cyan] {project.version}")
        console.print(f"[cyan]Profile:[/cyan] {project.profile}")
        console.print(f"[cyan]Model paths:[/cyan] {', '.join(project.model_paths)}")
        console.print(f"[cyan]Test paths:[/cyan] {', '.join(project.test_paths)}")

    except Exception as e:
        console.print(f"[red]Error:[/red] {e}", style="red")
        raise click.Abort()


if __name__ == "__main__":
    cli()
