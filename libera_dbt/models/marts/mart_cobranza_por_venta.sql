WITH ventas AS (

    SELECT *
    FROM {{ ref('fct_ventas') }}

),

unidades AS (

    SELECT *
    FROM {{ ref('dim_unidades') }}

),

ingresos AS (

    SELECT *
    FROM {{ ref('fct_ingresos') }}

),

ingresos_por_venta AS (

    SELECT
        venta_key,

        SUM(monto_pagado) AS total_ingresado,
        COUNT(*) AS numero_movimientos_ingreso,
        MIN(fecha_ingreso) AS fecha_primer_ingreso,
        MAX(fecha_ingreso) AS fecha_ultimo_ingreso

    FROM ingresos

    WHERE venta_key IS NOT NULL

    GROUP BY
        venta_key

)

SELECT
    v.venta_key,
    v.id_venta,

    u.desarrollo_largo,
    u.desarrollo_corto,
    u.etapa,
    u.unidad,
    u.modelo,

    v.status_venta,
    v.status_unidad,
    v.plan,
    v.equipo,
    v.asesor,

    v.fecha_contrato,
    v.fecha_primer_enganche,
    v.fecha_ultimo_pago_enganche,

    v.precio_venta,
    COALESCE(i.total_ingresado, 0) AS total_ingresado,

    v.precio_venta - COALESCE(i.total_ingresado, 0) AS saldo_estimado,

    CASE
        WHEN v.precio_venta > 0
            THEN COALESCE(i.total_ingresado, 0) / v.precio_venta
        ELSE NULL
    END AS porcentaje_cobrado,

    COALESCE(i.numero_movimientos_ingreso, 0) AS numero_movimientos_ingreso,
    i.fecha_primer_ingreso,
    i.fecha_ultimo_ingreso

FROM ventas v

LEFT JOIN unidades u
    ON v.unidad_key = u.unidad_key

LEFT JOIN ingresos_por_venta i
    ON v.venta_key = i.venta_key