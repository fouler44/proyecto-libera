{{ config(severity='warn') }}

-- Auditoria no bloqueante: expone persona_natural_key con multiples RFC, CURP
-- o emails. Se mantiene como warning mientras se decide si se limpia la fuente
-- o se ajusta la logica de deduplicacion de personas.
select
    persona_natural_key,
    count(distinct nullif(trim(rfc), '')) as rfcs_distintos,
    count(distinct nullif(trim(curp), '')) as curps_distintos,
    count(distinct nullif(lower(trim(email)), '')) as emails_distintos
from {{ ref('int_venta_persona') }}
where persona_natural_key is not null
group by persona_natural_key
having count(distinct nullif(trim(rfc), '')) > 1
    or count(distinct nullif(trim(curp), '')) > 1
    or count(distinct nullif(lower(trim(email)), '')) > 1
