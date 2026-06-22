with

source as (

    select * from {{ source('raw', 'rp_cronograma_unidades') }}

),

renamed as (
    select
        trim(upper(EQUIPO)) as equipo,
        
        trim(upper(DESARROLLO_CORTO)) as desarrollo_largo,
        trim(upper(DESARROLLO_LARGO)) as desarrollo_corto,
        
        trim(upper(UNIDAD)) as unidad,
        trim(upper(ASESOR)) as asesor,
        trim(upper(CLIENTE)) as cliente,
        trim(upper(CAMPANIA)) as campania,
        
        try_cast(RECHAZADO as date) as rechazado,
        try_cast(PROCESO as date) as proceso,
        try_cast(ESPERANDOAUTORIZACION as date) as esperando_autorizacion,
        try_cast(APROBADO_DIRECCION_VENTAS as date) as aprobado_direccion_ventas,
        try_cast(APROBADOJURIDICO as date) as aprobado_juridico,
        try_cast(FINALIZADO as date) as finalizado,
        try_cast(FINALIZADOYLIQUIDADO as date) as finalizado_liquidado

    from source
)

select * from renamed