with ingresos_ventas as (

    select
        'fct_ingresos -> fct_ventas' as relacion,
        count(*) as total_registros,
        count(v.venta_key) as con_relacion,
        count(*) - count(v.venta_key) as sin_relacion,
        round(
            cast(count(v.venta_key) as double) / nullif(count(*), 0) * 100,
            2
        ) as cobertura_pct,
        'auditoria_no_obligatoria' as tipo_auditoria

    from {{ ref('fct_ingresos') }} i
    left join {{ ref('fct_ventas') }} v
        on i.venta_key = v.venta_key

),

pagos_vencidos_ventas as (

    select
        'fct_pagos_vencidos -> fct_ventas' as relacion,
        count(*) as total_registros,
        count(v.venta_key) as con_relacion,
        count(*) - count(v.venta_key) as sin_relacion,
        round(
            cast(count(v.venta_key) as double) / nullif(count(*), 0) * 100,
            2
        ) as cobertura_pct,
        'auditoria_no_obligatoria' as tipo_auditoria

    from {{ ref('fct_pagos_vencidos') }} p
    left join {{ ref('fct_ventas') }} v
        on p.venta_key = v.venta_key

),

cronograma_unidades as (

    select
        'fct_cronograma_unidades -> dim_unidades' as relacion,
        count(*) as total_registros,
        count(u.unidad_key) as con_relacion,
        count(*) - count(u.unidad_key) as sin_relacion,
        round(
            cast(count(u.unidad_key) as double) / nullif(count(*), 0) * 100,
            2
        ) as cobertura_pct,
        'auditoria_no_obligatoria' as tipo_auditoria

    from {{ ref('fct_cronograma_unidades') }} c
    left join {{ ref('dim_unidades') }} u
        on c.unidad_key = u.unidad_key

),

facturas_ventas as (

    select
        'fct_facturas -> fct_ventas' as relacion,
        count(*) as total_registros,
        cast(null as bigint) as con_relacion,
        cast(null as bigint) as sin_relacion,
        cast(null as double) as cobertura_pct,
        'sin_llave_confiable' as tipo_auditoria

    from {{ ref('fct_facturas') }}

)

select * from ingresos_ventas
union all
select * from pagos_vencidos_ventas
union all
select * from cronograma_unidades
union all
select * from facturas_ventas
