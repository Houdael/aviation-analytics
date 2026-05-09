with source as (
    select * from {{ source('opensky', 'flights') }}
),

staged as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['icao24', 'first_seen']) }} as flight_id,

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
        to_timestamp(cast(last_seen as bigint))   as last_seen_at

    from source
    where first_seen is not null
)

select * from staged
