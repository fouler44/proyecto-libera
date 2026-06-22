with dashboard as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key([
            'desarrollo_largo',
            'unidad'
        ]) }} as unidad_key
    from {{ ref('stg_reports__dashboard_operaciones') }}

),

cronograma as (

    select *
    from {{ ref('fct_cronograma_unidades') }}

),

unidades as (

    select *
    from {{ ref('dim_unidades') }}

),

final as (

    select
        dashboard.*,

        cronograma.fecha_rechazado,
        cronograma.fecha_proceso,
        cronograma.fecha_esperando_autorizacion,
        cronograma.fecha_aprobado_direccion_ventas,
        cronograma.fecha_aprobado_juridico,
        cronograma.fecha_finalizado,
        cronograma.fecha_finalizado_liquidado,
        cronograma.estatus_cronograma_actual,

        unidades.grupo

    from dashboard

    left join cronograma
        on dashboard.unidad_key = cronograma.unidad_key

    left join unidades
        on dashboard.unidad_key = unidades.unidad_key

    where dashboard.desarrollo_corto not in ('UH MAY', 'DEMO 2024')

)

select * from final