with

source as (

    select * from {{ source('raw', 'rp_flujo_ingresos_ventacancelada') }}

),

renamed as (

    select
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
        MONTOPAGADO as monto_pagado,
        trim(upper(STATUS_TERCERO)) as status_tercero,
        trim(upper(NOMBRETERCERO)) as nombre_tercero,
        true as es_venta_cancelada

    from source
)

select * from renamed


-- NO TIENE NI venta_id NI FECHA_CAPTURA COMO SU VERSIÓN NO CANCELADA.
