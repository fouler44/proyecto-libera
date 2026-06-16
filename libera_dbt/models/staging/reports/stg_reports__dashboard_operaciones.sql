WITH

source AS (

    SELECT * FROM {{ source('raw', 'rp_dashboard_operaciones') }}

),

renamed AS (
    SELECT
        id_venta,
        TRIM(UPPER(EQUIPO)) AS equipo,
        TRIM(UPPER(DESARROLLO_LARGO)) AS desarrollo_largo,
        TRIM(UPPER(DESARROLLO_CORTO)) AS desarrollo_corto,
        TRIM(UPPER(UNIDAD)) AS unidad,
        TRIM(UPPER(MODELO)) AS modelo,
        TRIM(UPPER(ETAPA)) AS etapa,
        PRECIOLISTA AS precio_lista,
        PRECIOM2 AS precio_m2,
        TRIM(UPPER(ASESOR)) AS asesor,
        TRIM(UPPER(STATUSUNIDAD)) AS status_unidad,
        TRIM(UPPER(STATUSVENTA)) AS status_venta,
        TRIM(UPPER(CLIENTE)) AS cliente,
        TRIM(UPPER(CAMPANIA)) AS campania,
        TRY_CAST(FECHADESTATUS AS DATE) AS fecha_de_status,
        TRIM(PLAN) AS plan,
        COALESCE(NUMEROMENSUALIDES, 0) AS numero_mensualidades,
        COALESCE(NUMEROENGANCHES, 0) AS numero_enganches,
        PRECIOVENTA AS precio_venta,
        PRECIOM2V AS precio_m2_venta,
        ENGANCHE AS enganche,
        FINANCIAMIENTO AS financiamiento,
        TOTAL_COBRADO AS total_cobrado,
        SALDOTOTAL AS saldo_total,
        TOTALVENCIDO AS total_vencido,
        SIELTOTALCOBRADOESMENORQUEELENGANCHE AS enganche_incompleto,
        REQUIERE_FACTURA AS requiere_factura,
        TRY_CAST(FECHAPRIMERENGANCHE AS DATE) AS fecha_primer_enganche,
        TRY_CAST(FECHAULTIMOPAGOENGANCHE AS DATE) AS fecha_ultimo_pago_enganche,
        MONTODELPRIMERENGANCHE AS monto_primer_enganche,
        NULLIF(TRIM(UPPER(COMISIONASESOR)), '') AS comision_asesor,
        NULLIF(TRIM(UPPER(COMISIONLIBERA)), '') AS comision_libera
    
    FROM source
)

SELECT * FROM renamed