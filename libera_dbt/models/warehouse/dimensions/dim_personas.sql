with personas as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'persona_natural_key'
        ]) }} as persona_key,

        persona_natural_key,

        max(nombre_completo) as nombre_completo,
        max(nombre_cliente) as nombre_cliente,
        max(apellido_paterno) as apellido_paterno,
        max(apellido_materno) as apellido_materno,
        max(edad) as edad,
        max(rfc) as rfc,
        max(curp) as curp,
        max(lower(email)) as email,
        max(telefono_celular) as telefono_celular,
        max(telefono_local) as telefono_local,
        max(sexo) as sexo,
        max(estado_civil) as estado_civil,
        max(regimen) as regimen,
        max(ocupacion) as ocupacion,
        max(nacionalidad) as nacionalidad,
        max(lugar_nacimiento) as lugar_nacimiento,
        max(calle) as calle,
        max(no_exterior) as no_exterior,
        max(no_interior) as no_interior,
        max(colonia) as colonia,
        max(codigo_postal) as codigo_postal,
        max(localidad) as localidad,
        max(estado) as estado,
        max(pais) as pais,
        max(identificacion) as identificacion,
        max(no_identificacion) as no_identificacion

    from {{ ref('int_venta_persona') }}
    where persona_natural_key is not null
    group by persona_natural_key

)

select * from personas