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

    SELECT * FROM {{ ref('int_unidades_atributos') }}

),

final AS (

    SELECT DISTINCT
        {{ dbt_utils.generate_surrogate_key([
            'v.desarrollo_largo',
            'v.unidad'
        ]) }} AS unidad_key,

        v.desarrollo_largo,
        COALESCE(v.desarrollo_corto, a.desarrollo_corto) AS desarrollo_corto,
        a.etapa,
        v.unidad,
        v.modelo

    FROM ventas v
    LEFT JOIN atributos a
        ON v.desarrollo_largo = a.desarrollo_largo
       AND v.unidad = a.unidad

)

SELECT * FROM final