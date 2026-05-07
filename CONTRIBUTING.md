# Contributing

## Project stack

| Layer | Tool |
|---|---|
| Ingestion | [dlt](https://dlthub.com) |
| Data warehouse | Snowflake |
| Transformation | dbt |
| Orchestration | Dagster |
| Reporting | Power BI |

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
