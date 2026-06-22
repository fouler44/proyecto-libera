# Resumen de la capa staging

Este documento resume el estado actual de `models/staging/` en el proyecto dbt
de Libera. Su objetivo es dejar claro que hay en esta capa, que hace cada modelo,
que fuente raw consume, que pruebas existen y que riesgos o decisiones siguen
abiertas.

La revision se hizo contra el SQL y YAML actuales del repositorio, usando los
documentos de contexto solo como apoyo. La capa staging actual esta concentrada
en:

```text
libera_dbt/models/staging/reports/
```

## Rol de staging

`staging` es la primera transformacion formal despues de `raw`.

Su responsabilidad principal es:

- leer tablas fuente desde `source('raw', ...)`;
- renombrar columnas a snake_case;
- limpiar texto con `trim`, `upper`, `lower` o `initcap`;
- convertir fechas y tipos;
- corregir algunos valores sucios conocidos;
- dejar una version mas estable para `warehouse` y `marts`.

Staging no deberia ser todavia la capa de negocio final. La mayor parte de la
logica de entidades, llaves surrogate, deduplicacion fuerte y relaciones vive en
`warehouse`.

En `dbt_project.yml`, staging se configura asi:

```yaml
staging:
  +schema: staging
  +materialized: view
```

Por lo tanto, estos modelos se materializan como vistas.

## Fuentes raw declaradas

Las fuentes estan declaradas en `_reports__sources.yml` bajo:

```yaml
source: raw
database: raw
schema: raw
```

| Fuente raw | Modelo staging | Estado / uso |
| --- | --- | --- |
| `rp_vista_ventas` | `stg_reports__vista_ventas` | Fuente principal de ventas vigentes/observadas |
| `rp_clientes` | `stg_reports__clientes` | Clientes principales y atributos de venta |
| `rp_copropiedades` | `stg_reports__copropiedades` | Copropietarios asociados a ventas |
| `rp_flujo_ingresos` | `stg_reports__flujo_ingresos` | Movimientos de ingresos |
| `rp_facturas` | `stg_reports__facturas` | Facturas emitidas |
| `rp_cartera_vencida_detallado` | `stg_reports__cartera_vencida` | Pagos vencidos a detalle |
| `rp_dashboard_operaciones` | `stg_reports__dashboard_operaciones` | Dashboard operativo legacy |
| `rp_cronograma_unidades` | `stg_reports__cronograma_unidades` | Hitos operativos por unidad |
| `rp_cliente_canceladas` | `stg_reports__cliente_canceladas` | Clientes de ventas canceladas |
| `rp_copropiedades_canceladas` | `stg_reports__copropiedades_canceladas` | Copropietarios de ventas canceladas |
| `rp_flujo_ingresos_ventacancelada` | `stg_reports__flujo_ingresos_ventacancelada` | Ingresos de ventas canceladas |

## Clasificacion actual

### Staging principal del modelo actual

Estos modelos alimentan directamente `warehouse` o marts actuales:

- `stg_reports__vista_ventas`
- `stg_reports__clientes`
- `stg_reports__copropiedades`
- `stg_reports__flujo_ingresos`
- `stg_reports__facturas`
- `stg_reports__cartera_vencida`
- `stg_reports__dashboard_operaciones`
- `stg_reports__cronograma_unidades`

### Staging de fase 2 / canceladas

Estos modelos ya existen y estan etiquetados como `phase_2` y `canceladas`, pero
todavia no forman parte del modelo principal:

- `stg_reports__cliente_canceladas`
- `stg_reports__copropiedades_canceladas`
- `stg_reports__flujo_ingresos_ventacancelada`

## Verificacion de riesgos 2026-06-22

Riesgo 1, normalizacion inconsistente de `unidad`: mitigado. Todos los staging
que exponen `unidad` usan `trim(upper(UNIDAD))`.

Riesgo 2, cast directo en fechas: mitigado para fechas. Las conversiones de
fecha en staging usan `try_cast`; quedan casts directos no fecha para campos
como `codigo_postal`, `monto_pagado` y algunos casos de `edad`.

## Resumen rapido

