WITH facturas AS (

    SELECT *
    FROM {{ ref('fct_facturas') }}

),

fechas AS (

    SELECT *
    FROM {{ ref('dim_date') }}

)

SELECT
    f.factura_key,
    f.uuid,
    f.uuid_relacionado,
    f.folio_general,
    f.folio_seguimiento,

    f.rfc_emisor,
    f.rfc_receptor,
    f.razon_social_emisor,
    f.razon_social_receptor,

    f.fecha_timbrado,
    d.year AS anio_timbrado,
    d.month AS mes_timbrado,
    d.month_name AS nombre_mes_timbrado,

    f.tipo_factura,
    f.tipo_pago,
    f.total_factura

FROM facturas f

LEFT JOIN fechas d
    ON CAST(f.fecha_timbrado AS DATE) = d.date_day