with atributos as (
    select * from {{ ref('int_ventas_atributos') }}
),

ventas as (

    select * from {{ ref('stg_reports__vista_ventas') }}

),

dashboard as (

    select
        id_venta,
        precio_m2_venta,
        requiere_factura
    from {{ ref('stg_reports__dashboard_operaciones') }}
    where id_venta is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'v.id_venta'
        ]) }} as venta_key,

        v.id_venta,

        {{ dbt_utils.generate_surrogate_key([
            'v.desarrollo_largo',
            'v.unidad'
        ]) }} as unidad_key,

        v.status_venta,
        v.status_unidad,
        coalesce(v.plan, a.plan) as plan,
        v.equipo,
        a.asesor,
        a.status_escritura,

        v.fecha_primer_enganche,
        v.fecha_ultimo_pago_enganche,
        a.fecha_contrato,
        a.fecha_firma_contrato,
        a.fecha_escritura,
        a.fecha_prospectacion,
        a.fecha_registro_venta,
        a.fecha_aprobacion_jd,
        a.fecha_registro_carga_contrato,

        v.precio_venta,
        d.precio_m2_venta,
        a.enganche,
        a.financiamiento,
        a.valor_escritura,
        a.num_mensualidades,
        a.dia_pago,
        a.entro_dv,
        d.requiere_factura

    from ventas v
    left join atributos a
        on v.id_venta = a.id_venta
    left join dashboard d
        on v.id_venta = d.id_venta
)

select * from final