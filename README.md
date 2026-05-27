# Propueta de pipeline proyecto-libera

## Situación actual

Actualmente, la información comercial y financiera se encuentra disponible en vistas/tablas de reporte provenientes del CRM. Estas tablas contienen información relevante sobre ventas, clientes, copropietarios, ingresos y facturación; sin embargo, su estructura responde principalmente a necesidades operativas o de extracción, no necesariamente a un modelo analítico diseñado para responder preguntas de negocio de forma consistente.

Durante el perfilado inicial se identificaron algunos puntos importantes:

| Hallazgo                                                                               | Implicación                                                     |
| -------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `rp_vista_ventas` representa ventas y `id_venta` es único                              | Es una buena base para construir una fact table de ventas       |
| `folio` no es único en ingresos                                                        | No debe utilizarse como llave primaria de ingresos              |
| Una venta puede tener clientes y copropietarios                                        | Se necesita representar una relación venta-persona              |
| `rp_propietarios` mezcla clientes y copropietarios sin distinguir claramente el origen | Conviene usar `rp_clientes` y `rp_copropiedades` por separado   |
| Las tablas actuales están separadas por reporte                                        | La lógica de integración debe centralizarse en modelos dbt      |
| Existen tablas para ventas canceladas                                                  | Deben tratarse con cuidado o incorporarse en una fase posterior |

Como resultado, si los datos se consumen directamente desde las tablas raw, cada análisis tendría que resolver nuevamente problemas de limpieza, llaves, relaciones, deduplicación y reglas de negocio. Esto puede generar consultas duplicadas, resultados inconsistentes y dificultad para mantener reportes en el tiempo.

### Retos identificados

1. Tablas orientadas a reportes, no a modelo analítico
2. Llaves no siempre únicas, por ejemplo folio en ingresos
3. Relación venta-persona no es 1 a 1 por copropietarios
4. Lógica de negocio dispersa en consultas
5. Dificultad para reutilizar métricas de forma consistente

### Propuesta
La propuesta consiste en transformar las tablas raw en un modelo analítico organizado por capas. La capa staging estandariza los datos fuente, la capa warehouse modela hechos, dimensiones y relaciones, y la capa marts expone tablas listas para análisis.

Actualmente, la información se encuentra en tablas raw provenientes de reportes del CRM. Estas tablas contienen los datos necesarios para el análisis, pero no están organizadas bajo un modelo analítico común. Por ejemplo, ingresos contiene folios no únicos, clientes y copropietarios se encuentran en tablas separadas, y algunas vistas consolidadas no conservan claramente el rol de cada persona dentro de una venta.

Esto provoca que cada reporte o consulta tenga que resolver sus propias reglas de limpieza, relación y cálculo. La propuesta busca centralizar estas reglas en dbt, construyendo una arquitectura por capas y un modelo dimensional que permita analizar ventas, ingresos y facturación de forma consistente.

![Data Architecture](https://github.com/fouler44/proyecto-libera/blob/main/docs/data_architecture.png)

Beneficios:

- Grano definido por modelo.
- Llaves surrogate para relaciones confiables.
- Separación entre hechos, dimensiones y bridges.
- Tests de calidad con dbt.
- Marts orientados a preguntas de negocio.

### Comparación actual vs propuesto

| Situación actual                      | Propuesta                               |
| ------------------------------------- | --------------------------------------- |
| Tablas raw consumidas directamente    | Modelos analíticos en dbt               |
| Lógica repetida en consultas          | Lógica centralizada y versionada        |
| Llaves no documentadas                | Surrogate keys y pruebas de unicidad    |
| Clientes/copropietarios mezclados     | `dim_personas` + `bridge_venta_persona` |
| Ingresos sin llave única clara        | `ingreso_key` generado                  |
| Reportes difíciles de mantener        | Marts orientados a negocio              |
| Poca trazabilidad de transformaciones | Lineage y documentación dbt             |

![Data Flow](https://github.com/fouler44/proyecto-libera/blob/main/docs/data_flow.png?raw=true)
