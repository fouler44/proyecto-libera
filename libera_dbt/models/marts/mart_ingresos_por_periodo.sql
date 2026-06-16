WITH ingresos AS (

    SELECT *
    FROM {{ ref('fct_ingresos') }}

),

unidades AS (

    SELECT *
    FROM {{ ref('dim_unidades') }}

),

fechas AS (

    SELECT *
    FROM {{ ref('dim_date') }}

)

SELECT
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

    COUNT(*) AS numero_movimientos,
    SUM(i.monto_pagado) AS total_ingresado

FROM ingresos i

LEFT JOIN unidades u
    ON i.unidad_key = u.unidad_key

LEFT JOIN fechas d
    ON i.fecha_ingreso = d.date_day

GROUP BY
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