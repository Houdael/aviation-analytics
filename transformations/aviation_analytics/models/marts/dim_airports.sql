with source as (
    select * from {{ ref('airports') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['icao_code']) }} as airport_id,
        icao_code,
        iata_code,
        name,
        city,
        country
    from source
)

select * from final
