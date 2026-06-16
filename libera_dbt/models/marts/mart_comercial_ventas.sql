WITH ventas AS (

    SELECT *
    FROM {{ ref('fct_ventas') }}

),

unidades AS (

    SELECT *
    FROM {{ ref('dim_unidades') }}

),

venta_persona AS (

    SELECT *
    FROM {{ ref('bridge_venta_persona') }}

),

personas AS (

    SELECT *
    FROM {{ ref('dim_personas') }}

),

personas_por_venta AS (

    SELECT
        vp.venta_key,

        MAX(
            CASE
                WHEN vp.rol_persona_en_venta = 'cliente_principal'
                    THEN p.nombre_completo
            END
        ) AS cliente_principal,

        MAX(
            CASE
                WHEN vp.rol_persona_en_venta = 'cliente_principal'
                    THEN p.email
            END
        ) AS email_cliente_principal,

        MAX(
            CASE
                WHEN vp.rol_persona_en_venta = 'cliente_principal'
                    THEN p.telefono_celular
            END
        ) AS telefono_cliente_principal,

        SUM(
            CASE
                WHEN vp.rol_persona_en_venta = 'copropietario'
                    THEN 1
                ELSE 0
            END
        ) AS numero_copropietarios

    FROM venta_persona vp
    LEFT JOIN personas p
        ON vp.persona_key = p.persona_key

    GROUP BY
        vp.venta_key

)

SELECT
    v.venta_key,
    v.id_venta,

    u.desarrollo_largo,
    u.desarrollo_corto,
    u.etapa,
    u.unidad,
    u.modelo,

    v.status_venta,
    v.status_unidad,
    v.status_escritura,
    v.plan,
    v.equipo,
    v.asesor,

    ppv.cliente_principal,
    ppv.email_cliente_principal,
    ppv.telefono_cliente_principal,
    COALESCE(ppv.numero_copropietarios, 0) AS numero_copropietarios,

    CASE
        WHEN COALESCE(ppv.numero_copropietarios, 0) > 0 THEN true
        ELSE false
    END AS tiene_copropietarios,

    v.fecha_contrato,
    v.fecha_firma_contrato,
    v.fecha_primer_enganche,
    v.fecha_ultimo_pago_enganche,
    v.fecha_escritura,
    v.fecha_prospectacion,
    v.fecha_registro_venta,

    v.precio_venta,
    v.enganche,
    v.financiamiento,
    v.valor_escritura,
    v.num_mensualidades,
    v.dia_pago,
    v.entro_dv

FROM ventas v

LEFT JOIN unidades u
    ON v.unidad_key = u.unidad_key

LEFT JOIN personas_por_venta ppv
    ON v.venta_key = ppv.venta_key