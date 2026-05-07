{{ config(schema='staging') }}

with source as (
    select * from {{ source('opensky', 'flights') }}
),

renamed as (
    select
        -- surrogate key
        md5(cast(icao24 as varchar) || '-' || cast(first_seen as varchar)) as flight_id,

        -- identifiers
        cast(icao24 as varchar)                   as icao24,
        trim(cast(callsign as varchar))           as callsign,
        cast(flight_type as varchar)              as flight_type,

        -- resolved airport (the one this record is indexed against)
        case
            when flight_type = 'arrival'   then cast(est_arrival_airport as varchar)
            when flight_type = 'departure' then cast(est_departure_airport as varchar)
        end                                       as airport,

        -- airport references
        cast(est_departure_airport as varchar)    as est_departure_airport,
        cast(est_arrival_airport as varchar)      as est_arrival_airport,

        -- timestamps
        to_timestamp(cast(first_seen as bigint))  as first_seen_at,
        to_timestamp(cast(last_seen as bigint))   as last_seen_at,

        -- distances (metres)
        cast(est_departure_airport_horiz_distance as integer) as departure_horiz_distance_m,
        cast(est_departure_airport_vert_distance as integer)  as departure_vert_distance_m,
        cast(est_arrival_airport_horiz_distance as integer)   as arrival_horiz_distance_m,
        cast(est_arrival_airport_vert_distance as integer)    as arrival_vert_distance_m,

        -- candidate counts
        cast(departure_airport_candidates_count as integer)   as departure_airport_candidates_count,
        cast(arrival_airport_candidates_count as integer)     as arrival_airport_candidates_count

    from source
)

select * from renamed
