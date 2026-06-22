with conflictos as (

    select
        persona_natural_key
    from {{ ref('int_venta_persona') }}
    where persona_natural_key is not null
    group by persona_natural_key
    having count(distinct nullif(trim(rfc), '')) > 1
        or count(distinct nullif(trim(curp), '')) > 1
        or count(distinct nullif(lower(trim(email)), '')) > 1

),

detalle as (

    select
        p.persona_natural_key,
        p.id_venta,
        p.rol_persona_en_venta,
        p.nombre_completo,
        p.rfc,
        p.curp,
        lower(trim(p.email)) as email,
        p.telefono_celular
    from {{ ref('int_venta_persona') }} p
    inner join conflictos c
        on p.persona_natural_key = c.persona_natural_key

)

select *
from detalle
order by
    persona_natural_key,
    nombre_completo,
    id_venta