| Modelo staging | Fuente | Uso downstream principal |
| --- | --- | --- |
| `stg_reports__vista_ventas` | `rp_vista_ventas` | `fct_ventas`, `dim_unidades` |
| `stg_reports__clientes` | `rp_clientes` | `int_ventas_atributos`, `int_venta_persona`, `int_unidades_atributos` |
| `stg_reports__copropiedades` | `rp_copropiedades` | `int_venta_persona` |
| `stg_reports__flujo_ingresos` | `rp_flujo_ingresos` | `fct_ingresos` |
| `stg_reports__facturas` | `rp_facturas` | `fct_facturas` |
| `stg_reports__cartera_vencida` | `rp_cartera_vencida_detallado` | `fct_pagos_vencidos` |
| `stg_reports__dashboard_operaciones` | `rp_dashboard_operaciones` | `fct_ventas`, `mart_dash_cron` |
| `stg_reports__cronograma_unidades` | `rp_cronograma_unidades` | `fct_cronograma_unidades` |
| `stg_reports__cliente_canceladas` | `rp_cliente_canceladas` | Preparado, sin uso principal actual |
| `stg_reports__copropiedades_canceladas` | `rp_copropiedades_canceladas` | Preparado, sin uso principal actual |
| `stg_reports__flujo_ingresos_ventacancelada` | `rp_flujo_ingresos_ventacancelada` | Preparado, sin uso principal actual |

## `stg_reports__vista_ventas`

### Objetivo

Estandarizar la vista principal de ventas. Es la fuente base de `fct_ventas` y
tambien participa en `dim_unidades`.

### Fuente

`source('raw', 'rp_vista_ventas')`

### Columnas principales

- `id_venta`
- `desarrollo_largo`
- `desarrollo_corto`
- `unidad`
- `modelo`
- `status_unidad`
- `equipo`
- `status_venta`
- `plan`
- `precio_venta`
- `fecha_primer_enganche`
- `fecha_ultimo_pago_enganche`

### Transformaciones importantes

- Normaliza desarrollo largo/corto, unidad, modelo y equipo con
  `trim(upper(...))`.
- Convierte fechas de enganche con `try_cast`.
- Trata valores con texto `NULL` en `FECHAULTIMOPAGOENGANCHE`.

### Uso downstream

- `fct_ventas`
- `dim_unidades`

### Tests actuales

- `id_venta`: `not_null`, `unique`
- combinacion unica: `desarrollo_largo + unidad`

### Riesgos o pendientes

- Es importante validar con negocio si esta fuente representa todas las ventas o
  solo ventas vigentes/observadas.

## `stg_reports__clientes`

### Objetivo

Estandarizar clientes principales y atributos contractuales/comerciales de la
venta.

Este modelo cumple dos funciones:

- aportar atributos de venta que no vienen completos en `rp_vista_ventas`;
- aportar personas con rol `cliente_principal`.

### Fuente

`source('raw', 'rp_clientes')`

### Columnas principales

Datos de venta:

- `id_venta`
- `desarrollo_largo`
- `desarrollo_corto`
- `unidad`
- `etapa`
- `asesor`
- `status_venta`
- `fecha_contrato`
- `fecha_firma_contrato`
- `plan`
- `num_mensualidades`
- `precio_venta`
- `enganche`
- `financiamiento`
- `status_escritura`
- `fecha_escritura`
- `valor_escritura`
- `dia_pago`
- `fecha_prospectacion`
- `fecha_registro_venta`
- `fecha_aprobacion_jd`
- `fecha_registro_carga_contrato`
- `entro_dv`

Datos de persona:

- `nombre_cliente`
- `apellido_paterno`
- `apellido_materno`
- `edad`
- `lugar_nacimiento`
- `rfc`
- `curp`
- domicilio y contacto
- `sexo`
- `estado_civil`
- `regimen`
- `rol_persona_en_venta`
- `es_venta_cancelada`

### Transformaciones importantes

- Normaliza textos con `trim` y `upper`.
- Convierte varias fechas usando `try_cast` y limpia valores `'NULL'`.
- Corrige el plan mal escrito `48 MEESES` a `48 MESES`.
- Convierte la edad textual `CUARENTA Y DOS` a `42`.
- Corrige encoding de `LUGARNACIMIENTO` con `decode(encode(...))`.
- Marca `rol_persona_en_venta = 'cliente_principal'`.
- Marca `es_venta_cancelada = false`.

### Uso downstream

- `int_ventas_atributos`
- `int_venta_persona`
- `int_unidades_atributos`

### Tests actuales

- `id_venta`: `not_null`

### Riesgos o pendientes

- No tiene test de unicidad por `id_venta`, probablemente porque puede haber mas
  de una fila o porque se agregan atributos despues en `int_ventas_atributos`.
