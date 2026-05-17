from pathlib import Path

from dagster import Definitions, ScheduleDefinition, define_asset_job
from dagster_dbt import DbtCliResource
from dagster_dlt import DagsterDltResource

from aviation_analytics.assets import aviation_dbt_assets, opensky_flights  # noqa: TID252

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

DBT_PROJECT_DIR = Path(__file__).resolve().parents[3] / "transformations" / "aviation_analytics"

# ---------------------------------------------------------------------------
# Jobs
# ---------------------------------------------------------------------------

all_assets_job = define_asset_job(
    name="all_assets_job",
    description="Materializes all assets: OpenSky ingestion followed by all dbt models.",
)

# ---------------------------------------------------------------------------
# Schedules
# ---------------------------------------------------------------------------

daily_schedule = ScheduleDefinition(
    job=all_assets_job,
    cron_schedule="0 6 * * *",
    execution_timezone="UTC",
    name="daily_6am_utc",
    description="Triggers full pipeline materialization daily at 06:00 UTC.",
)

# ---------------------------------------------------------------------------
# Definitions
# ---------------------------------------------------------------------------

defs = Definitions(
    assets=[opensky_flights, aviation_dbt_assets],
    jobs=[all_assets_job],
    schedules=[daily_schedule],
    resources={
        "dbt": DbtCliResource(project_dir=str(DBT_PROJECT_DIR)),
        "dlt": DagsterDltResource(),
    },
)
