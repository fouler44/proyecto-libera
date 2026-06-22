{{ config(severity='warn') }}

-- Auditoria no bloqueante: mart_comercial_ventas usa max(...) para elegir el
-- cliente principal. Esta prueba expone ventas con cero o multiples clientes
-- principales antes de que esa seleccion silenciosa afecte el mart.
select
    v.venta_key,
    v.id_venta,
    count(
        distinct case
            when b.rol_persona_en_venta = 'cliente_principal'
                then b.persona_key
        end
    ) as clientes_principales
from {{ ref('fct_ventas') }} v
left join {{ ref('bridge_venta_persona') }} b
    on v.venta_key = b.venta_key
group by
    v.venta_key,
    v.id_venta
having count(
    distinct case
        when b.rol_persona_en_venta = 'cliente_principal'
            then b.persona_key
    end
) != 1
