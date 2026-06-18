WITH atributos AS (
    SELECT * FROM {{ ref('int_ventas_atributos') }}
),

ventas AS (

    SELECT * FROM {{ ref('stg_reports__vista_ventas') }}

),

dashboard AS (

    SELECT
        id_venta,
        precio_m2_venta,
        requiere_factura
    FROM {{ ref('stg_reports__dashboard_operaciones') }}
    WHERE id_venta IS NOT NULL

),

final AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'v.id_venta'
        ]) }} AS venta_key,

        v.id_venta,

        {{ dbt_utils.generate_surrogate_key([
            'v.desarrollo_largo',
            'v.unidad'
        ]) }} AS unidad_key,

        v.status_venta,
        v.status_unidad,
        COALESCE(v.plan, a.plan) AS plan,
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

    FROM ventas v
    LEFT JOIN atributos a
        ON v.id_venta = a.id_venta
    LEFT JOIN dashboard d
        ON v.id_venta = d.id_venta
)

SELECT * FROM final