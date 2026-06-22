select
    desarrollo_largo,
    unidad,
    count(distinct nullif(trim(desarrollo_corto), '')) as desarrollos_cortos_distintos,
    count(distinct nullif(trim(etapa), '')) as etapas_distintas
from {{ ref('stg_reports__clientes') }}
where desarrollo_largo is not null
  and unidad is not null
group by
    desarrollo_largo,
    unidad
having count(distinct nullif(trim(desarrollo_corto), '')) > 1
    or count(distinct nullif(trim(etapa), '')) > 1
