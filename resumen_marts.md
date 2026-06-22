# Resumen de la capa marts

Este documento resume el estado actual de la capa `models/marts` del proyecto
dbt de Libera. La idea es dejar un punto comun de contexto: que hace cada mart,
que modelos consume, cual es su grano, que pruebas tiene y que problemas o
decisiones siguen abiertas.

La revision se hizo contra el SQL y YAML actuales del repositorio, no solo contra
los documentos previos. Algunos documentos anteriores usan nombres viejos, por
ejemplo `fct_cartera_vencida_detallado`; en el proyecto actual ese modelo se
llama `fct_pagos_vencidos`.

## Rol de la capa marts

La capa `marts` contiene tablas finales orientadas a preguntas concretas de
negocio. A diferencia de `warehouse`, donde se modelan facts, dimensiones,
puentes e intermedios reutilizables, aqui los modelos ya estan pensados para
consumo analitico directo.

En este proyecto, los marts se materializan como tablas porque en
`dbt_project.yml` la carpeta `marts` tiene:

```yaml
marts:
  +schema: marts
  +materialized: table
```

## Clasificacion actual

### Marts oficiales o principales

Estos modelos son los mas importantes para uso actual:

- `mart_dash_cron`
- `mart_comercial_ventas`
- `mart_cobranza_por_venta`

### Marts de soporte o analisis secundario

Son utiles, pero no son el centro del reemplazo del dashboard operativo:

- `mart_facturacion`
- `mart_ingresos_por_periodo`
- `mart_cartera_vencida_por_venta`

### Mart experimental o futuro

Este modelo intenta reconstruir metricas desde facts del warehouse. No debe
tratarse todavia como reemplazo directo del reporte legacy:

- `experimental/mart_dash_cron_reconstruido`

## Resumen rapido

| Mart | Estado | Grano esperado | Uso principal |
| --- | --- | --- | --- |
| `mart_dash_cron` | Principal fase 2 | 1 fila por venta/unidad del dashboard operativo | Reemplazar `tc_gl_Dash_Cron` de forma directa |
| `mart_comercial_ventas` | Sano | 1 fila por venta | Analisis comercial de venta, unidad y cliente |
| `mart_cobranza_por_venta` | Sano fase 1 | 1 fila por venta | Venta vs ingresos cobrados, separando bruto y activo |
| `mart_cartera_vencida_por_venta` | Soporte testeado | 1 fila por venta con cartera vencida | Analisis agregado de pagos vencidos |
| `mart_ingresos_por_periodo` | Soporte testeado | 1 fila por periodo + atributos financieros | Ingresos por mes, banco, forma de pago, concepto |
| `mart_facturacion` | Aislado/descontinuado | 1 fila por factura/UUID | Soporte fiscal independiente, no conectado a ventas |
| `mart_dash_cron_reconstruido` | Experimental | 1 fila por venta | Version futura reconstruida desde warehouse |

## Verificacion de riesgos 2026-06-22

Riesgo 4, ingresos cancelados en metricas de cobranza: mitigado en los marts de
cobranza. `mart_cobranza_por_venta` conserva `total_ingresado` y
`total_ingresado_bruto` como metricas brutas, pero usa
`total_ingresado_activo` para `saldo_estimado` y `porcentaje_cobrado`.
`mart_dash_cron_reconstruido` conserva `total_cobrado_bruto` y usa
`total_cobrado` filtrado a `status_ingreso = 'Activo'`.

Riesgo 5, metricas legacy en `mart_dash_cron`: mitigado por documentacion. Las
columnas `total_cobrado`, `saldo_total` y `total_vencido` estan documentadas en
YAML como metricas legacy del reporte operativo original.

Riesgo 6, confusion del mart reconstruido con el oficial: mitigado. El modelo
vive en `models/marts/experimental/` y tiene tags `experimental` y
`reconciliacion`.

Riesgo 7, facturacion aislada: decidido y documentado. `mart_facturacion` y
`fct_facturas` se conservan como soporte fiscal aislado; no existe llave
confiable para relacionarlos con ventas y no deben usarse para analisis directo
de ventas o cobranza.

## `mart_dash_cron`

### Objetivo

Es el mart principal de fase 2. Su objetivo es reemplazar de forma directa el
reporte legacy `tc_gl_Dash_Cron`.

El reporte original se construia conceptualmente con:

```text
rp_dashboard_operaciones
+ rp_cronograma_unidades
+ tc_gl_Grupos
```

