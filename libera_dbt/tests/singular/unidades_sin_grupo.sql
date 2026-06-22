{{ config(severity='warn') }}

-- Auditoria no bloqueante: identifica desarrollos que no matchean con el seed
-- manual grupos_desarrollos y por eso quedan sin grupo analitico.
select
    desarrollo_largo,
    desarrollo_corto,
    count(*) as total_unidades
from {{ ref('dim_unidades') }}
where grupo is null
group by
    desarrollo_largo,
    desarrollo_corto
order by total_unidades desc
