WITH personas AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'persona_natural_key'
        ]) }} AS persona_key,

        persona_natural_key,

        MAX(nombre_completo) AS nombre_completo,
        MAX(nombre_cliente) AS nombre_cliente,
        MAX(apellido_paterno) AS apellido_paterno,
        MAX(apellido_materno) AS apellido_materno,
        MAX(edad) AS edad,
        MAX(rfc) AS rfc,
        MAX(curp) AS curp,
        MAX(LOWER(email)) AS email,
        MAX(telefono_celular) AS telefono_celular,
        MAX(telefono_local) AS telefono_local,
        MAX(sexo) AS sexo,
        MAX(estado_civil) AS estado_civil,
        MAX(regimen) AS regimen,
        MAX(ocupacion) AS ocupacion,
        MAX(nacionalidad) AS nacionalidad,
        MAX(lugar_nacimiento) AS lugar_nacimiento,
        MAX(calle) AS calle,
        MAX(no_exterior) AS no_exterior,
        MAX(no_interior) AS no_interior,
        MAX(colonia) AS colonia,
        MAX(codigo_postal) AS codigo_postal,
        MAX(localidad) AS localidad,
        MAX(estado) AS estado,
        MAX(pais) AS pais,
        MAX(identificacion) AS identificacion,
        MAX(no_identificacion) AS no_identificacion

    FROM {{ ref('int_venta_persona') }}
    WHERE persona_natural_key IS NOT NULL
    GROUP BY persona_natural_key

)

SELECT * FROM personas