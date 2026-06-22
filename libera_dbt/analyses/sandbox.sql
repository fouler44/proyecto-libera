select
    id_venta,
    count(*) as total
from {{ ref('stg_reports__dashboard_operaciones') }}
where id_venta is not null
group by 1
having count(*) > 1