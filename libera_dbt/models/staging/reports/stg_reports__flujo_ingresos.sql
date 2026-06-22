with

source as (

    select * from {{ source('raw', 'rp_flujo_ingresos') }}

),

renamed as (

    select
        id_venta,
        trim(STATUSINGRESO) as status_ingreso,
        trim(STATUSVENTA) as status_venta,
        trim(FOLIO) as folio,
        try_cast(FECHA_INGRESO as date) as fecha_ingreso,
        try_cast(FECHA_ARMOTIZACION as date) as fecha_amortizacion,
        trim(upper(DESARROLLOLARGO)) as desarrollo_largo,
        trim(upper(DESARROLLOCORTO)) as desarrollo_corto,
        trim(upper(UNIDAD)) as unidad,
        trim(ETAPA) as etapa,
        trim(upper(CLIENTE)) as cliente,
        trim(upper(BANCO)) as banco,
        trim(initcap(FORMAPAGO)) as forma_pago,
        trim(CONCEPTO) as concepto,
        trim(REFERENCIAINGRESOS) as referencia_ingresos,
        try_cast(MONTOPAGADO as decimal(10,2)) as monto_pagado,
        trim(upper(STATUS_TERCERO)) as status_tercero,
        trim(upper(NOMBRETERCERO)) as nombre_tercero,
        try_cast(FECHA_CAPTURA as date) as fecha_captura

    from source
)

select * from renamed
