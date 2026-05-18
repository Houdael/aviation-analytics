import json
import os

import pandas as pd
import plotly.express as px
import requests
import snowflake.connector
import streamlit as st

# ---------------------------------------------------------------------------
# Connection
# ---------------------------------------------------------------------------

@st.cache_resource
def get_connection():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        warehouse="AVIATION_DBT_DEV_WH",
        database="AVIATION_ANALYTICS_DEV",
        schema="MARTS",
    )


@st.cache_data
def run_query(query):
    conn = get_connection()
    return pd.read_sql(query, conn)


# ---------------------------------------------------------------------------
# App layout
# ---------------------------------------------------------------------------

st.set_page_config(
    page_title="Aviation Analytics",
    page_icon="✈️",
    layout="wide",
)

st.sidebar.title("✈️ Aviation Analytics")
page = st.sidebar.radio(
    "Navigate to",
    ["Airport Traffic", "Route Popularity", "Airline Reliability", "Traffic Patterns", "Ask Cortex"],
)

# ---------------------------------------------------------------------------
# Page 1 — Airport Traffic
# ---------------------------------------------------------------------------

if page == "Airport Traffic":
    st.title("🛬 Airport Traffic")
    st.caption("Total flight activity per airport, aggregated from daily records.")

    df = run_query("""
        SELECT
            airport_iata,
            airport_name,
            city,
            SUM(total_flights)  AS total_flights,
            SUM(arrivals)       AS total_arrivals,
            SUM(departures)     AS total_departures
        FROM mart_airport_traffic
        GROUP BY airport_iata, airport_name, city
        ORDER BY total_flights DESC
    """)

    col1, col2, col3 = st.columns(3)
    col1.metric("Total flights", f"{df['TOTAL_FLIGHTS'].sum():,.0f}")
    col2.metric("Total arrivals", f"{df['TOTAL_ARRIVALS'].sum():,.0f}")
    col3.metric("Total departures", f"{df['TOTAL_DEPARTURES'].sum():,.0f}")

    st.divider()

    fig = px.bar(
        df,
        x="AIRPORT_IATA",
        y="TOTAL_FLIGHTS",
        color="CITY",
        labels={"AIRPORT_IATA": "Airport", "TOTAL_FLIGHTS": "Total Flights", "CITY": "City"},
        title="Total Flights per Airport",
        text_auto=True,
    )
    fig.update_layout(xaxis_tickangle=0, showlegend=False)
    st.plotly_chart(fig, use_container_width=True)

    st.subheader("Arrivals vs Departures")
    fig2 = px.bar(
        df.melt(
            id_vars="AIRPORT_IATA",
            value_vars=["TOTAL_ARRIVALS", "TOTAL_DEPARTURES"],
            var_name="Type",
            value_name="Flights",
        ),
        x="AIRPORT_IATA",
        y="Flights",
        color="Type",
        barmode="group",
        labels={"AIRPORT_IATA": "Airport"},
        title="Arrivals vs Departures per Airport",
    )
    st.plotly_chart(fig2, use_container_width=True)

# ---------------------------------------------------------------------------
# Page 2 — Route Popularity
# ---------------------------------------------------------------------------

