with ingresos as (

    select *
    from {{ ref('stg_reports__flujo_ingresos') }}
    where concat_ws(
        '',
        cast(id_venta as string),
        folio,
        cast(fecha_ingreso as string),
        cast(fecha_amortizacion as string),
        referencia_ingresos,
        cast(monto_pagado as string),
        concepto,
        forma_pago,
        banco,
        status_ingreso,
        status_venta,
        desarrollo_largo,
        desarrollo_corto,
        unidad,
        etapa,
        cliente,
        status_tercero,
        nombre_tercero,
        cast(fecha_captura as string)
    ) != ''
      and monto_pagado is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'id_venta',
            'folio',
            'fecha_ingreso',
            'fecha_amortizacion',
            'fecha_captura',
            'referencia_ingresos',
            'monto_pagado',
            'concepto',
            'forma_pago',
            'banco'
        ]) }} as ingreso_key,

        {{ dbt_utils.generate_surrogate_key([
            'id_venta'
        ]) }} as venta_key,

        id_venta,

        {{ dbt_utils.generate_surrogate_key([
            'desarrollo_largo',
            'unidad'
        ]) }} as unidad_key,

        folio,
        status_ingreso,
        status_venta,
        fecha_ingreso,
        fecha_amortizacion,
        fecha_captura,
        banco,
        forma_pago,
        concepto,
        referencia_ingresos,
        status_tercero,
        nombre_tercero,
        cliente,
        monto_pagado

    from ingresos

)

select * from final