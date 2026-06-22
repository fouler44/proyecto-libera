select
    id_venta,
    count(distinct nullif(trim(desarrollo_largo), '')) as desarrollos_largos_distintos,
    count(distinct nullif(trim(desarrollo_corto), '')) as desarrollos_cortos_distintos,
    count(distinct nullif(trim(unidad), '')) as unidades_distintas,
    count(distinct nullif(trim(etapa), '')) as etapas_distintas,
    count(distinct nullif(trim(asesor), '')) as asesores_distintos,
    count(distinct nullif(trim(status_venta), '')) as status_venta_distintos,
    count(distinct nullif(trim(plan), '')) as planes_distintos,
    count(distinct enganche) as enganches_distintos,
    count(distinct financiamiento) as financiamientos_distintos,
    count(distinct precio_venta) as precios_venta_distintos
from {{ ref('stg_reports__clientes') }}
where id_venta is not null
group by id_venta
having count(distinct nullif(trim(desarrollo_largo), '')) > 1
    or count(distinct nullif(trim(desarrollo_corto), '')) > 1
    or count(distinct nullif(trim(unidad), '')) > 1
    or count(distinct nullif(trim(etapa), '')) > 1
    or count(distinct nullif(trim(asesor), '')) > 1
    or count(distinct nullif(trim(status_venta), '')) > 1
    or count(distinct nullif(trim(plan), '')) > 1
    or count(distinct enganche) > 1
    or count(distinct financiamiento) > 1
    or count(distinct precio_venta) > 1
