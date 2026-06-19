with

source as (

    select * from {{ source('raw', 'rp_cartera_vencida_detallado') }}

),

renamed as (
    select
        id_venta,
        trim(upper(EQUIPO)) as equipo,
        trim(upper(DESARROLLOLARGO)) as desarrollo_largo,
        trim(upper(DESARROLLOCORTO)) as desarrollo_corto,
        trim(upper(UNIDAD)) as unidad,
        trim(upper(CLIENTE)) as cliente,

        trim(CORREOELECTRONICO) as email,
        trim(TELEFONOCELULAR) as telefono_celular,
        trim(TELEFONOLOCAL) as telefono_local,

        DIASATRASO as dias_atraso,
        NOPAGO as no_pago,
        try_cast(FECHAPAGO as date) as fecha_pago,
        MONTOVENCIDO as monto_vencido,

        initcap(trim(lower(TIPOPAGO))) as tipo_pago

    from source
)

select * from renamed