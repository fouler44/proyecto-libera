with

source as (

    select * from {{ source('raw', 'rp_cliente_canceladas') }}

),

renamed as (

    select
        id_venta,
        trim(upper(DESARROLLO_LARGO)) as desarrollo_largo,
        trim(upper(DESARROLLO_CORTO)) as desarrollo_corto,
        trim(upper(UNIDAD)) as unidad,
        trim(ETAPA) as etapa,
        trim(upper(ASESOR)) as asesor,
        trim(STATUSVENTA) as status_venta,
        try_cast(FECHACONTRATO as date) as fecha_contrato,
        try_cast(FECHAFIRMACONTRATO as date) as fecha_firma_contrato,
        case
            when trim(PLAN) like '%CONTADO%' then 'CONTADO'
            when trim(PLAN) like '48 MEESES%' then '48 MESES'
            else trim(PLAN)
        end as plan,
        NOMENSUALIDADES as num_mensualidades,
        PRECIOVENTA as precio_venta,
        ENGANCHE as enganche,
        FINANCIAMIENTO as financiamiento,
        STATUSESCRITURA as status_escritura,
        try_cast(FECHAESCRITURA as date) as fecha_escritura,
        VALORESCRITURA as valor_escritura,
        DIAPAGO as dia_pago,
        trim(upper(NOMBRECLIENTE)) as nombre_cliente,
        trim(upper(APELLIDOPATERNO)) as apellido_paterno,
        trim(upper(APELLIDOMATERNO)) as apellido_materno,
        case
            when trim(EDAD) = 'CUARENTA Y DOS' then 42
            else try_cast(trim(EDAD) as int)
        end as edad,
        trim(upper(
            decode(encode(LUGARNACIMIENTO, 'ISO-8859-1'), 'UTF-8')
        )) as lugar_nacimiento,
        trim(upper(RFC)) as rfc,
        trim(upper(CURP)) as curp,
        CALLE as calle,
        trim(NOEXTERIOR) as no_exterior,
        trim(NOINTERIOR) as no_interior,
        trim(upper(COLONIA)) as colonia,
        cast(CODIGOPOSTAL as string) as codigo_postal,
        case
            when trim(upper(LOCALIDAD)) = '0' then null
            else trim(upper(LOCALIDAD))
        end as localidad,
        trim(upper(ESTADO)) as estado,
        trim(upper(PAIS)) as pais,
        trim(NACIONALIDAD) as nacionalidad,
        trim(upper(OCUPACION)) as ocupacion,
        trim(EMAIL) as email,
        trim(TELEFONOCELULAR) as telefono_celular,
        trim(TELEFONOLOCAL) as telefono_local,
        trim(upper(IDENTIFICACION)) as identificacion,
        trim(NOIDENTIFICACION) as no_identificacion,
        try_cast(FECHAPROSPECTACION as date) as fecha_prospectacion,
        try_cast(FECHAREGISTROVENTA as date) as fecha_registro_venta,
        try_cast(nullif(trim(FECHAAPROBACIONJD), 'NULL') as date) as fecha_aprobacion_jd,
        try_cast(nullif(trim(FECHAREGISTROCARGACONTRATO), 'NULL') as date) as fecha_registro_carga_contrato,
        ENTRODV as entro_dv,
        trim(upper(SEXO)) as sexo,
        trim(upper(ESTADOCIVIL)) as estado_civil,
        trim(upper(REGIMEN)) as regimen,
        'cliente_principal' as rol_persona_en_venta,
        true as es_venta_cancelada

    from source
)

select * from renamed
