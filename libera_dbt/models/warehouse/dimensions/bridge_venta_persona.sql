WITH personas AS (

    SELECT *
    FROM {{ ref('int_venta_persona') }}

),

ventas AS (

    SELECT
        venta_key,
        id_venta
    FROM {{ ref('fct_ventas') }}

),

final AS (

    SELECT DISTINCT
        v.venta_key,

        {{ dbt_utils.generate_surrogate_key([
            'p.persona_natural_key'
        ]) }} AS persona_key,

        p.id_venta,
        p.rol_persona_en_venta

    FROM personas p
    INNER JOIN ventas v
        ON p.id_venta = v.id_venta

    WHERE p.id_venta IS NOT NULL
      AND p.persona_natural_key IS NOT NULL

)

SELECT * FROM final