elif page == "Route Popularity":
    st.title("🗺️ Route Popularity")
    st.caption("Top 20 most active origin-destination routes.")

    df = run_query("""
        SELECT
            departure_iata,
            departure_city,
            arrival_iata,
            arrival_city,
            flight_count,
            first_seen_date,
            last_seen_date
        FROM mart_route_popularity
        ORDER BY flight_count DESC
        LIMIT 20
    """)

    df["ROUTE"] = df["DEPARTURE_IATA"] + " → " + df["ARRIVAL_IATA"]
    df["LABEL"] = df["DEPARTURE_CITY"] + " → " + df["ARRIVAL_CITY"]

    fig = px.bar(
        df,
        x="FLIGHT_COUNT",
        y="ROUTE",
        orientation="h",
        color="FLIGHT_COUNT",
        color_continuous_scale="Blues",
        labels={"FLIGHT_COUNT": "Number of Flights", "ROUTE": "Route"},
        title="Top 20 Routes by Flight Count",
        text_auto=True,
    )
    fig.update_layout(yaxis={"categoryorder": "total ascending"}, coloraxis_showscale=False)
    st.plotly_chart(fig, use_container_width=True)

    st.subheader("Top 20 Routes — Detail")
    st.dataframe(
        df[["ROUTE", "LABEL", "FLIGHT_COUNT", "FIRST_SEEN_DATE", "LAST_SEEN_DATE"]]
        .rename(columns={
            "ROUTE": "Route",
            "LABEL": "Cities",
            "FLIGHT_COUNT": "Flights",
            "FIRST_SEEN_DATE": "First Seen",
            "LAST_SEEN_DATE": "Last Seen",
        }),
        use_container_width=True,
        hide_index=True,
    )

# ---------------------------------------------------------------------------
# Page 3 — Airline Reliability
# ---------------------------------------------------------------------------

elif page == "Airline Reliability":
    st.title("🏆 Airline Reliability")
    st.caption("Airlines ranked by total flight volume and average flight duration.")

    df = run_query("""
        SELECT
            airline_name,
            operator_icao,
            operator_iata,
            total_flights,
            total_arrivals,
            total_departures,
            avg_flight_duration_minutes,
            active_days
        FROM mart_airline_reliability
        WHERE airline_name IS NOT NULL
        ORDER BY total_flights DESC
        LIMIT 30
    """)

    st.subheader("Airline Ranking")
    st.dataframe(
        df.rename(columns={
            "AIRLINE_NAME": "Airline",
            "OPERATOR_ICAO": "ICAO",
            "OPERATOR_IATA": "IATA",
            "TOTAL_FLIGHTS": "Total Flights",
            "TOTAL_ARRIVALS": "Arrivals",
            "TOTAL_DEPARTURES": "Departures",
            "AVG_FLIGHT_DURATION_MINUTES": "Avg Duration (min)",
            "ACTIVE_DAYS": "Active Days",
        }),
        use_container_width=True,
        hide_index=True,
    )

    st.divider()

    fig = px.bar(
        df.head(15),
        x="TOTAL_FLIGHTS",
        y="AIRLINE_NAME",
        orientation="h",
        color="AVG_FLIGHT_DURATION_MINUTES",
        color_continuous_scale="Teal",
        labels={
            "TOTAL_FLIGHTS": "Total Flights",
            "AIRLINE_NAME": "Airline",
            "AVG_FLIGHT_DURATION_MINUTES": "Avg Duration (min)",
        },
        title="Top 15 Airlines by Total Flights (colour = avg duration)",
        text_auto=True,
    )
    fig.update_layout(yaxis={"categoryorder": "total ascending"})
    st.plotly_chart(fig, use_container_width=True)

# ---------------------------------------------------------------------------
# Page 4 — Traffic Patterns
# ---------------------------------------------------------------------------

