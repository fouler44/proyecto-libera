with ingresos as (

    select *
    from {{ ref('fct_ingresos') }}

),

unidades as (

    select *
    from {{ ref('dim_unidades') }}

),

fechas as (

    select *
    from {{ ref('dim_date') }}

)

select
    d.year,
    d.month,
    d.month_name,

    u.desarrollo_largo,
    u.desarrollo_corto,
    u.etapa,

    i.banco,
    i.forma_pago,
    i.concepto,
    i.status_ingreso,

    count(*) as numero_movimientos,
    sum(i.monto_pagado) as total_ingresado

from ingresos i

left join unidades u
    on i.unidad_key = u.unidad_key

left join fechas d
    on i.fecha_ingreso = d.date_day

group by
    d.year,
    d.month,
    d.month_name,
    u.desarrollo_largo,
    u.desarrollo_corto,
    u.etapa,
    i.banco,
    i.forma_pago,
    i.concepto,
    i.status_ingreso