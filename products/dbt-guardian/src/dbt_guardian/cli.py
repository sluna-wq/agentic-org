"""CLI entrypoint for dbt Guardian."""

from pathlib import Path

import click
from rich.console import Console
from rich.table import Table

from .parsers import ManifestParser, CatalogParser, ProjectParser

console = Console()


@click.group()
@click.version_option(version="0.1.0")
def cli() -> None:
    """dbt Guardian — Autonomous reliability agents for dbt projects."""
    pass


@cli.command()
@click.argument("project_path", type=click.Path(exists=True, path_type=Path))
def analyze(project_path: Path) -> None:
    """Analyze a dbt project for test coverage gaps.

    PROJECT_PATH: Path to dbt project root directory
    """
    console.print(f"[bold]Analyzing dbt project:[/bold] {project_path}")

    # Find manifest
    manifest_path = project_path / "target" / "manifest.json"
    if not manifest_path.exists():
        console.print(
            "[red]Error:[/red] manifest.json not found. "
            "Run 'dbt compile' or 'dbt run' first.",
            style="red",
        )
        raise click.Abort()

    # Parse manifest
    try:
        parser = ManifestParser()
        manifest = parser.parse(manifest_path)

        # Display summary
        table = Table(title="Project Summary")
        table.add_column("Metric", style="cyan")
        table.add_column("Count", style="green")

        table.add_row("Models", str(len(manifest.models)))
        table.add_row("Tests", str(len(manifest.tests)))
        table.add_row("Sources", str(len(manifest.sources)))

        console.print(table)
        console.print("\n[green]✓[/green] Analysis complete!")

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