elif page == "Traffic Patterns":
    st.title("🕐 Traffic Patterns")
    st.caption("Intra-day flight counts by hour and airport — identify peak traffic windows.")

    df = run_query("""
        SELECT
            airport_iata,
            hour_of_day,
            SUM(flight_count) AS flight_count
        FROM mart_traffic_patterns
        GROUP BY airport_iata, hour_of_day
        ORDER BY airport_iata, hour_of_day
    """)

    airports = sorted(df["AIRPORT_IATA"].dropna().unique().tolist())
    selected = st.multiselect(
        "Filter by airport", options=airports, default=airports
    )

    df_filtered = df[df["AIRPORT_IATA"].isin(selected)] if selected else df

    pivot = df_filtered.pivot_table(
        index="AIRPORT_IATA",
        columns="HOUR_OF_DAY",
        values="FLIGHT_COUNT",
        aggfunc="sum",
        fill_value=0,
    )

    fig = px.imshow(
        pivot,
        labels={"x": "Hour of Day (UTC)", "y": "Airport", "color": "Flights"},
        title="Flight Volume Heatmap — Hour of Day × Airport",
        color_continuous_scale="YlOrRd",
        aspect="auto",
        text_auto=True,
    )
    fig.update_xaxes(dtick=1)
    st.plotly_chart(fig, use_container_width=True)

    st.subheader("Hourly totals across all selected airports")
    hourly = (
        df_filtered.groupby("HOUR_OF_DAY")["FLIGHT_COUNT"]
        .sum()
        .reset_index()
        .rename(columns={"HOUR_OF_DAY": "Hour", "FLIGHT_COUNT": "Flights"})
    )
    fig2 = px.bar(
        hourly,
        x="Hour",
        y="Flights",
        title="Total Flights by Hour of Day",
        labels={"Hour": "Hour of Day (UTC)", "Flights": "Total Flights"},
        text_auto=True,
    )
    fig2.update_xaxes(dtick=1)
    st.plotly_chart(fig2, use_container_width=True)

# ---------------------------------------------------------------------------
# Page 5 — Ask Cortex
# ---------------------------------------------------------------------------

elif page == "Ask Cortex":
    st.title("🤖 Ask Cortex")
    st.caption(
        "Ask a question in plain English. Snowflake Cortex Analyst will generate "
        "the SQL and run it against the aviation analytics semantic model."
    )

    CORTEX_ANALYST_ENDPOINT = (
        "https://{account}.snowflakecomputing.com/api/v2/cortex/analyst/message"
    )
    SEMANTIC_VIEW = "AVIATION_ANALYTICS_DEV.MARTS.SEM_AVIATION_ANALYTICS"

    def call_cortex_analyst(question: str) -> dict:
        conn = get_connection()
        account = os.environ["SNOWFLAKE_ACCOUNT"]
        token = conn._rest._token  # session token from the active connector session

        url = CORTEX_ANALYST_ENDPOINT.format(account=account)
        headers = {
            "Authorization": f'Snowflake Token="{token}"',
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        payload = {
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": question}],
                }
            ],
            "semantic_view": SEMANTIC_VIEW,
        }
        response = requests.post(url, headers=headers, json=payload, timeout=60)
        response.raise_for_status()

        raw = response.text

        try:
            result = json.loads(raw) if isinstance(raw, str) else response.json()
        except json.JSONDecodeError as e:
            raise ValueError(f"Could not parse Cortex API response as JSON: {e}\n\nRaw: {raw}")

        return result

    question = st.text_input(
        "Your question",
        placeholder="e.g. Which airport had the most flights last week?",
    )

    if st.button("Ask", type="primary") and question.strip():
        with st.spinner("Cortex is thinking..."):
            try:
                result = call_cortex_analyst(question.strip())

                # Extract generated SQL from response
                sql = None
                for item in result.get("message", {}).get("content", []):
                    if item.get("type") == "sql":
                        sql = item.get("statement")
                        break

                if sql:
                    st.subheader("Generated SQL")
                    st.code(sql, language="sql")

                    st.subheader("Results")
                    df = run_query(sql)
                    if df.empty:
                        st.info("The query returned no results.")
                    else:
                        st.dataframe(df, use_container_width=True, hide_index=True)
                else:
                    # Cortex returned a text response instead of SQL
                    for item in result.get("message", {}).get("content", []):
                        if item.get("type") == "text":
                            st.info(item.get("text", "No answer returned."))

            except requests.HTTPError as e:
                st.error(f"Cortex Analyst API error: {e.response.status_code} — {e.response.text}")
            except Exception as e:
                st.error(f"Unexpected error: {e}")
