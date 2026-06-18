WITH ventas AS (

    SELECT
        desarrollo_largo,
        desarrollo_corto,
        unidad,
        modelo
    FROM {{ ref('stg_reports__vista_ventas') }}
    WHERE desarrollo_largo IS NOT NULL
      AND unidad IS NOT NULL

),

atributos AS (

    SELECT *
    FROM {{ ref('int_unidades_atributos') }}

),

unidades_base AS (

    SELECT DISTINCT
        v.desarrollo_largo,
        COALESCE(v.desarrollo_corto, a.desarrollo_corto) AS desarrollo_corto,
        a.etapa,
        v.unidad,
        v.modelo

    FROM ventas v
    LEFT JOIN atributos a
        ON v.desarrollo_largo = a.desarrollo_largo
        AND v.unidad = a.unidad

),

grupos AS (

    SELECT *
    FROM {{ ref('grupos_desarrollos') }}

),

final AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'u.desarrollo_largo',
            'u.unidad'
        ]) }} AS unidad_key,

        u.desarrollo_largo,
        u.desarrollo_corto,
        g.grupo_2 AS grupo,
        u.etapa,
        u.unidad,
        u.modelo

    FROM unidades_base u
    LEFT JOIN grupos g
        ON u.desarrollo_largo = g.desarrollo_largo
        AND u.desarrollo_corto = g.desarrollo_corto

)

SELECT * FROM final