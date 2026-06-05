WITH

source AS (

    SELECT * FROM {{ source('raw', 'rp_flujo_ingresos') }}

),

renamed AS (

    SELECT
        id_venta,
        TRIM(STATUSINGRESO) AS status_ingreso,
        TRIM(STATUSVENTA) AS status_venta,
        TRIM(FOLIO) AS folio,
        CAST(FECHA_INGRESO AS DATE) AS fecha_ingreso,
        CAST(FECHA_ARMOTIZACION AS DATE) AS fecha_amortizacion,
        TRIM(UPPER(DESARROLLOLARGO)) AS desarrollo_largo,
        TRIM(UPPER(DESARROLLOCORTO)) AS desarrollo_corto,
        TRIM(UNIDAD) AS unidad,
        TRIM(ETAPA) AS etapa,
        TRIM(UPPER(CLIENTE)) AS cliente,
        TRIM(UPPER(BANCO)) AS banco,
        TRIM(INITCAP(FORMAPAGO)) AS forma_pago,
        TRIM(CONCEPTO) AS concepto,
        TRIM(REFERENCIAINGRESOS) AS referencia_ingresos,
        MONTOPAGADO AS monto_pagado,
        TRIM(UPPER(STATUS_TERCERO)) AS status_tercero,
        TRIM(UPPER(NOMBRETERCERO)) AS nombre_tercero,
        CAST(FECHA_CAPTURA AS DATE) AS fecha_captura

    FROM source
)

SELECT * FROM renamed
