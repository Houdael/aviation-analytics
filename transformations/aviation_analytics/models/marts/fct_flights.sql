with flights as (

    select * from {{ ref('stg_flights') }}

),

aircraft as (

    select * from {{ ref('stg_aircraft') }}

),

final as (

    select
        -- keys
        f.flight_id,
        f.icao24,
        f.airport_icao,
        f.flight_type,

        -- flight info
        f.callsign,
        f.est_departure_airport,
        f.est_arrival_airport,

        -- airline info from aircraft
        a.operator,
        a.operator_callsign,
        a.operator_icao,
        a.operator_iata,
        a.manufacturer,
        a.typecode,

        -- timestamps
        f.first_seen_at,
        f.last_seen_at,

        -- metrics
        datediff('minute', f.first_seen_at, f.last_seen_at) as flight_duration_minutes,
        cast(f.first_seen_at as date)                       as flight_date

    from flights f
    left join aircraft a on f.icao24 = a.icao24

)

select * from final