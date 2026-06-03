SELECT
    TRIM(FOLIOGENERAL_FACTURA) AS folio_general,
    TRIM(UUID) AS uuid,
    TRIM(UUI_DRELACIONADO) AS uuid_relacionado,
    TRIM(RFC_EMISOR) AS rfc_emisor,
    TRIM(RFC_RECEPTOR) AS rfc_receptor,
    TRIM(UPPER(RAZON_SOCIAL_EMISOR)) AS razon_social_emisor,
    TRIM(UPPER(RAZON_SOCIAL_RECEPTOR)) AS razon_social_receptor,
    CAST(FECHA_TIMBRADO AS DATE) AS fecha_timbrado,
    TIPO_FACTURA AS tipo_factura,
    TOTAL_FACTURA AS total_factura,
    TRIM(FOLIO_SEGUIMIENTO) AS folio_seguimiento,
    TRIM(TIPO_PAGO) AS tipo_pago
FROM {{ source('raw', 'rp_facturas') }}