with ventas as (

    select *
    from {{ ref('fct_ventas') }}

),

unidades as (

    select *
    from {{ ref('dim_unidades') }}

),

venta_persona as (

    select *
    from {{ ref('bridge_venta_persona') }}

),

personas as (

    select *
    from {{ ref('dim_personas') }}

),

personas_por_venta as (

    select
        vp.venta_key,

        max(
            case
                when vp.rol_persona_en_venta = 'cliente_principal'
                    then p.nombre_completo
            end
        ) as cliente_principal,

        max(
            case
                when vp.rol_persona_en_venta = 'cliente_principal'
                    then p.email
            end
        ) as email_cliente_principal,

        max(
            case
                when vp.rol_persona_en_venta = 'cliente_principal'
                    then p.telefono_celular
            end
        ) as telefono_cliente_principal,

        sum(
            case
                when vp.rol_persona_en_venta = 'copropietario'
                    then 1
                else 0
            end
        ) as numero_copropietarios

    from venta_persona vp
    left join personas p
        on vp.persona_key = p.persona_key

    group by 1

),

ingresos_por_venta as (

    select
        venta_key,

        sum(monto_pagado) as total_cobrado,
        count(*) as numero_movimientos_ingreso,
        min(fecha_ingreso) as fecha_primer_ingreso,
        max(fecha_ingreso) as fecha_ultimo_ingreso

    from {{ ref('fct_ingresos') }}

    where venta_key is not null

    group by 1

),

cartera_por_venta as (

    select
        venta_key,

        sum(monto_vencido) as total_vencido,
        count(*) as numero_pagos_vencidos,
        max(dias_atraso) as dias_atraso_maximo,
        avg(dias_atraso) as dias_atraso_promedio,
        min(fecha_pago) as fecha_primer_pago_vencido,
        max(fecha_pago) as fecha_ultimo_pago_vencido

    from {{ ref('fct_pagos_vencidos') }}

    where venta_key is not null

    group by 1

),

cronograma_por_unidad as (

    select
        unidad_key,

        max(fecha_rechazado) as fecha_rechazado,
        max(fecha_proceso) as fecha_proceso,
        max(fecha_esperando_autorizacion) as fecha_esperando_autorizacion,
        max(fecha_aprobado_direccion_ventas) as fecha_aprobado_direccion_ventas,
        max(fecha_aprobado_juridico) as fecha_aprobado_juridico,
        max(fecha_finalizado) as fecha_finalizado,
        max(fecha_finalizado_liquidado) as fecha_finalizado_liquidado,

        max(estatus_cronograma_actual) as estatus_cronograma_actual

    from {{ ref('fct_cronograma_unidades') }}

    group by 1

),

final as (

    select
        -- Llaves
        v.venta_key,
        v.id_venta,
        v.unidad_key,

        -- Unidad / desarrollo
        u.grupo,
        u.desarrollo_largo,
        u.desarrollo_corto,
        u.etapa,
        u.unidad,
        u.modelo,

        -- Venta / operación comercial
        v.status_venta,
        v.status_unidad,
        v.status_escritura,
        v.plan,
        v.equipo,
        v.asesor,

        -- Personas
        p.cliente_principal,
        p.email_cliente_principal,
        p.telefono_cliente_principal,

        coalesce(p.numero_copropietarios, 0) as numero_copropietarios,

        case
            when coalesce(p.numero_copropietarios, 0) > 0 then true
            else false
        end as tiene_copropietarios,

        -- Fechas de venta
        v.fecha_contrato,
        v.fecha_firma_contrato,
        v.fecha_primer_enganche,
        v.fecha_ultimo_pago_enganche,
        v.fecha_escritura,
        v.fecha_prospectacion,
        v.fecha_registro_venta,

        -- Métricas comerciales
        v.precio_venta,
        v.precio_m2_venta,
        v.enganche,
        v.financiamiento,
        v.valor_escritura,
        v.num_mensualidades,
        v.dia_pago,
        v.entro_dv,
        v.requiere_factura,

        -- Ingresos calculados desde fct_ingresos
        coalesce(i.total_cobrado, 0) as total_cobrado,
        coalesce(i.numero_movimientos_ingreso, 0) as numero_movimientos_ingreso,
        i.fecha_primer_ingreso,
        i.fecha_ultimo_ingreso,

        -- Cartera vencida calculada desde fct_cartera_vencida_detallado
        coalesce(c.total_vencido, 0) as total_vencido,
        coalesce(c.numero_pagos_vencidos, 0) as numero_pagos_vencidos,
        c.dias_atraso_maximo,
        c.dias_atraso_promedio,
        c.fecha_primer_pago_vencido,
        c.fecha_ultimo_pago_vencido,

        -- Saldos calculados
        v.precio_venta - coalesce(i.total_cobrado, 0) as saldo_total_estimado,

        case
            when v.precio_venta is null or v.precio_venta = 0 then null
            else coalesce(i.total_cobrado, 0) / v.precio_venta
        end as porcentaje_cobrado,

        case
            when coalesce(i.total_cobrado, 0) = 0 then 'sin_ingresos'
            when v.precio_venta is not null
                and coalesce(i.total_cobrado, 0) >= v.precio_venta
                then 'cobrado_total'
            when coalesce(c.total_vencido, 0) > 0 then 'con_vencido'
            else 'cobranza_al_corriente'
        end as estatus_cobranza_estimado,

        -- Cronograma operativo
        cr.fecha_rechazado,
        cr.fecha_proceso,
        cr.fecha_esperando_autorizacion,
        cr.fecha_aprobado_direccion_ventas,
        cr.fecha_aprobado_juridico,
        cr.fecha_finalizado,
        cr.fecha_finalizado_liquidado,
        cr.estatus_cronograma_actual

    from ventas v

    left join unidades u
        on v.unidad_key = u.unidad_key

    left join personas_por_venta p
        on v.venta_key = p.venta_key

    left join ingresos_por_venta i
        on v.venta_key = i.venta_key

    left join cartera_por_venta c
        on v.venta_key = c.venta_key

    left join cronograma_por_unidad cr
        on v.unidad_key = cr.unidad_key

    where u.desarrollo_corto not in ('UH MAY', 'DEMO 2024')

)

select *
from final