with source as (

    select * from {{ source('opensky', 'aircraft') }}

),

staged as (

    select
        -- primary key
        icao24,

        -- manufacturer normalization
        -- crowdsourced data has many variants for the same manufacturer
        -- we normalize the top 6 commercial manufacturers, leave others as-is
        case
            when manufacturername ilike '%airbus%'     then 'Airbus'
            when manufacturername ilike '%boeing%'     then 'Boeing'
            when manufacturername ilike '%embraer%'    then 'Embraer'
            when manufacturername ilike '%bombardier%' then 'Bombardier'
            when manufacturername ilike '%dassault%'   then 'Dassault'
            when manufacturername ilike '%gulfstream%' then 'Gulfstream'
            when manufacturername ilike '%boing%'      then 'Boeing'
            when manufacturername ilike '%empresa brasileira%' then 'Embraer'
            else manufacturername
        end                                            as manufacturer,

        model,
        typecode,

        nullif(trim(operator), '')                     as operator,
        nullif(trim(operatorcallsign), '')             as operator_callsign,
        nullif(trim(operatoricao), '')                 as operator_icao,
        nullif(trim(operatoriata), '')                 as operator_iata

    from source
    where icao24 is not null

),

deduped as (
    select *
    from staged
    qualify row_number() over (partition by icao24 order by icao24) = 1
)

select * from deduped
