with ventas as (

    select
        desarrollo_largo,
        desarrollo_corto,
        unidad,
        modelo
    from {{ ref('stg_reports__vista_ventas') }}
    where desarrollo_largo is not null
      and unidad is not null

),

atributos as (

    select *
    from {{ ref('int_unidades_atributos') }}

),

unidades_base as (

    select distinct
        v.desarrollo_largo,
        coalesce(v.desarrollo_corto, a.desarrollo_corto) as desarrollo_corto,
        a.etapa,
        v.unidad,
        v.modelo

    from ventas v
    left join atributos a
        on v.desarrollo_largo = a.desarrollo_largo
        and v.unidad = a.unidad

),

grupos as (

    select *
    from {{ ref('grupos_desarrollos') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'u.desarrollo_largo',
            'u.unidad'
        ]) }} as unidad_key,

        u.desarrollo_largo,
        u.desarrollo_corto,
        g.grupo_2 as grupo,
        u.etapa,
        u.unidad,
        u.modelo

    from unidades_base u
    left join grupos g
        on u.desarrollo_largo = g.desarrollo_largo
        and u.desarrollo_corto = g.desarrollo_corto

)

select * from final