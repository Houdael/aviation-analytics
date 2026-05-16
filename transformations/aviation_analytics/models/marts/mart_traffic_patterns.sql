with flights as (
    select * from {{ ref('fct_flights') }}
),

airports as (
    select * from {{ ref('dim_airports') }}
),

aggregated as (
    select
        airport_icao,
        date_part('hour', first_seen_at)                        as hour_of_day,
        date_trunc('day', first_seen_at)                        as traffic_date,
        flight_type,
        count(*)                                                as flight_count
    from flights
    where first_seen_at is not null
    group by 1, 2, 3, 4
),

final as (
    select
        agg.traffic_date,
        agg.hour_of_day,
        agg.airport_icao,
        a.iata_code                                             as airport_iata,
        a.name                                                  as airport_name,
        a.city,
        agg.flight_type,
        agg.flight_count
    from aggregated agg
    left join airports a on a.icao_code = agg.airport_icao
)

select * from final
order by traffic_date, hour_of_day, airport_icao
