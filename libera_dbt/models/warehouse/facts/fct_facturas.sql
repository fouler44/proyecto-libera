WITH facturas AS (

    SELECT * FROM {{ ref('stg_reports__facturas') }}

),

final AS (

    SELECT
        CASE
            WHEN uuid IS NOT NULL AND uuid != ''
                THEN {{ dbt_utils.generate_surrogate_key(['uuid']) }}
            ELSE {{ dbt_utils.generate_surrogate_key([
                'folio_general',
                'folio_seguimiento',
                'fecha_timbrado',
                'total_factura'
            ]) }}
        END AS factura_key,

        uuid,
        uuid_relacionado,
        folio_general,
        folio_seguimiento,
        rfc_emisor,
        rfc_receptor,
        razon_social_emisor,
        razon_social_receptor,
        fecha_timbrado,
        tipo_factura,
        tipo_pago,
        total_factura

    FROM facturas

)

SELECT * FROM final