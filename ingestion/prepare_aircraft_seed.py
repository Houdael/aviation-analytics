"""
Loads the full OpenSky aircraft reference database into STAGING.AIRCRAFT in Snowflake.

Run this script manually whenever aircraftDatabase.csv is updated (downloaded from
https://opensky-network.org/aircraft-database). It truncates the existing table and
replaces it with the full contents of the CSV, keeping only the relevant columns.

Usage:
    python ingestion/prepare_aircraft_seed.py
"""

import os

import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas


COLUMNS_TO_KEEP = [
    "icao24",
    "registration",
    "manufacturername",
    "model",
    "typecode",
    "operator",
    "operatorcallsign",
    "operatoricao",
    "operatoriata",
]


def main() -> None:
    # --- 1. Load full CSV ---
    base_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(base_dir, "aircraftDatabase.csv")
    df = pd.read_csv(csv_path, low_memory=False)
    df = df[COLUMNS_TO_KEEP]
    print(f"Loaded {len(df):,} aircraft records from {csv_path}")

    # Snowflake expects uppercase column names when using write_pandas
    df.columns = [col.upper() for col in df.columns]

    # --- 2. Connect to Snowflake ---
    conn = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema="STAGING",
    )

    try:
        # --- 3. Truncate existing table ---
        cursor = conn.cursor()
        cursor.execute("TRUNCATE TABLE IF EXISTS AIRCRAFT")
        cursor.close()
        print("Truncated STAGING.AIRCRAFT")

        # --- 4. Load full dataset ---
        success, nchunks, nrows, _ = write_pandas(
            conn=conn,
            df=df,
            table_name="AIRCRAFT",
            database=os.environ["SNOWFLAKE_DATABASE"],
            schema="STAGING",
            auto_create_table=True,
            overwrite=False,
        )

        if success:
            print(f"✅ Loaded {nrows:,} rows into STAGING.AIRCRAFT ({nchunks} chunk(s))")
        else:
            print("❌ write_pandas reported failure — check Snowflake logs")

    finally:
        conn.close()


if __name__ == "__main__":
    main()
