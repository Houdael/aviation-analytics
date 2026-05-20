# Aviation Analytics Platform

End-to-end aviation analytics platform tracking daily flight activity across 10 major European airports. Built on a modern data stack — from raw ADS-B data ingestion through transformation, orchestration, AI-powered querying, and interactive dashboarding.

---

## 🔗 Live

| | URL |
|---|---|
| **Streamlit dashboard** | [aviation-analytics-hel.streamlit.app](https://aviation-analytics-hel.streamlit.app) |
| **dbt docs** | [houdael.github.io/aviation-analytics](https://houdael.github.io/aviation-analytics) |

---

## Business questions

- **Airport traffic** — what are the weekly and monthly flight volumes per airport?
- **Route popularity** — which routes are the most active, and how has demand evolved over time?
- **Airline reliability** — which airlines operate the most flights, and how consistent are they?
- **On-time performance** — how does flight duration vary by airline and route?
- **Traffic patterns** — at what times of day is each airport busiest?

---

## Airports in scope

| IATA | ICAO | Airport | City | Country |
|------|------|---------|------|---------|
| LHR | EGLL | Heathrow | London | United Kingdom |
| CDG | LFPG | Charles de Gaulle | Paris | France |
| AMS | EHAM | Schiphol | Amsterdam | Netherlands |
| FRA | EDDF | Frankfurt | Frankfurt | Germany |
| MAD | LEMD | Adolfo Suárez Barajas | Madrid | Spain |
| FCO | LIRF | Leonardo da Vinci Fiumicino | Rome | Italy |
| BCN | LEBL | El Prat | Barcelona | Spain |
| BRU | EBBR | Brussels | Brussels | Belgium |
| ZRH | LSZH | Zurich | Zurich | Switzerland |
| LIS | LPPT | Humberto Delgado | Lisbon | Portugal |

---

## Tech stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Ingestion | [dlt](https://dlthub.com) | Pulls daily flight data from OpenSky Network API into Snowflake |
| Data warehouse | Snowflake | Stores raw, staging, marts, and snapshot layers |
| Transformation | dbt | Models, tests, snapshots, contracts, and docs |
| Orchestration | Dagster | Schedules and monitors the daily pipeline |
| CI/CD | GitHub Actions | Runs dbt compile/test on every push, daily pipeline, dbt docs deployment |
| AI | Snowflake Cortex | Natural-language querying via Cortex Analyst |
| Reporting | Streamlit | Interactive dashboard with 5 pages including Ask Cortex |

---

## Architecture

```
OpenSky Network API  (ADS-B flight data)
          │
          ▼
    [ dlt pipeline ]  ingestion/opensky_pipeline.py
          │
          ▼
  RAW schema          raw flight records, loaded daily
          │
          ▼
STAGING schema        stg_flights, stg_aircraft — cleaned, typed, surrogate keys
          │
          ▼
  MARTS schema        fct_flights, dim_airports, dim_airlines
                      mart_airport_traffic, mart_route_popularity
                      mart_airline_reliability, mart_on_time_performance
                      mart_traffic_patterns
          │
    ┌─────┴──────┐
    ▼            ▼
Streamlit    Snowflake Cortex Analyst
dashboard    (natural-language queries
(5 pages)     via semantic view)
```

### Snowflake databases

| Environment | Database |
|-------------|----------|
| Development | `AVIATION_ANALYTICS_DEV` |
| Production  | `AVIATION_ANALYTICS_PROD` |

### Snowflake infrastructure

| Resource | DEV | PROD |
|----------|-----|------|
| Warehouse | `AVIATION_DBT_DEV_WH` | `AVIATION_DBT_PROD_WH` |
| Role | `AVIATION_DBT_DEV_ROLE` | `AVIATION_DBT_PROD_ROLE` |

---

## Data source

[OpenSky Network API](https://opensky-network.org) — crowdsourced ADS-B flight data, non-commercial use.
Arrivals and departures are pulled daily for each of the 10 airports via the `/flights/arrival` and `/flights/departure` endpoints. Aircraft reference data is loaded from the OpenSky aircraft database.

---

## Project structure

```
aviation-analytics/
├── ingestion/
│   └── opensky_pipeline.py           # dlt pipeline — OpenSky API → Snowflake RAW
│
├── transformations/
│   └── aviation_analytics/           # dbt project
│       ├── models/
│       │   ├── staging/              # stg_flights, stg_aircraft + sources + docs
│       │   └── marts/                # fct, dim, mart models + contracts + docs
│       ├── snapshots/
│       │   └── aircraft_snapshot.sql # SCD Type 2 — aircraft operator history
│       ├── seeds/
│       │   └── airports.csv          # static airport reference data
│       ├── macros/
│       │   └── generate_schema_name.sql
│       ├── profiles.yml              # dbt Snowflake connection (env vars)
│       └── packages.yml              # dbt_utils
│
├── orchestration/
│   └── aviation_analytics/           # Dagster project
│       └── aviation_analytics/
│           ├── assets.py             # dlt + dbt assets
│           └── definitions.py        # resources, jobs, daily 06:00 UTC schedule
│
├── cortex/
│   └── semantic_model.yml            # Snowflake Cortex Analyst semantic model
│
├── streamlit/
│   ├── streamlit_app.py              # Streamlit dashboard (5 pages)
│   └── requirements.txt
│
├── .github/
│   └── workflows/
│       ├── ci.yml                    # dbt compile + test on every push
│       ├── daily_pipeline.yml        # ingestion + dbt run/snapshot/test at 06:00 UTC
│       └── dbt_docs.yml              # dbt docs generate + GitHub Pages deploy on develop
│
├── CONTRIBUTING.md
└── README.md
```

---

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/Houdael/aviation-analytics.git
cd aviation-analytics
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure OpenSky credentials

```bash
export OPENSKY_CLIENT_ID=your_client_id
export OPENSKY_CLIENT_SECRET=your_client_secret
```

### 3. Configure Snowflake credentials for dlt

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

The `profiles.yml` is committed at `transformations/aviation_analytics/profiles.yml` and reads from environment variables. Set:

```bash
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_user
export DBT_SNOWFLAKE_PASSWORD=your_password
# Optional — defaults to AVIATION_ANALYTICS_DEV and AVIATION_DBT_DEV_WH
export SNOWFLAKE_DATABASE=AVIATION_ANALYTICS_DEV
export SNOWFLAKE_WAREHOUSE=AVIATION_DBT_DEV_WH
```

### 5. Run the pipeline

```bash
# Ingest yesterday's flights
python ingestion/opensky_pipeline.py

# Run dbt
cd transformations/aviation_analytics
dbt deps --profiles-dir .
dbt run --profiles-dir .
dbt snapshot --profiles-dir .
dbt test --profiles-dir .
```

### 6. Run the Streamlit dashboard locally

```bash
cd streamlit
pip install -r requirements.txt
streamlit run streamlit_app.py
```

---

## Current status

| Component | Status |
|-----------|--------|
| dlt ingestion pipeline | ✅ Complete |
| dbt staging layer | ✅ Complete |
| dbt marts layer | ✅ Complete |
| dbt snapshots (SCD Type 2) | ✅ Complete |
| dbt model contracts | ✅ Complete |
| dbt docs | ✅ Complete — [houdael.github.io/aviation-analytics](https://houdael.github.io/aviation-analytics) |
| Dagster orchestration | ✅ Complete |
| GitHub Actions CI/CD | ✅ Complete |
| Streamlit dashboard | ✅ Complete — [aviation-analytics-hel.streamlit.app](https://aviation-analytics-hel.streamlit.app) |
| Snowflake Cortex AI layer | ✅ Complete |
