# Contributing

## Project stack

| Layer | Tool |
|---|---|
| Ingestion | [dlt](https://dlthub.com) |
| Data warehouse | Snowflake |
| Transformation | dbt |
| Orchestration | Dagster |
| CI/CD | GitHub Actions |
| Reporting | Streamlit |

## Environments

We maintain two Snowflake databases:

| Database | Purpose |
|---|---|
| `AVIATION_ANALYTICS_DEV` | Day-to-day development and testing |
| `AVIATION_ANALYTICS_PROD` | Production data, loaded by the Dagster pipeline |

### Snowflake infrastructure

| Resource | DEV | PROD |
|---|---|---|
| Database | `AVIATION_ANALYTICS_DEV` | `AVIATION_ANALYTICS_PROD` |
| Warehouse | `AVIATION_DBT_DEV_WH` | `AVIATION_DBT_PROD_WH` |
| Role | `AVIATION_DBT_DEV_ROLE` | `AVIATION_DBT_PROD_ROLE` |

### Local configuration

`secrets.toml` (dlt's local secrets file, never committed) must point to `AVIATION_ANALYTICS_DEV` by default. This ensures that running any pipeline or dbt command locally cannot affect production data.

```toml
[destination.snowflake.credentials]
database = "AVIATION_ANALYTICS_DEV"
```

To run against production intentionally, override the database at the CLI or via a separate secrets profile — never change the default in `secrets.toml`.

### dbt profiles.yml

A `profiles.yml` file is committed at `transformations/aviation_analytics/profiles.yml` and used in CI via `--profiles-dir .`. It reads all sensitive values from environment variables using `env_var()`. You do not need a `~/.dbt/profiles.yml` locally — set the required environment variables instead:

```bash
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_user
export DBT_SNOWFLAKE_PASSWORD=your_password
```

## Elementary setup

[Elementary](https://www.elementary-data.com/) is used for data observability — it collects dbt test results, run results, and model metadata into a dedicated `elementary` schema in Snowflake.

### Running `edr report` locally

The Elementary CLI (`edr`) reads from a separate `elementary` profile in `~/.dbt/profiles.yml`. This profile is **not** committed to the repo (it contains credentials) and must be created manually on each machine.

Add the following to `~/.dbt/profiles.yml`, replacing the placeholders:

```yaml
elementary:
  outputs:
    default:
      type: snowflake
      account: <your_snowflake_account>
      user: <your_snowflake_user>
      password: <your_snowflake_password>
      database: AVIATION_ANALYTICS_DEV
      schema: elementary
      warehouse: AVIATION_DBT_DEV_WH
      role: AVIATION_DBT_DEV_ROLE
  target: default
```

Once the profile is in place, generate a report with:

```bash
edr report
```

This produces a self-contained HTML report with test results, model run history, and data health metrics based on what Elementary collected during the last `dbt build` or `dbt test` run.

## GitHub Actions

### Schedule trigger and default branch

The `daily_pipeline.yml` schedule trigger (`cron`) only fires on the **default branch** (usually `main`). Pushing the workflow to a feature branch will not activate the schedule — it must be merged to the default branch first. Use `workflow_dispatch` to trigger it manually from any branch.

### dlt Snowflake credentials in CI

dlt reads Snowflake credentials from environment variables using double-underscore `__` as a separator for nested config keys:

```
DESTINATION__SNOWFLAKE__CREDENTIALS__DATABASE
DESTINATION__SNOWFLAKE__CREDENTIALS__USERNAME
DESTINATION__SNOWFLAKE__CREDENTIALS__PASSWORD
DESTINATION__SNOWFLAKE__CREDENTIALS__HOST
DESTINATION__SNOWFLAKE__CREDENTIALS__WAREHOUSE
DESTINATION__SNOWFLAKE__CREDENTIALS__ROLE
```

**Important:** `DESTINATION__SNOWFLAKE__CREDENTIALS__HOST` must be the bare account identifier only — do **not** append `.snowflakecomputing.com`. dlt adds the suffix automatically.

```yaml
# ✅ correct
DESTINATION__SNOWFLAKE__CREDENTIALS__HOST: ${{ secrets.SNOWFLAKE_ACCOUNT }}

# ❌ incorrect — causes connection failure
DESTINATION__SNOWFLAKE__CREDENTIALS__HOST: ${{ secrets.SNOWFLAKE_ACCOUNT }}.snowflakecomputing.com
```

## Architecture Decision Records

### ADR-001 — No intermediate layer

The staging-to-marts transformation logic is straightforward enough that an intermediate layer would add structural overhead without meaningful reuse. Models are kept flat and readable. If cross-mart reuse logic emerges in the future, an intermediate layer will be introduced at that point.

### ADR-002 — dbt Snapshots for slow-changing dimensions

dbt Snapshots will be used to track slow-changing dimensions, specifically aircraft operator changes over time. An aircraft can change airline, and capturing that history enables accurate historical analysis of airline reliability without data loss. Snapshots will be applied to the `stg_aircraft` model.

### ADR-003 — dbt Docs generated in CI

`dbt docs generate` will be run as part of the CI pipeline to produce a browsable data catalog on every merge. This automatically documents model lineage, column descriptions, and test coverage, keeping the catalog in sync with the codebase without manual effort.

### ADR-004 — dbt Model Contracts on mart models

Contracts will be enforced on all mart models to guarantee column-level stability. This prevents breaking changes (renamed or dropped columns) from reaching downstream consumers (Streamlit, Snowflake Cortex) silently. Any intentional schema change on a mart model requires an explicit contract update, making it a deliberate and reviewable decision.

## Git conventions

### Commit message format

We follow [Conventional Commits](https://www.conventionalcommits.org/). Every commit message must start with a type prefix:

| Prefix | When to use |
|---|---|
| `feat:` | New feature or behaviour |
| `fix:` | Bug fix |
| `chore:` | Maintenance, dependency updates, config changes |
| `docs:` | Documentation only |
| `refactor:` | Code restructuring with no behaviour change |

Examples:

```
feat: add fetch_flights function for OpenSky API
fix: normalize dataset name to lowercase
chore: pin dlt to 0.4.x
docs: add CONTRIBUTING.md
refactor: extract token refresh logic into TokenManager
```

### Rules

- **English only** — commit messages, comments, and docstrings must be written in English.
- **One commit per logical change** — do not bundle unrelated changes into a single commit. If two changes can be reverted independently, they belong in separate commits.
- **Imperative mood** — write the subject line as a command: "add X", "fix Y", not "added X" or "fixes Y".
- **No period at the end** of the subject line.

## Known limitations

### OpenSky API reliability

The OpenSky Network API is a free service and can be intermittently unavailable. Two known failure modes:

1. **Auth server timeout (`auth.opensky-network.org`)** — if OpenSky's OAuth2 server is down, the pipeline cannot authenticate and will fail. The retry strategy (3 retries, exponential backoff) mitigates transient failures but cannot recover from a full outage.
2. **404 on recent dates** — OpenSky data for the last 24–48h is often not yet available. The pipeline handles this gracefully by skipping and logging a warning instead of failing.

To backfill missing dates, temporarily change `yesterday` in `run_pipeline()` to a specific date and run locally:

```python
yesterday = date(2026, 5, 22)  # replace with target date
```

Remember to restore the original line after backfilling. Do not commit the temporary change.

### Idempotent pipeline

The pipeline is idempotent — re-running it for the same date will not produce duplicates. This is enforced at two layers:

1. **dlt `write_disposition='merge'`** — dlt uses `(icao24, firstSeen, flight_type)` as a composite primary key when loading into `RAW`. Re-loading the same day upserts existing records rather than appending new ones. This replaces the previous `write_disposition='append'` strategy, which would insert duplicate rows on every re-run.
2. **Staging deduplication** — `stg_flights` applies a `QUALIFY ROW_NUMBER() OVER (PARTITION BY icao24, first_seen_at, flight_type ORDER BY _dlt_load_id DESC) = 1` as a defense-in-depth measure, keeping only the most recently loaded record per logical flight in the unlikely event that overlapping load batches slip through.
