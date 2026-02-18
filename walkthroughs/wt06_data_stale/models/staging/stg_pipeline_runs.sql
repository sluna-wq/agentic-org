-- stg_pipeline_runs: one row per pipeline execution, with parsed fields
-- Grain: one row per run_id
-- Source: raw.raw_pipeline_runs
--
-- KEY TRANSFORMATION: derives a boolean `ran_mart_models` from the models_run column.
-- When models_run = 'all' or is null/blank, all models ran (including marts).
-- When models_run = 'staging.*', only staging models ran — marts were SKIPPED.
-- This column is the primary diagnostic signal for the staleness investigation.

with source as (

    select * from {{ ref('raw_pipeline_runs') }}

),

staged as (

    select
        run_id,
        cast(run_date as date)          as run_date,
        lower(status)                   as status,
        cast(exit_code as int)          as exit_code,
        models_run,
        cast(duration_seconds as int)   as duration_seconds,

        -- derived: did this run include mart models?
        case
            when models_run = 'all' or models_run is null or models_run = ''
                then true
            when models_run like 'staging%'
                then false
            else true  -- explicit mart selector or other broad selector
        end                             as ran_mart_models,

        -- derived: was this a "phantom success"?
        -- exit_code = 0 but marts were not run = silent partial execution
        case
            when exit_code = 0
              and (models_run like 'staging%')
                then true
            else false
        end                             as is_phantom_success,

        -- derived: approximate models skipped (staging-only runs are ~75% shorter)
        case
            when models_run like 'staging%'
                then 'mart models skipped'
            else 'all models ran'
        end                             as run_scope_label

    from source

)

select * from staged