El reemplazo en dbt es:

```text
stg_reports__dashboard_operaciones
+ fct_cronograma_unidades
+ dim_unidades.grupo
```

### Modelos que consume

- `stg_reports__dashboard_operaciones`
- `fct_cronograma_unidades`
- `dim_unidades`

### Logica

1. Parte de `stg_reports__dashboard_operaciones`.
2. Genera `unidad_key` usando `desarrollo_largo + unidad`.
3. Une cronograma por `unidad_key`.
4. Une `dim_unidades` por `unidad_key` para traer `grupo`.
5. Excluye los desarrollos `UH MAY` y `DEMO 2024`.

### Columnas importantes

Como selecciona `dashboard.*`, conserva muchas columnas del dashboard operativo:

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
- `unidad_key`
- fechas y estatus del cronograma
- `grupo`

### Interpretacion

Este mart no intenta recalcular `total_cobrado`, `saldo_total` o
`total_vencido` desde facts atomicas. Eso es intencional: su proposito es
reproducir el dashboard operativo original con staging limpio y joins
controlados.

En `_mart__models.yml` esas tres columnas estan documentadas como metricas
legacy del reporte operativo original para evitar compararlas directamente con
metricas reconstruidas desde facts.

### Tests actuales

En `_mart__models.yml` tiene:

- `id_venta`: `not_null`, `unique`
- `unidad_key`
- `unidad`
- `desarrollo_largo`
- `desarrollo_corto`
- `precio_venta`

### Problemas o riesgos

- Depende de que `stg_reports__dashboard_operaciones` ya venga deduplicado. En
  el build se observaron copias exactas para `id_venta` 2252 y 2263; si en el
  futuro aparecen duplicados con valores distintos, este mart heredara esa
  ambiguedad.
- El filtro `where dashboard.desarrollo_corto not in (...)` tambien excluye
  filas donde `desarrollo_corto` sea `null`.
- Como conserva metricas del reporte operativo, estas pueden diferir de metricas
  reconstruidas desde `fct_ingresos` o `fct_pagos_vencidos`.

## `mart_comercial_ventas`

### Objetivo

Responder preguntas comerciales basicas:

- Que se vendio.
- En que desarrollo y unidad.
- Quien es el cliente principal.
- Cuantos copropietarios tiene.
- Cual fue el precio de venta.

### Modelos que consume

- `fct_ventas`
- `dim_unidades`
- `bridge_venta_persona`
- `dim_personas`

### Grano

Una fila por venta.

### Logica

1. Parte de `fct_ventas`.
2. Une `dim_unidades` por `unidad_key`.
3. Agrega personas primero a nivel `venta_key` en el CTE
   `personas_por_venta`.
4. Obtiene cliente principal, email, telefono y numero de copropietarios.
5. Une esa agregacion a la venta.

Esta logica evita duplicar ventas cuando una venta tiene varios copropietarios.

### Columnas importantes

- `venta_key`
- `id_venta`
- datos de unidad: `desarrollo_largo`, `desarrollo_corto`, `etapa`, `unidad`,
  `modelo`
- datos de venta: `status_venta`, `status_unidad`, `status_escritura`, `plan`,
  `equipo`, `asesor`
- datos de cliente: `cliente_principal`, `email_cliente_principal`,
  `telefono_cliente_principal`
- `numero_copropietarios`
- `tiene_copropietarios`
- fechas de venta
- metricas comerciales: `precio_venta`, `enganche`, `financiamiento`,
  `valor_escritura`, `num_mensualidades`, `dia_pago`, `entro_dv`

### Tests actuales

En `_mart__models.yml` tiene:

- `venta_key`: `unique`, `not_null`
- `id_venta`: `unique`, `not_null`
- `precio_venta`: `not_null`

### Problemas o riesgos

- Si existieran varios registros con rol `cliente_principal` para una misma
  venta, el modelo usa `max(...)` y elegiria uno de forma silenciosa.
- Conviene una auditoria futura para validar que cada venta tenga exactamente
  un cliente principal.

## `mart_cobranza_por_venta`

### Objetivo

Responder:

- Cuanto se vendio por venta.
- Cuanto se ha ingresado/cobrado.
- Cuanto queda pendiente de forma estimada.
- Cual es el porcentaje cobrado.

### Modelos que consume

- `fct_ventas`
- `dim_unidades`
- `fct_ingresos`

### Grano

