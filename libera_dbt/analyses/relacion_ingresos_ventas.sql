SELECT
    COUNT(*) AS ingresos_sin_venta
FROM {{ ref('stg_reports__flujo_ingresos') }} i
LEFT JOIN {{ ref('stg_reports__vista_ventas') }} v
    ON i.id_venta = v.id_venta
WHERE v.id_venta IS NULL

-- Si sale mayor a cero, no conviertas la relación ingreso-venta en test obligatorio todavía.