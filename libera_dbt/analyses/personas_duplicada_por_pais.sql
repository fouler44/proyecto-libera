select
    id_venta,
    nombre_cliente,
    apellido_paterno,
    apellido_materno,
    rfc,
    curp,
    count(*) as total_filas,
    count(distinct pais) as paises_distintos
from {{ ref('stg_reports__clientes') }}
group by
    id_venta,
    nombre_cliente,
    apellido_paterno,
    apellido_materno,
    rfc,
    curp
having count(*) > 1