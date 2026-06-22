with unidades_desde_clientes as (

    select
        desarrollo_largo,
        desarrollo_corto,
        unidad,
        etapa
    from {{ ref('stg_reports__clientes') }}
    where desarrollo_largo is not null
      and unidad is not null

),

deduplicated as (

    select
        desarrollo_largo,
        unidad,
        max(desarrollo_corto) as desarrollo_corto,
        max(etapa) as etapa
    from unidades_desde_clientes
    group by
        desarrollo_largo,
        unidad

)

select * from deduplicated