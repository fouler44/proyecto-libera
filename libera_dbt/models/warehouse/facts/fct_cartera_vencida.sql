with cartera as (

    select *
    from {{ ref('stg_reports__cartera_vencida') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'id_venta',
            'no_pago',
            'fecha_pago',
            'tipo_pago'
        ]) }} as cartera_vencida_key,

        case
            when id_venta is not null
                then {{ dbt_utils.generate_surrogate_key(['id_venta']) }}
        end as venta_key,

        case
            when desarrollo_largo is not null and unidad is not null
                then {{ dbt_utils.generate_surrogate_key([
                    'desarrollo_largo',
                    'unidad'
                ]) }}
        end as unidad_key,

        id_venta,

        equipo,
        desarrollo_largo,
        desarrollo_corto,
        unidad,

        cliente,
        email,
        telefono_celular,
        telefono_local,

        dias_atraso,
        no_pago,
        fecha_pago,
        monto_vencido,
        tipo_pago

    from cartera

    where monto_vencido is not null

)

select * from final