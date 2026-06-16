SELECT
    id_venta,
    COUNT(*) AS total
FROM {{ ref('stg_reports__vista_ventas') }}
GROUP BY id_venta
HAVING COUNT(*) > 1