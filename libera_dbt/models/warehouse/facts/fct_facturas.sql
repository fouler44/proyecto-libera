with facturas as (

    select * from {{ ref('stg_reports__facturas') }}

),

final as (

    select
        case
            when uuid is not null and uuid != ''
                then {{ dbt_utils.generate_surrogate_key(['uuid']) }}
            else {{ dbt_utils.generate_surrogate_key([
                'folio_general',
                'folio_seguimiento',
                'fecha_timbrado',
                'total_factura'
            ]) }}
        end as factura_key,

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

    from facturas

)

select * from final