Una fila por venta.

### Logica

1. Parte de `fct_ventas`.
2. Agrega `fct_ingresos` por `venta_key` antes del join.
3. Calcula:
   - `total_ingresado`: ingreso bruto sin filtrar `status_ingreso`
   - `total_ingresado_bruto`: alias explicito del ingreso bruto
   - `total_ingresado_activo`: solo ingresos con `status_ingreso = 'Activo'`
   - `numero_movimientos_ingreso`
   - `fecha_primer_ingreso`
   - `fecha_ultimo_ingreso`
4. Une la agregacion a ventas.
5. Calcula:
   - `saldo_estimado = precio_venta - total_ingresado_activo`
   - `porcentaje_cobrado = total_ingresado_activo / precio_venta * 100`

### Columnas importantes

- `venta_key`
- `id_venta`
- datos de unidad
- datos de venta
- fechas comerciales
- `precio_venta`
- `total_ingresado`
- `total_ingresado_bruto`
- `total_ingresado_activo`
- `numero_movimientos_ingreso`
- `fecha_primer_ingreso`
- `fecha_ultimo_ingreso`
- `saldo_estimado`
- `porcentaje_cobrado`

### Tests actuales

En `_mart__models.yml` tiene:

- `venta_key`: `unique`, `not_null`
- `id_venta`: `unique`, `not_null`
- `total_ingresado`: `not_null`
- `total_ingresado_bruto`: `not_null`
- `total_ingresado_activo`: `not_null`
- `saldo_estimado`: `not_null`

### Interpretacion

Este mart es sano como fase 1 de cobranza. No incorpora cartera vencida. Eso no
es un error; simplemente significa que responde venta vs ingresos, no detalle de
morosidad.

### Problemas o riesgos

- No incluye `fct_pagos_vencidos`.
- Ignora ingresos cuyo `venta_key` sea `null`.
- Conserva `total_ingresado` como metrica bruta por compatibilidad. Para
  analisis de saldo/cobranza se debe usar `total_ingresado_activo`, que excluye
  movimientos con `status_ingreso` distinto de `Activo`.
- El porcentaje esta en escala 0 a 100 con 2 decimales, alineado con
  `mart_dash_cron_reconstruido`.

## `mart_cartera_vencida_por_venta`

### Objetivo

Crear una vista agregada de cartera vencida a nivel venta:

- monto total vencido;
- numero de pagos vencidos;
- dias maximos y promedio de atraso;
- primera y ultima fecha de pago vencido;
- datos de contacto del cliente.

### Modelos que consume

- `fct_pagos_vencidos`
- `dim_unidades`
- `fct_ventas`

### Grano esperado

Una fila por venta con cartera vencida agregada.

En el SQL actual agrupa por:

- `venta_key`
- `id_venta`
- `unidad_key`

### Columnas importantes

- `venta_key`
- `id_venta`
- `unidad_key`
- `equipo`
- `desarrollo_largo`
- `desarrollo_corto`
- `grupo`
- `unidad`
- `cliente`
- `email`
- `telefono_celular`
- `telefono_local`
- `total_vencido`
- `numero_pagos_vencidos`
- `dias_atraso_maximo`
- `dias_atraso_promedio`
- `fecha_primer_pago_vencido`
- `fecha_ultimo_pago_vencido`

### Tests actuales

En `_mart__models.yml` tiene:

- combinacion unica de `venta_key`, `id_venta`, `unidad_key`
- `total_vencido`: `not_null`
- `numero_pagos_vencidos`: `not_null`

### Problemas actuales

- Usa `v.equipo` desde `fct_ventas`, aunque `fct_pagos_vencidos` tambien trae
  `equipo`. Si una venta de cartera no existe en `fct_ventas`, `equipo` quedara
  nulo.

### Recomendacion

Mantenerlo como mart de soporte para analisis de morosidad. No debe bloquear el
reemplazo de `tc_gl_Dash_Cron`.

## `mart_ingresos_por_periodo`

### Objetivo

Analizar ingresos agregados por periodo y atributos financieros:

- anio;
- mes;
- desarrollo;
- etapa;
- banco;
- forma de pago;
- concepto;
- estatus del ingreso.

### Modelos que consume

- `fct_ingresos`
- `dim_unidades`
- `dim_date`

### Grano

Una fila por combinacion de:

