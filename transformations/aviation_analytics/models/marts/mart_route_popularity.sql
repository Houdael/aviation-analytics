with flights as (
    select * from {{ ref('fct_flights') }}
),

airports as (
    select * from {{ ref('dim_airports') }}
),

routes as (
    select
        est_departure_airport,
        est_arrival_airport,
        count(*)                                                as flight_count,
        min(date_trunc('day', first_seen_at))                   as first_seen_date,
        max(date_trunc('day', first_seen_at))                   as last_seen_date
    from flights
    where est_departure_airport is not null
      and est_arrival_airport is not null
    group by 1, 2
),

final as (
    select
        r.est_departure_airport                                 as departure_icao,
        dep.iata_code                                           as departure_iata,
        dep.name                                                as departure_airport_name,
        dep.city                                                as departure_city,
        dep.country                                             as departure_country,
        r.est_arrival_airport                                   as arrival_icao,
        arr.iata_code                                           as arrival_iata,
        arr.name                                                as arrival_airport_name,
        arr.city                                                as arrival_city,
        arr.country                                             as arrival_country,
        r.flight_count,
        r.first_seen_date,
        r.last_seen_date
    from routes r
    left join airports dep on dep.icao_code = r.est_departure_airport
    left join airports arr on arr.icao_code = r.est_arrival_airport
)

select * from final
order by flight_count desc
