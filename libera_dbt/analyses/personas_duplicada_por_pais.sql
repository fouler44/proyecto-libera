SELECT
    id_venta,
    nombre_cliente,
    apellido_paterno,
    apellido_materno,
    rfc,
    curp,
    COUNT(*) AS total_filas,
    COUNT(DISTINCT pais) AS paises_distintos
FROM {{ ref('stg_reports__clientes') }}
GROUP BY
    id_venta,
    nombre_cliente,
    apellido_paterno,
    apellido_materno,
    rfc,
    curp
HAVING COUNT(*) > 1