- La correccion de edad solo cubre el caso conocido `CUARENTA Y DOS`. Si aparecen
  otros textos, `cast(trim(EDAD) as int)` puede fallar.
- `id_venta` no tiene test de unicidad porque este staging puede alimentar
  agregaciones posteriores por venta.

## `stg_reports__copropiedades`

### Objetivo

Estandarizar copropietarios asociados a ventas. Tiene una estructura muy parecida
a `stg_reports__clientes`, pero el rol cambia a `copropietario`.

### Fuente

`source('raw', 'rp_copropiedades')`

### Columnas principales

Comparte practicamente las mismas columnas de venta y persona que
`stg_reports__clientes`.

Las columnas distintivas son:

- `rol_persona_en_venta = 'copropietario'`
- `es_venta_cancelada = false`

### Transformaciones importantes

- Normaliza textos, incluyendo `unidad` con `trim(upper(...))`.
- Convierte fechas con `try_cast`.
- Corrige `48 MEESES` a `48 MESES`.
- Corrige `CUARENTA Y DOS` a `42`.
- Corrige encoding de `LUGARNACIMIENTO`.

### Uso downstream

- `int_venta_persona`

### Tests actuales

- `id_venta`: `not_null`

### Riesgos o pendientes

- La edad todavia usa `cast(trim(EDAD) as int)` despues de corregir el caso
  conocido `CUARENTA Y DOS`; si aparecen otros textos, podria fallar.

## `stg_reports__flujo_ingresos`

### Objetivo

Estandarizar movimientos de ingresos. Alimenta `fct_ingresos`.

### Fuente

`source('raw', 'rp_flujo_ingresos')`

### Columnas principales

- `id_venta`
- `status_ingreso`
- `status_venta`
- `folio`
- `fecha_ingreso`
- `fecha_amortizacion`
- `desarrollo_largo`
- `desarrollo_corto`
- `unidad`
- `etapa`
- `cliente`
- `banco`
- `forma_pago`
- `concepto`
- `referencia_ingresos`
- `monto_pagado`
- `status_tercero`
- `nombre_tercero`
- `fecha_captura`

### Transformaciones importantes

- Normaliza desarrollo, unidad, cliente, banco y tercero con mayusculas.
- Usa `initcap` para `forma_pago`.
- Convierte fechas de ingreso, amortizacion y captura con `try_cast`.
- Conserva `status_ingreso` y `status_venta` porque pueden distinguir filas
  que comparten folio, referencia, monto y fechas.

### Uso downstream

- `fct_ingresos`
- analisis exploratorio `relacion_ingresos_ventas.sql`

### Tests actuales

- `monto_pagado >= 0`

### Riesgos o pendientes

- No tiene test `not_null` para `monto_pagado`; el filtro fuerte ocurre despues
  en `fct_ingresos`.
- `folio` no es llave confiable ni unica. Esto ya se resuelve en `fct_ingresos`
  con una llave surrogate compuesta.
- Caso observado en build: el `id_venta` 2303 y folio 19311 aparecio con la
  misma referencia, monto y fechas, pero con `status_ingreso` distinto
  (`Activo` y `Cancelado`). Por eso el estatus forma parte de la llave en
  `fct_ingresos`.
- La relacion con `fct_ventas` no debe forzarse todavia; hay ingresos que pueden
  no existir en `rp_vista_ventas`.

## `stg_reports__facturas`

### Objetivo

Estandarizar facturas emitidas desde `rp_facturas`.

### Fuente

`source('raw', 'rp_facturas')`

### Columnas principales

- `folio_general`
- `uuid`
- `uuid_relacionado`
- `rfc_emisor`
- `rfc_receptor`
- `razon_social_emisor`
- `razon_social_receptor`
- `fecha_timbrado`
- `tipo_factura`
- `total_factura`
- `folio_seguimiento`
- `tipo_pago`

### Transformaciones importantes

- Renombra columnas fiscales.
- Normaliza razones sociales con `upper`.
- Convierte `FECHA_TIMBRADO` con `try_cast`.

### Uso downstream

- `fct_facturas`

### Tests actuales

- `uuid`: `not_null`, `unique`

### Riesgos o pendientes

- `fct_facturas` tiene fallback para construir `factura_key` sin `uuid`, pero el
  staging exige `uuid` no nulo y unico. Conviene decidir si UUID sera obligatorio
  o si se aceptaran facturas sin UUID.
- No existe relacion confiable con ventas en esta fase.

