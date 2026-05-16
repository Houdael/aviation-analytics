with flights as (
    select * from {{ ref('fct_flights') }}
),

airports as (
    select * from {{ ref('dim_airports') }}
),

daily as (
    select
        airport_icao,
        date_trunc('day', first_seen_at)                        as traffic_date,
        date_trunc('week', first_seen_at)                       as traffic_week,
        count_if(flight_type = 'arrival')                       as arrivals,
        count_if(flight_type = 'departure')                     as departures,
        count(*)                                                as total_flights
    from flights
    group by 1, 2, 3
),

final as (
    select
        d.traffic_date,
        d.traffic_week,
        d.airport_icao,
        a.iata_code                                             as airport_iata,
        a.name                                                  as airport_name,
        a.city,
        a.country,
        d.arrivals,
        d.departures,
        d.total_flights
    from daily d
    left join airports a on a.icao_code = d.airport_icao
)

select * from final
