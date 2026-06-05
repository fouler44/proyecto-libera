WITH

source AS (

    SELECT * FROM {{ source('raw', 'rp_vista_ventas') }}

),

renamed AS (

    SELECT
        id_venta,
        TRIM(UPPER(DESARROLLO_LARGO)) AS desarrollo_largo,
        TRIM(UPPER(DESARROLLO_CORTO)) AS desarrollo_corto,
        TRIM(UNIDAD) AS unidad,
        TRIM(UPPER(MODELO)) AS modelo,
        TRIM(STATUSUNIDAD) AS status_unidad,
        TRIM(UPPER(EQUIPO)) AS equipo,
        TRIM(STATUSVENTA) AS status_venta,
        TRIM(PLAN) AS plan,
        PRECIOVENTA AS precio_venta,
        CAST(FECHAPRIMERENGANCHE AS DATE) AS fecha_primer_enganche,
        CASE
            WHEN FECHAULTIMOPAGOENGANCHE LIKE '%NULL%' THEN NULL
            ELSE CAST(FECHAULTIMOPAGOENGANCHE AS DATE)
        END AS fecha_ultimo_pago_enganche

    FROM source
)

SELECT * FROM renamed
