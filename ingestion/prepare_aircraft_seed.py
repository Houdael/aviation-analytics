import os 
import pandas as pd
import snowflake.connector


SNOWFLAKE_ACCOUNT = os.environ["SNOWFLAKE_ACCOUNT"]
SNOWFLAKE_USER = os.environ["SNOWFLAKE_USER"]
SNOWFLAKE_PASSWORD = os.environ["SNOWFLAKE_PASSWORD"]
SNOWFLAKE_WAREHOUSE = os.environ["SNOWFLAKE_WAREHOUSE"]
SNOWFLAKE_DATABASE = os.environ["SNOWFLAKE_DATABASE"]

conn = snowflake.connector.connect(
    account     = SNOWFLAKE_ACCOUNT,
    user        = SNOWFLAKE_USER,
    password    = SNOWFLAKE_PASSWORD,
    warehouse   = SNOWFLAKE_WAREHOUSE,
    database    = SNOWFLAKE_DATABASE,
    schema      = "RAW"
)

cursor = conn.cursor()
cursor.execute("SELECT DISTINCT icao24 FROM flights")
icao24_list = [row[0] for row in cursor.fetchall()]

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(BASE_DIR, "aircraftDatabase.csv"))
df_filtered = df[df["icao24"].isin(icao24_list)]

COLUMNS_TO_KEEP = [
    "icao24", "registration", "manufacturername", 
    "model", "typecode", "operator", 
    "operatorcallsign", "operatoricao", "operatoriata"
]
df_filtered = df_filtered[COLUMNS_TO_KEEP]

df_filtered.to_csv(
    os.path.join(BASE_DIR, "../transformations/aviation_analytics/seeds/aircraft.csv"),
    index=False
)

cursor.close()
conn.close()

print(f"{len(df_filtered)} aircraft records saved to seeds/aircraft.csv")
