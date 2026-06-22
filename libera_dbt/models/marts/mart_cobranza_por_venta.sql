with ventas as (

    select *
    from {{ ref('fct_ventas') }}

),

unidades as (

    select *
    from {{ ref('dim_unidades') }}

),

ingresos as (

    select *
    from {{ ref('fct_ingresos') }}
    where venta_key is not null

),

ingresos_por_venta as (

    select
        venta_key,

        coalesce(sum(monto_pagado), 0) as total_ingresado,
        coalesce(sum(case when lower(status_ingreso) = 'activo' then monto_pagado end), 0) as total_ingresado_activo,
        count(*) as numero_movimientos_ingreso,
        min(fecha_ingreso) as fecha_primer_ingreso,
        max(fecha_ingreso) as fecha_ultimo_ingreso

    from ingresos

    group by
        venta_key

),

ventas_con_unidad as (

    select
        v.venta_key,
        v.id_venta,

        u.desarrollo_largo,
        u.desarrollo_corto,
        u.etapa,
        u.unidad,
        u.modelo,

        v.status_venta,
        v.status_unidad,
        v.plan,
        v.equipo,
        v.asesor,

        v.fecha_contrato,
        v.fecha_primer_enganche,
        v.fecha_ultimo_pago_enganche,

        v.precio_venta,
        
        coalesce(i.total_ingresado, 0) as total_ingresado,
        coalesce(i.total_ingresado, 0) as total_ingresado_bruto,
        coalesce(i.total_ingresado_activo, 0) as total_ingresado_activo,
        coalesce(i.numero_movimientos_ingreso, 0) as numero_movimientos_ingreso,
        i.fecha_primer_ingreso,
        i.fecha_ultimo_ingreso

    from ventas v

    left join unidades u
        on v.unidad_key = u.unidad_key

    left join ingresos_por_venta i
        on v.venta_key = i.venta_key

),

metricas as (

    select
        *,

        precio_venta - total_ingresado_activo as saldo_estimado,

        case
            when precio_venta > 0
                then round(total_ingresado_activo / precio_venta * 100, 2)
            else null
        end as porcentaje_cobrado

    from ventas_con_unidad

)

select *
from metricas
