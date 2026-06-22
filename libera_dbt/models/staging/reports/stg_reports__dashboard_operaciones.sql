with

source as (

    select * from {{ source('raw', 'rp_dashboard_operaciones') }}

),

renamed as (
    select
        id_venta,
        trim(upper(EQUIPO)) as equipo,
        trim(upper(DESARROLLO_LARGO)) as desarrollo_largo,
        trim(upper(DESARROLLO_CORTO)) as desarrollo_corto,
        trim(upper(UNIDAD)) as unidad,
        trim(upper(MODELO)) as modelo,
        trim(upper(ETAPA)) as etapa,
        PRECIOLISTA as precio_lista,
        PRECIOM2 as precio_m2,
        trim(upper(ASESOR)) as asesor,
        trim(upper(STATUSUNIDAD)) as status_unidad,
        trim(upper(STATUSVENTA)) as status_venta,
        trim(upper(CLIENTE)) as cliente,
        trim(upper(CAMPANIA)) as campania,
        nullif(trim(upper(VENDEDOREXTERNO)), '') as vendedor_externo,
        try_cast(FECHADESTATUS as date) as fecha_de_status,
        trim(PLAN) as plan,
        coalesce(NUMEROMENSUALIDES, 0) as numero_mensualidades,
        coalesce(NUMEROENGANCHES, 0) as numero_enganches,
        PRECIOVENTA as precio_venta,
        PRECIOM2V as precio_m2_venta,
        ENGANCHE as enganche,
        FINANCIAMIENTO as financiamiento,
        TOTAL_COBRADO as total_cobrado,
        SALDOTOTAL as saldo_total,
        TOTALVENCIDO as total_vencido,
        SIELTOTALCOBRADOESMENORQUEELENGANCHE as enganche_incompleto,
        REQUIERE_FACTURA as requiere_factura,
        try_cast(FECHAPRIMERENGANCHE as date) as fecha_primer_enganche,
        try_cast(FECHAULTIMOPAGOENGANCHE as date) as fecha_ultimo_pago_enganche,
        MONTODELPRIMERENGANCHE as monto_primer_enganche,
        nullif(trim(upper(COMISIONASESOR)), '') as comision_asesor,
        nullif(trim(upper(COMISIONLIBERA)), '') as comision_libera

    from source
),

deduplicated as (

    select distinct *
    from renamed
)

select * from deduplicated
