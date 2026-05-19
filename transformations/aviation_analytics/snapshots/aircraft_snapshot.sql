{% snapshot aircraft_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='icao24',
        strategy='check',
        check_cols=['operator', 'operator_icao', 'operator_iata', 'operator_callsign'],
    )
}}

-- SCD Type 2 snapshot tracking airline ownership changes over time.
-- An aircraft (identified by icao24) can be transferred to a different airline,
-- and this snapshot preserves the full history of those operator changes.
-- Each time the operator, operator_icao, operator_iata, or operator_callsign
-- changes for a given aircraft, dbt creates a new record with dbt_valid_from
-- and dbt_valid_to timestamps, enabling point-in-time queries of airline ownership.
-- This ensures that historical flight records can be accurately attributed to the
-- airline that operated the aircraft at the time of the flight, not the current operator.

select
    icao24,
    manufacturer,
    model,
    typecode,
    operator,
    operator_callsign,
    operator_icao,
    operator_iata
from {{ ref('stg_aircraft') }}

{% endsnapshot %}
