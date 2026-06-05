WITH personas AS (

    SELECT
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
    FROM {{ ref('stg_reports__clientes') }}

    UNION ALL

    SELECT
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
    FROM {{ ref('stg_reports__copropiedades') }}

),

prepared AS (

    SELECT
        *,

        CONCAT_WS(
            ' ',
            nombre_cliente,
            apellido_paterno,
            apellido_materno
        ) AS nombre_completo,

        CASE
            WHEN curp IS NOT NULL AND curp != '' THEN curp
            WHEN rfc IS NOT NULL AND rfc != '' THEN rfc
            WHEN email IS NOT NULL AND email != '' THEN LOWER(email)
            ELSE CONCAT_WS(
                '|',
                nombre_cliente,
                apellido_paterno,
                apellido_materno,
                telefono_celular
            )
        END AS persona_natural_key

    FROM personas
    WHERE id_venta IS NOT NULL

)

SELECT DISTINCT * FROM prepared