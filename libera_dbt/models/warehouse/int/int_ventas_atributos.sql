with ventas_atributos as (

    select
        id_venta,

        max(desarrollo_largo) as desarrollo_largo,
        max(desarrollo_corto) as desarrollo_corto,
        max(unidad) as unidad,
        max(etapa) as etapa,
        max(asesor) as asesor,
        max(status_venta) as status_venta,

        max(fecha_contrato) as fecha_contrato,
        max(fecha_firma_contrato) as fecha_firma_contrato,
        max(fecha_escritura) as fecha_escritura,
        max(fecha_prospectacion) as fecha_prospectacion,
        max(fecha_registro_venta) as fecha_registro_venta,
        max(fecha_aprobacion_jd) as fecha_aprobacion_jd,
        max(fecha_registro_carga_contrato) as fecha_registro_carga_contrato,

        max(plan) as plan,
        max(num_mensualidades) as num_mensualidades,
        max(precio_venta) as precio_venta,
        max(enganche) as enganche,
        max(financiamiento) as financiamiento,
        max(status_escritura) as status_escritura,
        max(valor_escritura) as valor_escritura,
        max(dia_pago) as dia_pago,
        max(entro_dv) as entro_dv

    from {{ ref('stg_reports__clientes') }}
    where id_venta is not null
    group by id_venta

)

select * from ventas_atributos