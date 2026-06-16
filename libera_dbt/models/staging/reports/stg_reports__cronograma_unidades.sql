WITH 

source AS (

    SELECT * FROM {{ source('raw', 'rp_cronograma_unidades') }}
    
),

renamed AS (
    SELECT
        TRIM(UPPER(EQUIPO)) AS equipo,
        TRIM(UPPER(UNIDAD)) AS unidad,
        TRIM(UPPER(DESARROLLO_CORTO)) AS desarrollo_largo,
        TRIM(UPPER(DESARROLLO_LARGO)) AS desarrollo_corto,
        TRIM(UPPER(ASESOR)) AS asesor,
        TRIM(UPPER(CLIENTE)) AS cliente,
        TRIM(UPPER(CAMPANIA)) AS campania,
        TRY_CAST(RECHAZADO AS DATE) AS rechazado,
        TRY_CAST(PROCESO AS DATE) AS proceso,
        TRY_CAST(ESPERANDOAUTORIZACION AS DATE) AS esperando_autorizacion,
        TRY_CAST(APROBADO_DIRECCION_VENTAS AS DATE) AS aprobado_direccion_ventas,
        TRY_CAST(APROBADOJURIDICO AS DATE) AS aprobado_juridico,
        TRY_CAST(FINALIZADO AS DATE) AS finalizado,
        TRY_CAST(FINALIZADOYLIQUIDADO AS DATE) AS finalizado_liquidado
    
    FROM source
)

SELECT * FROM renamed