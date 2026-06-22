select
    id_venta,
    count(*) as total
from {{ ref('stg_reports__vista_ventas') }}
group by id_venta
having count(*) > 1