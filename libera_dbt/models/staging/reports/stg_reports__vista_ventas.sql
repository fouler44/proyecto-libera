with

source as (

    select * from {{ source('raw', 'rp_vista_ventas') }}

),

renamed as (

    select
        id_venta,
        trim(upper(DESARROLLO_LARGO)) as desarrollo_largo,
        trim(upper(DESARROLLO_CORTO)) as desarrollo_corto,
        trim(upper(UNIDAD)) as unidad,
        trim(upper(MODELO)) as modelo,
        trim(STATUSUNIDAD) as status_unidad,
        trim(upper(EQUIPO)) as equipo,
        trim(STATUSVENTA) as status_venta,
        case
            when trim(upper(PLAN)) like '%CONTADO%' then 'CONTADO'
            when trim(upper(PLAN)) like '48 MEESES%' then '48 MESES'
            when trim(upper(PLAN)) LIKE "48 MESES.%" then "48 MESES"
            when trim(upper(PLAN)) LIKE "24 MESES.%" then "24 MESES"
            when trim(upper(PLAN)) LIKE "60 MESES.%" then "60 MESES"
            when trim(upper(PLAN)) LIKE "12 MESES.%" then "12 MESES"
            else trim(PLAN)
        end as plan,
        PRECIOVENTA as precio_venta,
        try_cast(FECHAPRIMERENGANCHE as date) as fecha_primer_enganche,
        try_cast(nullif(trim(FECHAULTIMOPAGOENGANCHE), 'NULL') as date) as fecha_ultimo_pago_enganche

    from source
)

select * from renamed
