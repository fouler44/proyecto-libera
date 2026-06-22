select
    id_venta,
    count(distinct asesor) as distintos_asesores
from {{ ref('stg_reports__clientes') }}
group by 1
having count(distinct asesor) > 1