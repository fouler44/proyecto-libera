WITH

source AS (

    SELECT * FROM {{ source('raw', 'rp_cliente_canceladas') }}

),

renamed AS (

    SELECT
        id_venta,
        TRIM(UPPER(DESARROLLO_LARGO)) AS desarrollo_largo,
        TRIM(UPPER(DESARROLLO_CORTO)) AS desarrollo_corto,
        UNIDAD AS unidad,
        TRIM(ETAPA) AS etapa,
        TRIM(UPPER(ASESOR)) AS asesor,
        TRIM(STATUSVENTA) AS status_venta,
        CAST(FECHACONTRATO AS DATE) AS fecha_contrato,
        CAST(FECHAFIRMACONTRATO AS DATE) AS fecha_firma_contrato,
        CASE
            WHEN TRIM(PLAN) LIKE '%CONTADO%' THEN 'CONTADO'
            WHEN TRIM(PLAN) LIKE '48 MEESES%' THEN '48 MESES'
            ELSE TRIM(PLAN)
        END AS plan,
        NOMENSUALIDADES AS num_mensualidades,
        PRECIOVENTA AS precio_venta,
        ENGANCHE AS enganche,
        FINANCIAMIENTO AS financiamiento,
        STATUSESCRITURA AS status_escritura,
        CAST(FECHAESCRITURA AS DATE) AS fecha_escritura,
        VALORESCRITURA AS valor_escritura,
        DIAPAGO AS dia_pago,
        TRIM(UPPER(NOMBRECLIENTE)) AS nombre_cliente,
        TRIM(UPPER(APELLIDOPATERNO)) AS apellido_paterno,
        TRIM(UPPER(APELLIDOMATERNO)) AS apellido_materno,
        CASE
            WHEN TRIM(EDAD) = 'CUARENTA Y DOS' THEN 42
            ELSE CAST(TRIM(EDAD) AS INT)
        END AS edad,
        TRIM(UPPER(
            decode(encode(LUGARNACIMIENTO, 'ISO-8859-1'), 'UTF-8')
        )) AS lugar_nacimiento,
        TRIM(UPPER(RFC)) AS rfc,
        TRIM(UPPER(CURP)) AS curp,
        CALLE AS calle,
        TRIM(NOEXTERIOR) AS no_exterior,
        TRIM(NOINTERIOR) AS no_interior,
        TRIM(UPPER(COLONIA)) AS colonia,
        CAST(CODIGOPOSTAL AS STRING) AS codigo_postal,
        CASE
            WHEN TRIM(UPPER(LOCALIDAD)) = '0' THEN NULL
            ELSE TRIM(UPPER(LOCALIDAD))
        END AS localidad,
        TRIM(UPPER(ESTADO)) AS estado,
        TRIM(UPPER(PAIS)) AS pais,
        TRIM(NACIONALIDAD) AS nacionalidad,
        TRIM(UPPER(OCUPACION)) AS ocupacion,
        TRIM(EMAIL) AS email,
        TRIM(TELEFONOCELULAR) AS telefono_celular,
        TRIM(TELEFONOLOCAL) AS telefono_local,
        TRIM(UPPER(IDENTIFICACION)) AS identificacion,
        TRIM(NOIDENTIFICACION) AS no_identificacion,
        CAST(FECHAPROSPECTACION AS DATE) AS fecha_prospectacion,
        CAST(FECHAREGISTROVENTA AS DATE) AS fecha_registro_venta, 
        TRY_CAST(NULLIF(TRIM(FECHAAPROBACIONJD), 'NULL') AS DATE) AS fecha_aprobacion_jd,
        TRY_CAST(NULLIF(TRIM(FECHAREGISTROCARGACONTRATO), 'NULL') AS DATE) AS fecha_registro_carga_contrato,
        ENTRODV AS entro_dv,
        TRIM(UPPER(SEXO)) AS sexo,
        TRIM(UPPER(ESTADOCIVIL)) AS estado_civil,
        TRIM(UPPER(REGIMEN)) AS regimen,
        'cliente_principal' AS rol_persona_en_venta,
        TRUE AS es_venta_cancelada

    FROM source
)

SELECT * FROM renamed
