from datetime import datetime, timedelta, timezone
from pathlib import Path

import dlt
from dagster import AssetExecutionContext, asset
from dagster_dbt import DbtCliResource, DbtProject, dbt_assets
from dagster_dlt import DagsterDltResource, DagsterDltTranslator

import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "ingestion"))
from opensky_pipeline import EUROPEAN_AIRPORTS, TokenManager, opensky_source  # noqa: E402

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

DBT_PROJECT_DIR = (
    Path(__file__).resolve().parents[3] / "transformations" / "aviation_analytics"
)
DBT_PROJECT = DbtProject(project_dir=DBT_PROJECT_DIR)

# ---------------------------------------------------------------------------
# dlt asset — wraps the OpenSky ingestion pipeline
# ---------------------------------------------------------------------------

_dlt_pipeline = dlt.pipeline(
    pipeline_name="opensky",
    destination="snowflake",
    dataset_name="raw",
)


@asset(
    group_name="ingestion",
    description=(
        "Ingests yesterday's flight arrivals and departures for 10 European airports "
        "from the OpenSky Network API into the RAW Snowflake schema via dlt."
    ),
)
def opensky_flights(context: AssetExecutionContext, dlt: DagsterDltResource):
    yesterday = datetime.now(timezone.utc).date() - timedelta(days=1)
    token_manager = TokenManager()

    context.log.info(
        f"Ingesting flights for {len(EUROPEAN_AIRPORTS)} airports on {yesterday}"
    )

    load_info = dlt.run(
        context=context,
        dlt_source=opensky_source(yesterday, token_manager),
        dlt_pipeline=_dlt_pipeline,
        dagster_dlt_translator=DagsterDltTranslator(),
    )

    context.log.info(str(load_info))


# ---------------------------------------------------------------------------
# dbt assets — one Dagster asset per dbt model
# ---------------------------------------------------------------------------

@dbt_assets(manifest=DBT_PROJECT.manifest_path)
def aviation_dbt_assets(context: AssetExecutionContext, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()
