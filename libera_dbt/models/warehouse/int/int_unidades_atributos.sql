WITH unidades_desde_clientes AS (

    SELECT
        desarrollo_largo,
        desarrollo_corto,
        unidad,
        etapa
    FROM {{ ref('stg_reports__clientes') }}
    WHERE desarrollo_largo IS NOT NULL
      AND unidad IS NOT NULL

),

deduplicated AS (

    SELECT
        desarrollo_largo,
        unidad,
        MAX(desarrollo_corto) AS desarrollo_corto,
        MAX(etapa) AS etapa
    FROM unidades_desde_clientes
    GROUP BY
        desarrollo_largo,
        unidad

)

SELECT * FROM deduplicated