with personas as (

    select
        id_venta,
        rol_persona_en_venta,
        nombre_cliente,
        apellido_paterno,
        apellido_materno,
        edad,
        lugar_nacimiento,
        rfc,
        curp,
        calle,
        no_exterior,
        no_interior,
        colonia,
        codigo_postal,
        localidad,
        estado,
        pais,
        nacionalidad,
        ocupacion,
        email,
        telefono_celular,
        telefono_local,
        identificacion,
        no_identificacion,
        sexo,
        estado_civil,
        regimen,
        es_venta_cancelada
    from {{ ref('stg_reports__clientes') }}

    union all

    select
        id_venta,
        rol_persona_en_venta,
        nombre_cliente,
        apellido_paterno,
        apellido_materno,
        edad,
        lugar_nacimiento,
        rfc,
        curp,
        calle,
        no_exterior,
        no_interior,
        colonia,
        codigo_postal,
        localidad,
        estado,
        pais,
        nacionalidad,
        ocupacion,
        email,
        telefono_celular,
        telefono_local,
        identificacion,
        no_identificacion,
        sexo,
        estado_civil,
        regimen,
        es_venta_cancelada
    from {{ ref('stg_reports__copropiedades') }}

),

prepared as (

    select
        *,

        concat_ws(
            ' ',
            nombre_cliente,
            apellido_paterno,
            apellido_materno
        ) as nombre_completo,

        case
            when curp is not null and curp != '' then curp
            when rfc is not null and rfc != '' then rfc
            when email is not null and email != '' then lower(email)
            else concat_ws(
                '|',
                nombre_cliente,
                apellido_paterno,
                apellido_materno,
                telefono_celular
            )
        end as persona_natural_key

    from personas
    where id_venta is not null

)

select distinct * from prepared