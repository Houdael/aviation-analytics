with flights as (
    select * from {{ ref('fct_flights') }}
),

airlines as (
    select * from {{ ref('dim_airlines') }}
),

aggregated as (
    select
        operator_icao,
        count(*)                                                as total_flights,
        count_if(flight_type = 'departure')                     as total_departures,
        count_if(flight_type = 'arrival')                       as total_arrivals,
        avg(flight_duration_minutes)                            as avg_flight_duration_minutes,
        count(distinct date_trunc('day', first_seen_at))        as active_days
    from flights
    where operator_icao is not null
    group by 1
),

final as (
    select
        a.airline_id,
        a.operator_icao,
        a.operator_iata,
        a.airline_name,
        a.operator_callsign,
        agg.total_flights,
        agg.total_departures,
        agg.total_arrivals,
        round(agg.avg_flight_duration_minutes, 1)                as avg_flight_duration_minutes,
        agg.active_days
    from aggregated agg
    left join airlines a on a.operator_icao = agg.operator_icao
)

select * from final
order by total_flights desc
