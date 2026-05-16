with source as (
    select * from {{ ref('stg_aircraft') }}
),

deduped as (
    select
        operator_icao,
        operator_iata,
        operator        as airline_name,
        operator_callsign,
        row_number() over (partition by operator_icao order by icao24) as rn
    from source
    where operator_icao is not null
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['operator_icao']) }} as airline_id,
        operator_icao,
        operator_iata,
        airline_name,
        operator_callsign
    from deduped
    where rn = 1
)

select * from final
