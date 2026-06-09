# Propuesta de pipeline analítico para proyecto-libera

## Situación actual

Actualmente, la información comercial y financiera se encuentra disponible en tablas fuente cargadas en la capa `raw`, provenientes de reportes del CRM. Estas tablas contienen información relevante sobre ventas, clientes, copropietarios, ingresos y facturación; sin embargo, su estructura responde principalmente a necesidades operativas o de extracción, no necesariamente a un modelo analítico diseñado para responder preguntas de negocio de forma consistente.

Durante el perfilado inicial se identificaron algunos puntos importantes:

| Hallazgo | Implicación |
| --- | --- |
| `rp_vista_ventas` representa ventas y `id_venta` es único | Es una buena base para construir una fact table de ventas |
| `folio` no es único en ingresos | No debe utilizarse como llave primaria de ingresos |
| Una venta puede tener clientes y copropietarios | Se necesita representar una relación venta-persona |
| `rp_propietarios` mezcla clientes y copropietarios sin distinguir claramente el origen | Conviene usar `rp_clientes` y `rp_copropiedades` por separado |
| Las tablas actuales están separadas por reporte | La lógica de integración debe centralizarse en modelos dbt |
| Existen tablas para ventas canceladas | Deben tratarse con cuidado o incorporarse en una fase posterior |

Como resultado, si los datos se consumen directamente desde la capa `raw`, cada análisis tendría que resolver nuevamente problemas de limpieza, llaves, relaciones, deduplicación y reglas de negocio. Esto puede generar consultas duplicadas, resultados inconsistentes y dificultad para mantener reportes en el tiempo.

## Retos identificados

1. Tablas orientadas a reportes, no a un modelo analítico.
2. Llaves no siempre únicas, por ejemplo `folio` en ingresos.
3. Relación venta-persona no es 1 a 1 debido a la existencia de copropietarios.
4. Lógica de negocio dispersa en consultas.
5. Dificultad para reutilizar métricas de forma consistente.
6. Poca trazabilidad sobre transformaciones y reglas aplicadas.

## Propuesta

La propuesta consiste en transformar las tablas raw provenientes de reportes del CRM en un modelo analítico organizado por capas. La capa `staging` estandariza los datos fuente, la capa `warehouse` modela hechos, dimensiones y relaciones, y la capa `marts` expone tablas listas para análisis.

El objetivo es centralizar en dbt las reglas de limpieza, integración, llaves, relaciones y cálculos de negocio. De esta forma, los reportes y consultas analíticas pueden consumir modelos consistentes en lugar de resolver estas reglas de forma repetida.

![Data Architecture](https://github.com/fouler44/proyecto-libera/blob/main/docs/data_architecture.png?raw=true)

## Beneficios esperados

- Grano definido por modelo.
- Llaves surrogate para relaciones confiables.
- Separación entre hechos, dimensiones y bridges.
- Tests de calidad con dbt.
- Lineage y documentación automática.
- Marts orientados a preguntas de negocio.
- Menor duplicación de lógica en consultas y reportes.

## Comparación actual vs propuesto

| Situación actual | Propuesta |
| --- | --- |
| Tablas raw consumidas directamente | Modelos analíticos en dbt |
| Lógica repetida en consultas | Lógica centralizada y versionada |
| Llaves no documentadas | Surrogate keys y pruebas de unicidad |
| Clientes/copropietarios mezclados | `dim_personas` + `bridge_venta_persona` |
| Ingresos sin llave única clara | `ingreso_key` generado |
| Reportes difíciles de mantener | Marts orientados a negocio |
| Poca trazabilidad de transformaciones | Lineage y documentación dbt |

![Data Flow](https://github.com/fouler44/proyecto-libera/blob/main/docs/data_flow.png?raw=true)

## Matriz de procesos y grano

| Proceso | Modelo propuesto | Grano | Fuente principal |
| --- | --- | --- | --- |
| Ventas | `fct_ventas` | 1 fila por `id_venta` | `rp_vista_ventas` |
| Personas asociadas a ventas | `bridge_venta_persona` | 1 fila por venta-persona | `rp_clientes`, `rp_copropiedades` |
| Personas | `dim_personas` | 1 fila por persona deduplicada | `rp_clientes`, `rp_copropiedades` |
| Unidades | `dim_unidades` | 1 fila por desarrollo-unidad | `rp_vista_ventas` |
| Ingresos | `fct_ingresos` | 1 fila por movimiento de ingreso | `rp_flujo_ingresos` |
| Facturación | `fct_facturas` | 1 fila por factura | `rp_facturas` |

## Alcance inicial

La primera versión del pipeline se enfocará en los procesos de ventas, ingresos y facturación. Para mantener el alcance controlado, las tablas relacionadas con ventas canceladas se considerarán en una fase posterior, ya que requieren validar si comparten el mismo grano y las mismas reglas de negocio que las ventas activas.

Modelos principales considerados:

- `fct_ventas`
- `fct_ingresos`
- `fct_facturas`
- `dim_personas`
- `dim_unidades`
- `dim_fechas`
- `bridge_venta_persona`
- `mart_comercial_ventas`
- `mart_cobranza_por_venta`
- `mart_ingresos_por_periodo`

![Dimensional Model](https://github.com/fouler44/proyecto-libera/blob/main/docs/dimensional_model.png?raw=true)
