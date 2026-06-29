with

source as (

    select * from {{ source('raw', 'rp_facturas') }}

),

renamed as (

    select
        trim(FOLIOGENERAL_FACTURA) as folio_general,
        trim(UUID) as uuid,
        trim(UUI_DRELACIONADO) as uuid_relacionado,
        trim(RFC_EMISOR) as rfc_emisor,
        trim(RFC_RECEPTOR) as rfc_receptor,
        trim(upper(RAZON_SOCIAL_EMISOR)) as razon_social_emisor,
        trim(upper(RAZON_SOCIAL_RECEPTOR)) as razon_social_receptor,
        try_cast(FECHA_TIMBRADO as date) as fecha_timbrado,
        nullif(trim(TIPO_FACTURA), 'NULL') as tipo_factura,
        TOTAL_FACTURA as total_factura,
        trim(FOLIO_SEGUIMIENTO) as folio_seguimiento,
        trim(TIPO_PAGO) as tipo_pago

    from source
)

select * from renamed