- `year`
- `month`
- `month_name`
- `desarrollo_largo`
- `desarrollo_corto`
- `etapa`
- `banco`
- `forma_pago`
- `concepto`
- `status_ingreso`

### Columnas importantes

- `year`
- `month`
- `month_name`
- `desarrollo_largo`
- `desarrollo_corto`
- `etapa`
- `banco`
- `forma_pago`
- `concepto`
- `status_ingreso`
- `numero_movimientos`
- `total_ingresado`

### Interpretacion

Este mart no depende de `fct_ventas`. Eso es consistente con una decision
importante del modelo: no todos los ingresos tienen necesariamente una venta
confiable en `fct_ventas`.

Por eso puede incluir ingresos que no conectan con una venta del modelo
principal, siempre que existan en `fct_ingresos`.

Como `status_ingreso` forma parte del grano, un mismo folio/referencia puede
aparecer separado entre `Activo` y `Cancelado`.

### Tests actuales

En `_mart__models.yml` tiene:

- combinacion unica de las columnas de agrupacion:
  `year`, `month`, `month_name`, `desarrollo_largo`, `desarrollo_corto`,
  `etapa`, `banco`, `forma_pago`, `concepto`, `status_ingreso`
- `numero_movimientos`: `not_null`
- `total_ingresado`: `not_null`

### Problemas o riesgos

- Si `fecha_ingreso` no matchea con `dim_date`, `year`, `month` y `month_name`
  quedaran nulos.
- Si `unidad_key` no matchea con `dim_unidades`, los campos de desarrollo
  quedaran nulos.
- `total_ingresado` suma los movimientos existentes en cada grupo de
  `status_ingreso`; no excluye cancelados por defecto.
- Podria enriquecerse con `grupo` desde `dim_unidades`.

### Recomendacion

Mantenerlo como mart de soporte financiero. Si empieza a consumirse de forma
intensiva, podria agregarse una llave surrogate legible para facilitar joins
externos.

## `mart_facturacion`

### Objetivo

Exponer facturas emitidas con atributos de fecha:

- cuando se timbraron;
- quien emitio;
- quien recibio;
- tipo de factura;
- tipo de pago;
- total facturado.

### Modelos que consume

- `fct_facturas`
- `dim_date`

### Grano

Una fila por factura/UUID.

### Columnas importantes

- `factura_key`
- `uuid`
- `uuid_relacionado`
- `folio_general`
- `folio_seguimiento`
- `rfc_emisor`
- `rfc_receptor`
- `razon_social_emisor`
- `razon_social_receptor`
- `fecha_timbrado`
- `anio_timbrado`
- `mes_timbrado`
- `nombre_mes_timbrado`
- `tipo_factura`
- `tipo_pago`
- `total_factura`

### Interpretacion

Este mart esta correctamente aislado. No se relaciona con ventas porque todavia
no existe una llave confiable entre `fct_facturas` y `fct_ventas`.

No debe usarse para analisis directo de ventas o cobranza.

Esta etiquetado como `descontinuado` en YAML, pero la decision actual es
conservarlo como soporte fiscal independiente.

### Tests actuales

En `_mart__models.yml` tiene:

- `factura_key`: `unique`, `not_null`
- `uuid`: `unique`, `not_null`
- `total_factura`: `not_null`

### Problemas o riesgos

- En `fct_facturas`, `factura_key` tiene una logica fallback cuando falta
  `uuid`, pero los tests actuales obligan `uuid` `not_null`. Si se conserva UUID
  obligatorio, el fallback queda como proteccion teorica y casi no se usaria.
- Ya tiene descripcion en `_mart__models.yml` aclarando que es fiscal,
  independiente y sin llave confiable hacia ventas.

## `mart_dash_cron_reconstruido`

### Objetivo

Intentar reconstruir el dashboard operativo desde modelos atomicos del
warehouse, en lugar de partir del reporte operativo ya calculado.

El archivo vive en `models/marts/experimental/` y el YAML lo etiqueta como
`experimental` y `reconciliacion`.

### Modelos que consume

- `fct_ventas`
- `dim_unidades`
- `bridge_venta_persona`
- `dim_personas`
- `fct_ingresos`
- `fct_pagos_vencidos`
- `fct_cronograma_unidades`

### Grano

Una fila por venta.

### Logica

