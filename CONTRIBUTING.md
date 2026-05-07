# Contributing

## Project stack

| Layer | Tool |
|---|---|
| Ingestion | [dlt](https://dlthub.com) |
| Data warehouse | Snowflake |
| Transformation | dbt |
| Orchestration | Dagster |
| Reporting | Power BI |

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
