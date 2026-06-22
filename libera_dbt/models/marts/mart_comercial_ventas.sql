with ventas as (

    select *
    from {{ ref('fct_ventas') }}

),

unidades as (

    select *
    from {{ ref('dim_unidades') }}

),

venta_persona as (

    select *
    from {{ ref('bridge_venta_persona') }}

),

personas as (

    select *
    from {{ ref('dim_personas') }}

),

personas_por_venta as (

    select
        vp.venta_key,

        max(
            case
                when vp.rol_persona_en_venta = 'cliente_principal'
                    then p.nombre_completo
            end
        ) as cliente_principal,

        max(
            case
                when vp.rol_persona_en_venta = 'cliente_principal'
                    then p.email
            end
        ) as email_cliente_principal,

        max(
            case
                when vp.rol_persona_en_venta = 'cliente_principal'
                    then p.telefono_celular
            end
        ) as telefono_cliente_principal,

        sum(
            case
                when vp.rol_persona_en_venta = 'copropietario'
                    then 1
                else 0
            end
        ) as numero_copropietarios

    from venta_persona vp
    left join personas p
        on vp.persona_key = p.persona_key

    group by
        vp.venta_key

)

select
    v.venta_key,
    v.id_venta,

    u.desarrollo_largo,
    u.desarrollo_corto,
    u.etapa,
    u.unidad,
    u.modelo,

    v.status_venta,
    v.status_unidad,
    v.status_escritura,
    v.plan,
    v.equipo,
    v.asesor,

    ppv.cliente_principal,
    ppv.email_cliente_principal,
    ppv.telefono_cliente_principal,
    coalesce(ppv.numero_copropietarios, 0) as numero_copropietarios,

    case
        when coalesce(ppv.numero_copropietarios, 0) > 0 then true
        else false
    end as tiene_copropietarios,

    v.fecha_contrato,
    v.fecha_firma_contrato,
    v.fecha_primer_enganche,
    v.fecha_ultimo_pago_enganche,
    v.fecha_escritura,
    v.fecha_prospectacion,
    v.fecha_registro_venta,

    v.precio_venta,
    v.enganche,
    v.financiamiento,
    v.valor_escritura,
    v.num_mensualidades,
    v.dia_pago,
    v.entro_dv

from ventas v

left join unidades u
    on v.unidad_key = u.unidad_key

left join personas_por_venta ppv
    on v.venta_key = ppv.venta_key