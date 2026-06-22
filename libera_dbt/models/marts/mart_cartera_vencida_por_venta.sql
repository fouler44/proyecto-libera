with pagos (

    select *
    from {{ ref('fct_pagos_vencidos') }}

),

unidades as (

    select *
    from {{ ref('dim_unidades') }}
    
),

ventas as (

    select *
    from {{ ref('fct_ventas') }}

),

cartera_por_venta as (

    select
        venta_key,
        id_venta,
        unidad_key,

        max(cliente) as cliente,
        max(email) as email,
        max(telefono_celular) as telefono_celular,
        max(telefono_local) as telefono_local,

        sum(monto_vencido) as total_vencido,
        count(*) as numero_pagos_vencidos,
        max(dias_atraso) as dias_atraso_maximo,
        avg(dias_atraso) as dias_atraso_promedio,
        min(fecha_pago) as fecha_primer_pago_vencido,
        max(fecha_pago) as fecha_ultimo_pago_vencido
    
    from pagos
    group by venta_key, id_venta, unidad_key

),

final as (

    select
        c.venta_key,
        c.id_venta,
        c.unidad_key,

        v.equipo,
        u.desarrollo_largo,
        u.desarrollo_corto,
        u.grupo,
        u.unidad,

        c.cliente,
        c.email,
        c.telefono_celular,
        c.telefono_local,

        c.total_vencido,
        c.numero_pagos_vencidos,
        c.dias_atraso_maximo,
        c.dias_atraso_promedio,
        c.fecha_primer_pago_vencido,
        c.fecha_ultimo_pago_vencido

    from cartera_por_venta c

    left join unidades u
        on c.unidad_key = u.unidad_key

    left join ventas v
        on c.venta_key = v.venta_key

)

select * from final