## `stg_reports__dashboard_operaciones`

### Objetivo

Estandarizar el dashboard operativo legacy. Es clave para fase 2 porque
`mart_dash_cron` parte de este staging para reemplazar `tc_gl_Dash_Cron`.

### Fuente

`source('raw', 'rp_dashboard_operaciones')`

### Columnas principales

- `id_venta`
- `equipo`
- `desarrollo_largo`
- `desarrollo_corto`
- `unidad`
- `modelo`
- `etapa`
- `precio_lista`
- `precio_m2`
- `asesor`
- `status_unidad`
- `status_venta`
- `cliente`
- `campania`
- `vendedor_externo`
- `fecha_de_status`
- `plan`
- `numero_mensualidades`
- `numero_enganches`
- `precio_venta`
- `precio_m2_venta`
- `enganche`
- `financiamiento`
- `total_cobrado`
- `saldo_total`
- `total_vencido`
- `enganche_incompleto`
- `requiere_factura`
- `fecha_primer_enganche`
- `fecha_ultimo_pago_enganche`
- `monto_primer_enganche`
- `comision_asesor`
- `comision_libera`

### Transformaciones importantes

- Normaliza campos descriptivos con `trim(upper(...))`.
- Convierte fechas con `try_cast`.
- Convierte campos vacios de vendedor/comisiones a `null`.
- Usa `coalesce(..., 0)` para `numero_mensualidades` y `numero_enganches`.
- Conserva metricas operativas del reporte legacy como `total_cobrado`,
  `saldo_total` y `total_vencido`.
- Elimina copias exactas con `select distinct` despues de estandarizar campos.

### Uso downstream

- `fct_ventas`, para traer `precio_m2_venta` y `requiere_factura`.
- `mart_dash_cron`, como base principal del reemplazo del dashboard legacy.
- analisis exploratorio `sandbox.sql`.

### Tests actuales

- `id_venta`: `not_null`, `unique`

### Riesgos o pendientes

- Las metricas `total_cobrado`, `saldo_total` y `total_vencido` vienen ya
  calculadas desde el reporte operativo. Son utiles para replica legacy, pero
  pueden diferir de metricas reconstruidas desde facts atomicas.
- Campos como `campania`, `vendedor_externo`, `comision_asesor` y
  `comision_libera` todavia requieren validacion de significado de negocio.
- `precio_lista` y `precio_m2` podrian ser atributos de unidad o de evento,
  dependiendo de si cambian con el tiempo.
- Caso observado en build: `id_venta` 2252 y 2263 llegaron duplicados como
  copias exactas fila a fila. La deduplicacion actual cubre copias identicas;
  si aparecen filas con el mismo `id_venta` pero valores distintos, se debe
  definir una regla de prioridad de negocio.

## `stg_reports__cronograma_unidades`

### Objetivo

Estandarizar hitos del cronograma operativo de unidades.

### Fuente

`source('raw', 'rp_cronograma_unidades')`

### Columnas principales

- `equipo`
- `desarrollo_largo`
- `desarrollo_corto`
- `unidad`
- `asesor`
- `cliente`
- `campania`
- `rechazado`
- `proceso`
- `esperando_autorizacion`
- `aprobado_direccion_ventas`
- `aprobado_juridico`
- `finalizado`
- `finalizado_liquidado`

### Transformaciones importantes

- Convierte todos los hitos a fecha con `try_cast`.
- Normaliza textos con `trim(upper(...))`.
- Invierte los nombres de desarrollo:
  - raw `DESARROLLO_CORTO` pasa a `desarrollo_largo`;
  - raw `DESARROLLO_LARGO` pasa a `desarrollo_corto`.

### Uso downstream

- `fct_cronograma_unidades`

### Tests actuales

- `desarrollo_largo`: `not_null`
- `unidad`: `not_null`

### Riesgos o pendientes

- La inversion de columnas parece intencional por el comportamiento del reporte
  original, pero debe quedar documentada porque es facil confundirse.
- No tiene `id_venta`; la relacion se hace por `desarrollo_largo + unidad` o
  `unidad_key`, que es mas debil que una llave de venta.

## `stg_reports__cartera_vencida`

### Objetivo

Estandarizar el detalle de pagos vencidos. Alimenta `fct_pagos_vencidos`.

### Fuente

`source('raw', 'rp_cartera_vencida_detallado')`

### Columnas principales

