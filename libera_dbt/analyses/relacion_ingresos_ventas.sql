select
    count(*) as ingresos_sin_venta
from {{ ref('stg_reports__flujo_ingresos') }} i
left join {{ ref('stg_reports__vista_ventas') }} v
    on i.id_venta = v.id_venta
where v.id_venta is null

-- Si sale mayor a cero, no conviertas la relación ingreso-venta en test obligatorio todavía.