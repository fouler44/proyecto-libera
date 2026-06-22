with cronograma as (

    select *
    from {{ ref('stg_reports__cronograma_unidades') }}

),

agrupado as (

    select
        desarrollo_largo,
        max(desarrollo_corto) as desarrollo_corto,
        unidad,

        max(equipo) as equipo,
        max(asesor) as asesor,
        max(cliente) as cliente,
        max(campania) as campania,

        max(rechazado) as fecha_rechazado,
        max(proceso) as fecha_proceso,
        max(esperando_autorizacion) as fecha_esperando_autorizacion,
        max(aprobado_direccion_ventas) as fecha_aprobado_direccion_ventas,
        max(aprobado_juridico) as fecha_aprobado_juridico,
        max(finalizado) as fecha_finalizado,
        max(finalizado_liquidado) as fecha_finalizado_liquidado

    from cronograma
    group by 1, 3

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'desarrollo_largo',
            'unidad'
        ]) }} as cronograma_unidad_key,

        {{ dbt_utils.generate_surrogate_key([
            'desarrollo_largo',
            'unidad'
        ]) }} as unidad_key,

        desarrollo_largo,
        desarrollo_corto,
        unidad,

        equipo,
        asesor,
        cliente,
        campania,

        fecha_rechazado,
        fecha_proceso,
        fecha_esperando_autorizacion,
        fecha_aprobado_direccion_ventas,
        fecha_aprobado_juridico,
        fecha_finalizado,
        fecha_finalizado_liquidado,

        case
            when fecha_finalizado_liquidado is not null then 'finalizado_liquidado'
            when fecha_finalizado is not null then 'finalizado'
            when fecha_aprobado_juridico is not null then 'aprobado_juridico'
            when fecha_aprobado_direccion_ventas is not null then 'aprobado_direccion_ventas'
            when fecha_esperando_autorizacion is not null then 'esperando_autorizacion'
            when fecha_proceso is not null then 'proceso'
            when fecha_rechazado is not null then 'rechazado'
            else 'sin_estatus'
        end as estatus_cronograma_actual,

        datediff(fecha_esperando_autorizacion, fecha_proceso)
            as dias_proceso_a_esperando_autorizacion,

        datediff(fecha_aprobado_direccion_ventas, fecha_esperando_autorizacion)
            as dias_esperando_autorizacion_a_aprobado_dv,

        datediff(fecha_aprobado_juridico, fecha_aprobado_direccion_ventas)
            as dias_aprobado_dv_a_aprobado_juridico,

        datediff(fecha_finalizado, fecha_aprobado_juridico)
            as dias_aprobado_juridico_a_finalizado,

        datediff(fecha_finalizado_liquidado, fecha_finalizado)
            as dias_finalizado_a_liquidado,

        datediff(fecha_finalizado, fecha_proceso)
            as dias_proceso_a_finalizado,

        datediff(fecha_finalizado_liquidado, fecha_proceso)
            as dias_proceso_a_finalizado_liquidado

    from agrupado

)

select * from final