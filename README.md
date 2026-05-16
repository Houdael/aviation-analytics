# Aviation Analytics Platform

End-to-end aviation analytics platform tracking daily flight activity across 10 major European airports.

---

## Business questions

- **On-time performance** — which airlines and routes are most punctual?
- **Delay patterns** — when and where do delays cluster by airport and time of day?
- **Route popularity** — how do route volumes trend over time?
- **Airline reliability** — how do airlines rank on operational reliability?
- **Airport traffic** — what are weekly and monthly traffic volumes per airport?

---

## Airports in scope

| IATA | ICAO | Airport | City |
|------|------|---------|------|
| CDG | LFPG | Charles de Gaulle | Paris |
| LHR | EGLL | Heathrow | London |
| AMS | EHAM | Schiphol | Amsterdam |
| FRA | EDDF | Frankfurt | Frankfurt |
| MAD | LEMD | Adolfo Suárez Barajas | Madrid |
| FCO | LIRF | Leonardo da Vinci Fiumicino | Rome |
| BCN | LEBL | El Prat | Barcelona |
| BRU | EBBR | Brussels | Brussels |
| ZRH | LSZH | Zurich | Zurich |
| LIS | LPPT | Humberto Delgado | Lisbon |

---

## Tech stack

| Layer | Tool |
|-------|------|
| Ingestion | [dlt](https://dlthub.com) |
| Data warehouse | Snowflake |
| Transformation | dbt |
| Orchestration | Dagster |
| AI / enrichment | Snowflake Cortex |
| Reporting | Power BI |

---

## Architecture

```
OpenSky Network API
        │
        ▼
  [ Ingestion ]  dlt pipeline
        │
        ▼
   RAW schema    (raw flight records, loaded daily)
        │
        ▼
STAGING schema   (cleaned, typed, surrogate keys)
        │
        ▼
  MARTS schema   (aggregated, business-ready models)
        │
        ▼
    Power BI
```

Snowflake hosts three schemas in two databases:

| Environment | Database |
|-------------|----------|
| Development | `AVIATION_ANALYTICS_DEV` |
| Production  | `AVIATION_ANALYTICS_PROD` |

---

## Data source

[OpenSky Network API](https://opensky-network.org) — ADS-B flight data, non-commercial use.
Arrivals and departures are pulled daily for each airport via the `/flights/arrival` and `/flights/departure` endpoints.

---

## Project structure

```
aviation-analytics/
├── ingestion/                        # dlt ingestion pipeline
│   └── opensky_pipeline.py
├── transformations/
│   └── aviation_analytics/           # dbt project
│       ├── models/
│       │   └── staging/              # staging layer
│       ├── seeds/                    # static reference data
│       └── macros/
└── orchestration/                    # Dagster jobs (coming soon)
```

---

## Setup

### 1. Install dependencies

```bash
python -m venv .venv
source .venv/bin/activate
pip install dlt[snowflake] requests
```

### 2. Configure OpenSky credentials

Set the following environment variables (or add them to `.dlt/secrets.toml`):

```bash
export OPENSKY_CLIENT_ID=your_client_id
export OPENSKY_CLIENT_SECRET=your_client_secret
```

### 3. Configure Snowflake credentials

Create `.dlt/secrets.toml` (never committed):

```toml
[destination.snowflake.credentials]
database = "AVIATION_ANALYTICS_DEV"
account = "your_account"
user = "your_user"
password = "your_password"
warehouse = "AVIATION_DBT_DEV_WH"
role = "AVIATION_DBT_DEV_ROLE"
```

### 4. Configure dbt

Create `~/.dbt/profiles.yml`:

```yaml
aviation_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: your_account
      user: your_user
      password: your_password
      database: AVIATION_ANALYTICS_DEV
      warehouse: AVIATION_DBT_DEV_WH
      schema: staging
      role: AVIATION_DBT_DEV_ROLE
```

### 5. Run the pipeline

```bash
# Ingest yesterday's flights
python ingestion/opensky_pipeline.py

# Run dbt transformations
cd transformations/aviation_analytics
dbt deps
dbt run
dbt test
```

---

## Current status

| Component | Status |
|-----------|--------|
| dlt ingestion pipeline | ✅ Complete |
| dbt staging layer | ✅ Complete |
| dbt marts layer | ✅ Complete |
| dbt docs | ✅ Complete |
| Dagster orchestration | 📋 Planned |
| Snowflake Cortex AI layer | 📋 Planned |
| Power BI reports | 📋 Planned |
| GitHub Actions CI/CD | 📋 Planned |
