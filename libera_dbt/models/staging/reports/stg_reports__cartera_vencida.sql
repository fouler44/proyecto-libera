WITH 

source AS (

    SELECT * FROM {{ source('raw', 'rp_cartera_vencida_detallado') }}
    
),

renamed AS (
    SELECT
        id_venta,
        TRIM(UPPER(EQUIPO)) AS equipo,
        TRIM(UPPER(DESARROLLOLARGO)) AS desarrollo_largo,
        TRIM(UPPER(DESARROLLOCORTO)) AS desarrollo_corto,
        TRIM(UPPER(UNIDAD)) AS unidad,
        TRIM(UPPER(CLIENTE)) AS cliente,
        
        TRIM(CORREOELECTRONICO) AS email,
        TRIM(TELEFONOCELULAR) AS telefono_celular,
        TRIM(TELEFONOLOCAL) AS telefono_local,
        
        DIASATRASO AS dias_atraso,
        NOPAGO AS no_pago,
        TRY_CAST(FECHAPAGO AS DATE) AS fecha_pago,
        MONTOVENCIDO AS monto_vencido,
        
        INITCAP(TRIM(LOWER(TIPOPAGO))) AS tipo_pago

    FROM source
)

SELECT * FROM renamed