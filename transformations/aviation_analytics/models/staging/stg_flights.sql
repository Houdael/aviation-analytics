with source as (
    select * from {{ source('opensky', 'flights') }}
),

staged as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['icao24', 'first_seen', 'flight_type']) }} as flight_id,

        -- identifiers
        icao24,
        trim(callsign)                            as callsign,
        flight_type,

        -- resolved airport (the one this record is indexed against)
        case
            when flight_type = 'arrival'   then est_arrival_airport
            when flight_type = 'departure' then est_departure_airport
        end                                       as airport_icao,

        -- airport references
        est_departure_airport,
        est_arrival_airport,

        -- timestamps
        to_timestamp(cast(first_seen as bigint))  as first_seen_at,
        to_timestamp(cast(last_seen as bigint))   as last_seen_at,

        -- dlt metadata
        _dlt_load_id

    from source
    where first_seen is not null
),

-- Defense-in-depth deduplication: keep the most recently loaded record per
-- logical flight in case a merge window overlap produces duplicate rows.
deduped as (
    select *
    from staged
    qualify row_number() over (
        partition by icao24, first_seen_at, flight_type
        order by _dlt_load_id desc
    ) = 1
)

select * from deduped
