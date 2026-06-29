# Repository Guidelines

## Project Structure & Module Organization

This repository contains a dbt project for the Libera analytics pipeline. The dbt project lives in `libera_dbt/`; run dbt commands from that directory unless noted otherwise. Models are organized by layer: `models/staging/reports/` for source-shaped views, `models/warehouse/int/` for ephemeral intermediate models, `models/warehouse/dimensions/` and `models/warehouse/facts/` for warehouse entities, and `models/marts/` for final table outputs. Model and source tests/documentation live beside each layer in `_...__models.yml` or `_...__sources.yml` files. Reusable dbt macros are in `libera_dbt/macros/`, ad hoc SQL analyses are in `libera_dbt/analyses/`, and architecture/lineage assets are in `docs/`.

## Build, Test, and Development Commands

- `cd libera_dbt`: enter the dbt project before running dbt.
- `dbt deps`: install packages from `packages.yml`.
- `dbt debug --profiles-dir ~/.dbt --target <target>`: validate the Databricks connection and profile.
- `dbt build --profiles-dir ~/.dbt --target <target>`: compile, run, and test all selected models.
- `dbt build --select mart_facturacion --profiles-dir ~/.dbt --target <target>`: build and test one mart while iterating.
- `dbt clean`: remove generated `target/` and `dbt_packages/` directories.

CI runs dbt on pull requests to `main` using Python 3.13 and Databricks secrets.

## Coding Style & Naming Conventions

Use SQL files with lowercase snake_case names. Follow dbt layer prefixes already in use: `stg_reports__...` for staging, `int_...` for intermediate models, `dim_...` for dimensions, `fct_...` for facts, `bridge_...` for bridge tables, and `mart_...` for marts. Keep CTE names descriptive and column aliases stable, especially keys such as `venta_key`, `factura_key`, and `uuid`. Prefer two-space indentation in YAML files and consistent SQL indentation within each model. Add schema tests and descriptions in the layer YAML when adding or changing model contracts.

## Staging Conventions

- Staging models are 1:1 with source tables
- Named: stg_<source>__<table_name>.sql
- Always materialized as views
- Only staging models select from sources

## Testing Guidelines

Testing uses dbt schema tests declared in YAML. At minimum, add `unique` and `not_null` tests for primary keys and required business identifiers. Add `not_null` tests for required measures used by marts. Run `dbt build --select <model>` before opening a PR, and run a full `dbt build` when changes affect shared staging, warehouse, or macro logic.

## Commit & Pull Request Guidelines

Recent commits use short imperative messages, for example `Add CI workflow and dbt profiles configuration` or `Remove profiles.yml from repository`. Keep commit titles concise and action-oriented. Pull requests should describe the changed models, note any Databricks/profile or secret requirements, include the dbt command run, and mention affected marts or downstream docs. Do not commit local `profiles.yml`, `target/`, `dbt_packages/`, or log output.

## Security & Configuration Tips

Keep Databricks credentials in environment variables or local `~/.dbt/profiles.yml`. CI expects repository secrets for the Databricks host, HTTP path, and token. Avoid hard-coding catalog, schema, host, or token values in model SQL.