- `id_venta`
- `equipo`
- `desarrollo_largo`
- `desarrollo_corto`
- `unidad`
- `cliente`
- `email`
- `telefono_celular`
- `telefono_local`
- `dias_atraso`
- `no_pago`
- `fecha_pago`
- `monto_vencido`
- `tipo_pago`

### Transformaciones importantes

- Normaliza desarrollo, unidad y cliente con mayusculas.
- Conserva contacto del cliente como texto.
- Convierte `FECHAPAGO` con `try_cast`.
- Normaliza `tipo_pago` con `initcap(trim(lower(...)))`.

### Uso downstream

- `fct_pagos_vencidos`

### Tests actuales

- `monto_vencido`: `not_null`
- `fecha_pago`: `not_null`
- `no_pago`: `not_null`

### Riesgos o pendientes

- La relacion con ventas no debe forzarse todavia. Puede haber cartera con
  `id_venta` que no exista en `fct_ventas`.
- Los datos de contacto no necesariamente deben conectarse a `dim_personas`; por
  ahora son texto informativo.

## `stg_reports__cliente_canceladas`

### Objetivo

Preparar clientes principales de ventas canceladas para una futura fase de
modelado de cancelaciones.

### Fuente

`source('raw', 'rp_cliente_canceladas')`

### Columnas principales

Tiene una estructura casi igual a `stg_reports__clientes`.

Columnas distintivas:

- `rol_persona_en_venta = 'cliente_principal'`
- `es_venta_cancelada = true`

### Uso downstream

No alimenta el warehouse principal actual.

### Tests actuales

No tiene tests. Solo tiene tags:

- `phase_2`
- `canceladas`

### Riesgos o pendientes

- Convierte fechas principales con `try_cast`; el modelo sigue separado hasta
  disenar formalmente el subdominio de ventas canceladas.
- Debe mantenerse separado hasta disenar formalmente el subdominio de ventas
  canceladas.

## `stg_reports__copropiedades_canceladas`

### Objetivo

Preparar copropietarios de ventas canceladas.

### Fuente

`source('raw', 'rp_copropiedades_canceladas')`

### Columnas principales

Tiene una estructura casi igual a `stg_reports__copropiedades`.

Columnas distintivas:

- `rol_persona_en_venta = 'copropietario'`
- `es_venta_cancelada = true`

### Uso downstream

No alimenta el warehouse principal actual.

### Tests actuales

No tiene tests. Solo tiene tags:

- `phase_2`
- `canceladas`

### Riesgos o pendientes

- Mismo pendiente de robustez que `stg_reports__copropiedades`: la edad usa
  `cast(trim(EDAD) as int)` para valores no cubiertos por la correccion manual.
- A futuro podria alimentar una tabla puente o dimension de personas para
  canceladas, pero todavia no esta integrado.

## `stg_reports__flujo_ingresos_ventacancelada`

### Objetivo

Preparar ingresos asociados a ventas canceladas.

### Fuente

`source('raw', 'rp_flujo_ingresos_ventacancelada')`

### Columnas principales

- `status_ingreso`
- `status_venta`
- `folio`
- `fecha_ingreso`
- `fecha_amortizacion`
- `desarrollo_largo`
- `desarrollo_corto`
- `unidad`
- `etapa`
- `cliente`
- `banco`
- `forma_pago`
- `concepto`
- `referencia_ingresos`
- `monto_pagado`
- `status_tercero`
- `nombre_tercero`
- `es_venta_cancelada`

### Transformaciones importantes

- Estandariza texto de forma similar a `stg_reports__flujo_ingresos`.
- Marca `es_venta_cancelada = true`.

### Uso downstream

No alimenta el warehouse principal actual.

### Tests actuales

No tiene tests. Solo tiene tags:

- `phase_2`
- `canceladas`

### Riesgos o pendientes

- El propio SQL documenta que esta fuente no tiene `id_venta` ni `fecha_captura`
  como su version no cancelada.
- Al no tener `id_venta`, cualquier relacion futura con ventas canceladas tendra
  que hacerse con otra llave o logica de conciliacion.

## Tests actuales de staging

La seleccion `path:models/staging` contiene 11 modelos y 16 tests.

Tests declarados:

- `stg_reports__vista_ventas.id_venta`: `not_null`, `unique`
- `stg_reports__vista_ventas`: combinacion unica
  `desarrollo_largo + unidad`
