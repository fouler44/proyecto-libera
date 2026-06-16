WITH ventas_atributos AS (

    SELECT
        id_venta,

        MAX(desarrollo_largo) AS desarrollo_largo,
        MAX(desarrollo_corto) AS desarrollo_corto,
        MAX(unidad) AS unidad,
        MAX(etapa) AS etapa,
        MAX(asesor) AS asesor,
        MAX(status_venta) AS status_venta,

        MAX(fecha_contrato) AS fecha_contrato,
        MAX(fecha_firma_contrato) AS fecha_firma_contrato,
        MAX(fecha_escritura) AS fecha_escritura,
        MAX(fecha_prospectacion) AS fecha_prospectacion,
        MAX(fecha_registro_venta) AS fecha_registro_venta,
        MAX(fecha_aprobacion_jd) AS fecha_aprobacion_jd,
        MAX(fecha_registro_carga_contrato) AS fecha_registro_carga_contrato,

        MAX(plan) AS plan,
        MAX(num_mensualidades) AS num_mensualidades,
        MAX(precio_venta) AS precio_venta,
        MAX(enganche) AS enganche,
        MAX(financiamiento) AS financiamiento,
        MAX(status_escritura) AS status_escritura,
        MAX(valor_escritura) AS valor_escritura,
        MAX(dia_pago) AS dia_pago,
        MAX(entro_dv) AS entro_dv

    FROM {{ ref('stg_reports__clientes') }}
    WHERE id_venta IS NOT NULL
    GROUP BY id_venta

)

SELECT * FROM ventas_atributos