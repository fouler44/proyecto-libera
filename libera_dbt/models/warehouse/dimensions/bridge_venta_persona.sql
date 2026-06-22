with personas as (

    select *
    from {{ ref('int_venta_persona') }}

),

ventas as (

    select
        venta_key,
        id_venta
    from {{ ref('fct_ventas') }}

),

final as (

    select distinct
        v.venta_key,

        {{ dbt_utils.generate_surrogate_key([
            'p.persona_natural_key'
        ]) }} as persona_key,

        p.id_venta,
        p.rol_persona_en_venta

    from personas p
    inner join ventas v
        on p.id_venta = v.id_venta

    where p.id_venta is not null
      and p.persona_natural_key is not null

)

select * from final