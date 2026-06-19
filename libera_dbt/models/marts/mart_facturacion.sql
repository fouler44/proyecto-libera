with facturas as (

    select *
    from {{ ref('fct_facturas') }}

),

fechas as (

    select *
    from {{ ref('dim_date') }}

)

select
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
    d.year as anio_timbrado,
    d.month as mes_timbrado,
    d.month_name as nombre_mes_timbrado,

    f.tipo_factura,
    f.tipo_pago,
    f.total_factura

from facturas f

left join fechas d
    on cast(f.fecha_timbrado as date) = d.date_day