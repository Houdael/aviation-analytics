with flights as (
    select * from {{ ref('fct_flights') }}
),

airlines as (
    select * from {{ ref('dim_airlines') }}
),

aggregated as (
    select
        operator_icao,
        est_departure_airport,
        est_arrival_airport,
        count(*)                                                as flight_count,
        avg(flight_duration_minutes)                            as avg_flight_duration_minutes,
        min(flight_duration_minutes)                            as min_flight_duration_minutes,
        max(flight_duration_minutes)                            as max_flight_duration_minutes
    from flights
    where operator_icao is not null
      and est_departure_airport is not null
      and est_arrival_airport is not null
      and flight_duration_minutes > 0
    group by 1, 2, 3
),

final as (
    select
        al.airline_id,
        al.operator_icao,
        al.operator_iata,
        al.airline_name,
        agg.est_departure_airport                               as departure_icao,
        agg.est_arrival_airport                                 as arrival_icao,
        agg.flight_count,
        round(agg.avg_flight_duration_minutes, 1)                as avg_flight_duration_minutes,
        round(agg.min_flight_duration_minutes, 1)                as min_flight_duration_minutes,
        round(agg.max_flight_duration_minutes, 1)                as max_flight_duration_minutes
    from aggregated agg
    left join airlines al on al.operator_icao = agg.operator_icao
)

select * from final
order by airline_name, departure_icao, arrival_icao