- `stg_reports__clientes.id_venta`: `not_null`
- `stg_reports__copropiedades.id_venta`: `not_null`
- `stg_reports__flujo_ingresos.monto_pagado`: `>= 0`
- `stg_reports__facturas.uuid`: `not_null`, `unique`
- `stg_reports__dashboard_operaciones.id_venta`: `not_null`, `unique`
- `stg_reports__cronograma_unidades.desarrollo_largo`: `not_null`
- `stg_reports__cronograma_unidades.unidad`: `not_null`
- `stg_reports__cartera_vencida.monto_vencido`: `not_null`
- `stg_reports__cartera_vencida.fecha_pago`: `not_null`
- `stg_reports__cartera_vencida.no_pago`: `not_null`
- test singular `distintos_asesores`

Modelos sin tests directos:

- `stg_reports__cliente_canceladas`
- `stg_reports__copropiedades_canceladas`
- `stg_reports__flujo_ingresos_ventacancelada`

## Problemas y decisiones abiertas

### Normalizacion de `unidad`

Verificacion 2026-06-22: los staging que exponen `unidad` ya usan la regla
consistente `trim(upper(UNIDAD))`, incluyendo ventas, clientes, copropiedades,
ingresos, dashboard, cronograma y cartera vencida.

Esto mitiga el riesgo de joins silenciosamente fallidos en llaves construidas
con `desarrollo_largo + unidad`.

### `cast` vs `try_cast`

Verificacion 2026-06-22: las conversiones de fecha en staging ya usan
`try_cast`. Esto reduce el riesgo de que un valor invalido de raw rompa el
build completo.

Quedan casts directos no relacionados con fechas, por ejemplo `codigo_postal`,
`monto_pagado` y algunos campos de `edad`. Esos son pendientes de robustez
distintos al riesgo original de fechas.

### Fuentes sin freshness

Las sources estan declaradas, pero no tienen pruebas de freshness ni tests sobre
columnas raw. Esto no es obligatorio, pero seria util si el pipeline depende de
actualizaciones periodicas desde Manivela/CRM.

### Canceladas fuera del modelo principal

Las tablas canceladas ya tienen staging, pero todavia no alimentan facts,
dimensiones ni marts oficiales. Esto es correcto por ahora: modelarlas requiere
decidir si seran un subdominio separado o si se integraran con ventas activas.

### Cronograma sin `id_venta`

El cronograma trabaja por unidad/desarrollo, no por venta. Por eso debe
relacionarse con cuidado usando `unidad_key`. Esto debe seguir documentado para
evitar asumir que mide directamente la venta.

## Verificacion realizada

Durante la revision se ejecuto:

```bash
dbt parse
dbt compile --select path:models/staging
dbt ls --select path:models/staging --output name
dbt ls --select path:models/staging --resource-type test --output name
```

Resultados:

- `dbt parse` termino correctamente.
- `dbt compile --select path:models/staging` termino correctamente.
- dbt detecto 11 modelos staging.
- dbt detecto 11 sources raw relacionadas con staging.
- dbt detecto 16 tests asociados a staging.

Importante: `dbt compile` valida grafo, Jinja y compilacion, pero no ejecuta los
modelos contra Databricks. Para validar datos reales, duplicados y errores de
conversion en runtime, hace falta correr `dbt build`.

## Prioridades recomendadas

1. Documentar en YAML las columnas principales de cada staging.
2. Decidir si `uuid` de facturas es obligatorio o si el fallback de
   `fct_facturas` deberia permitir nulos.
3. Evaluar si los casts no fecha (`edad`, montos, codigos postales) deben
   cambiar gradualmente a `try_cast`.
4. Mantener canceladas como fase 2 hasta modelarlas como subdominio formal.

## Lectura recomendada

Para entender la capa staging rapidamente:

1. `stg_reports__vista_ventas` es la base de ventas.
2. `stg_reports__clientes` y `stg_reports__copropiedades` son la base de
   personas asociadas a ventas.
3. `stg_reports__flujo_ingresos` es la base de ingresos.
4. `stg_reports__facturas` es la base fiscal, todavia sin relacion confiable con
   ventas.
5. `stg_reports__dashboard_operaciones` es la base del reemplazo legacy
   `mart_dash_cron`.
6. `stg_reports__cronograma_unidades` es avance operativo por unidad, no por
   venta.
7. `stg_reports__cartera_vencida` es el detalle de pagos vencidos, actualmente
   modelado en warehouse como `fct_pagos_vencidos`.
8. Los tres staging de canceladas estan preparados, pero aun no forman parte del
   modelo principal.