1. Parte de `fct_ventas`.
2. Agrega personas por venta.
3. Agrega ingresos por venta desde `fct_ingresos`.
4. Agrega cartera vencida por venta desde `fct_pagos_vencidos`.
5. Agrega cronograma por unidad desde `fct_cronograma_unidades`.
6. Calcula metricas:
   - `total_cobrado_bruto`
   - `total_cobrado`: solo ingresos con `status_ingreso = 'Activo'`
   - `total_vencido`
   - `saldo_total_estimado`
   - `porcentaje_cobrado`
   - `estatus_cobranza_estimado`

### Interpretacion

Este modelo no es equivalente a `mart_dash_cron`.

`mart_dash_cron` conserva metricas del dashboard operativo original.
`mart_dash_cron_reconstruido` recalcula esas metricas desde facts. Por eso puede
dar resultados distintos aunque ambos parezcan hablar del mismo dashboard.

### Tests actuales

En `_mart__models.yml` tiene:

- `venta_key`: `unique`, `not_null`
- `id_venta`: `unique`, `not_null`
- `unidad_key`: `not_null`
- `precio_venta`: `not_null`
- `total_cobrado`: `not_null`
- `total_vencido`: `not_null`
- `saldo_total_estimado`: `not_null`

### Problemas o riesgos

- Usa `max(estatus_cronograma_actual)` sobre texto. Eso elige por orden
  lexicografico, no necesariamente por prioridad del proceso.
- Si `fct_cronograma_unidades` ya tiene una fila por `unidad_key`, no deberia
  hacer falta reagruparlo.
- El filtro `where u.desarrollo_corto not in (...)` elimina ventas donde la
  unidad no haya matcheado y `u.desarrollo_corto` sea `null`.
- `porcentaje_cobrado` queda alineado con `mart_cobranza_por_venta`: escala
  0 a 100 con 2 decimales.
- Puede dejar fuera ingresos o cartera vencida que no conecten con ventas de
  `fct_ventas`.
- Conserva `total_cobrado_bruto` para reconciliacion, pero `total_cobrado`,
  `saldo_total_estimado` y `porcentaje_cobrado` usan solo ingresos activos.

### Recomendacion

Mantenerlo como experimental. Es valioso para una futura reconciliacion, pero no
debe reemplazar todavia a `mart_dash_cron`.

## Tests actuales de marts

La seleccion actual `path:models/marts` contiene 7 modelos y 40 tests.

Modelos con tests declarados:

- `mart_comercial_ventas`
- `mart_cobranza_por_venta`
- `mart_dash_cron`
- `mart_cartera_vencida_por_venta`
- `mart_ingresos_por_periodo`
- `mart_facturacion`
- `mart_dash_cron_reconstruido`

Todos los marts actuales tienen al menos tests basicos declarados.

## Verificacion realizada

Durante la revision se ejecuto:

```bash
dbt parse
dbt compile --select path:models/marts
dbt ls --select path:models/marts --output name
dbt ls --select path:models/marts --resource-type test --output name
```

Resultados:

- `dbt parse` termino correctamente.
- `dbt compile --select path:models/marts` termino correctamente con red
  habilitada.
- dbt detecto 7 modelos en `models/marts`.
- dbt detecto 40 tests asociados a la seleccion de marts.

Importante: `dbt compile` valida grafo, Jinja y compilacion, pero no ejecuta los
modelos contra Databricks. Para validar datos reales, duplicados y errores SQL en
ejecucion, hace falta correr `dbt build`.

## Problemas prioritarios a corregir

1. Mantener `mart_dash_cron_reconstruido` como experimental y no usarlo como
   reporte oficial.
2. Decidir si `uuid` en facturacion es obligatorio o si se permitiran facturas
   sin UUID usando el fallback de `factura_key`.
3. Revisar si `mart_cartera_vencida_por_venta` debe traer `equipo` desde
   `fct_pagos_vencidos` como fallback cuando no matchea con `fct_ventas`.

## Lectura recomendada

Para trabajar con esta capa sin confundirse:

1. Usar `mart_dash_cron` para reemplazar el dashboard operativo legacy.
2. Usar `mart_comercial_ventas` para preguntas comerciales por venta.
3. Usar `mart_cobranza_por_venta` para venta vs ingresos cobrados.
4. Usar `mart_cartera_vencida_por_venta` para morosidad.
5. Usar `mart_ingresos_por_periodo` para ingresos agregados por tiempo y
   atributos financieros.
6. Usar `mart_facturacion` solo para facturacion general.
7. Usar `mart_dash_cron_reconstruido` solo como laboratorio de reconciliacion o
   version futura.
