## Contexto de modelos en `models/marts`

El proyecto tiene varios marts, pero actualmente hay que distinguir entre modelos oficiales, modelos de soporte y modelos experimentales.

El objetivo principal de fase 2 es reemplazar el reporte legacy `tc_gl_Dash_Cron`, que originalmente se construía con:

```sql
rp_dashboard_operaciones
LEFT JOIN rp_cronograma_unidades
LEFT JOIN tc_gl_Grupos
```

El reemplazo principal en dbt debe ser:

```text
mart_dash_cron
```

Este modelo debe considerarse el mart oficial de fase 2 porque replica la lógica funcional del reporte legacy:

```text
stg_reports__dashboard_operaciones
+ fct_cronograma_unidades
+ dim_unidades.grupo
```

`mart_dash_cron` no intenta recalcular métricas desde facts atómicas. Su objetivo es reemplazar el reporte original con staging limpio, cronograma modelado y grupo proveniente de `dim_unidades`.

---

## Modelos actuales

### `mart_comercial_ventas`

Estado: correcto.

Este mart tiene una fila por venta. Consume:

```text
fct_ventas
dim_unidades
bridge_venta_persona
dim_personas
```

Su objetivo es mostrar información comercial de la venta, unidad y cliente principal. También calcula copropietarios usando `bridge_venta_persona`, evitando duplicar ventas por personas.

Este modelo se considera sano y puede mantenerse como mart oficial.

---

### `mart_cobranza_por_venta`

Estado: correcto, pero todavía es fase 1.

Consume:

```text
fct_ventas
dim_unidades
fct_ingresos
```

Calcula:

```text
total_ingresado
numero_movimientos_ingreso
fecha_primer_ingreso
fecha_ultimo_ingreso
saldo_estimado
porcentaje_cobrado
```

Actualmente no incorpora cartera vencida. Eso no es un error, pero debe entenderse como una versión inicial. En una mejora posterior podría integrarse información desde `fct_pagos_vencidos` o `fct_cartera_vencida_detallado`, dependiendo del nombre final usado en warehouse.

---

### `mart_dash_cron`

Estado: mart principal de fase 2.

Consume:

```text
stg_reports__dashboard_operaciones
fct_cronograma_unidades
dim_unidades
```

Su objetivo es reemplazar directamente `tc_gl_Dash_Cron`.

La lógica actual es:

```text
dashboard.*
+ fechas/estatus de cronograma
+ grupo desde dim_unidades
```

Filtra:

```text
desarrollo_corto not in ('UH MAY', 'DEMO 2024')
```

Este mart debe considerarse el entregable principal para recrear el reporte operativo usado por negocio.

Importante: `mart_dash_cron` parte de `stg_reports__dashboard_operaciones`, por lo tanto conserva métricas del reporte original como `total_cobrado`, `saldo_total`, `total_vencido`, etc. Eso es intencional porque su propósito es reemplazo directo, no reconstrucción analítica.

---

### `mart_dash_cron_reconstruido`

Estado: experimental / futuro.

Este modelo intenta reconstruir el dashboard operativo desde warehouse:

```text
fct_ventas
dim_unidades
bridge_venta_persona
dim_personas
fct_ingresos
fct_pagos_vencidos o fct_cartera_vencida_detallado
fct_cronograma_unidades
```

No debe considerarse reemplazo directo de `tc_gl_Dash_Cron`, porque recalcula métricas como:

```text
total_cobrado
total_vencido
saldo_total_estimado
porcentaje_cobrado
```

desde facts del warehouse.

Este modelo puede diferir del reporte original por razones válidas:

* `total_cobrado` se calcula desde `fct_ingresos`;
* `total_vencido` se calcula desde cartera vencida;
* `saldo_total_estimado` se calcula como `precio_venta - total_cobrado`;
* solo incluye ventas presentes en `fct_ventas`;
* ingresos o cartera sin venta relacionada quedan fuera.

Problemas técnicos a revisar:

* El modelo usa `ref('fct_pagos_vencidos')`. Validar si ese es el nombre correcto. En el plan previo se hablaba de `fct_cartera_vencida_detallado`.
* El modelo selecciona `v.precio_m2_venta`, pero en conversaciones previas el campo esperado era `precio_m2_vendido`. Validar nombre real en `fct_ventas`.
* `max(estatus_cronograma_actual)` no necesariamente representa el estatus correcto, porque `max` sobre texto es lexicográfico. Si `fct_cronograma_unidades` ya es única por `unidad_key`, no debería agregarse con `max`.
* El filtro `where u.desarrollo_corto not in (...)` elimina también registros donde `u.desarrollo_corto` sea null. Si se quiere conservar ventas sin unidad relacionada, usar lógica más explícita.

Recomendación: mantener este modelo como experimental o renombrarlo como versión futura. No usarlo como mart oficial de fase 2 todavía.

---

### `mart_cartera_vencida_por_venta`

Estado: útil, pero requiere correcciones.

Objetivo esperado:

```text
1 fila por venta con cartera vencida agregada
```

Calcula:

```text
total_vencido
numero_pagos_vencidos
dias_atraso_maximo
dias_atraso_promedio
fecha_primer_pago_vencido
fecha_ultimo_pago_vencido
```

Problemas técnicos actuales:

* Tiene error de sintaxis al inicio: `with pagos (` debe ser `with pagos as (`.
* Usa `ref('fct_pagos_vencidos')`. Validar si el nombre real de la fact en warehouse es ese o `fct_cartera_vencida_detallado`.
* Selecciona campos como `cliente`, `email`, `telefono_celular`, pero hay que confirmar si esos nombres existen en la fact. En el diseño previo se hablaba de `cliente_texto`, `correo_electronico`, `telefono_celular`, `telefono_local`.
* No está documentado ni testeado en `_mart__models.yml`.

Recomendación: corregirlo y dejarlo como mart de soporte para análisis de cartera, no como prerequisito del reemplazo `tc_gl_Dash_Cron`.

---

### `mart_facturacion`

Estado: técnicamente correcto, pero aislado.

Consume:

```text
fct_facturas
dim_date
```

Agrega atributos temporales de `fecha_timbrado`.

No está mal, pero actualmente no existe una llave confiable para relacionar facturas con ventas. Por eso este mart no debe usarse para análisis de ventas, cobranza o dashboard operativo todavía.

Su utilidad actual es limitada a análisis fiscal/facturación general:

```text
facturas por fecha
facturas por receptor
facturas por tipo_factura
total_factura
```

Recomendación: mantenerlo como mart secundario o de baja prioridad. Documentar claramente que no conecta con ventas por ahora.

---

### `mart_ingresos_por_periodo`

Estado: útil pero genérico e incompleto en documentación/tests.

Consume:

```text
fct_ingresos
dim_unidades
dim_date
```

Agrega ingresos por:

```text
year
month
month_name
desarrollo_largo
desarrollo_corto
etapa
banco
forma_pago
concepto
status_ingreso
```

Sirve para analizar entradas de dinero por periodo, banco, forma de pago o concepto.

Consideraciones:

* No está documentado/testeado en `_mart__models.yml`.
* Podría enriquecerse con `grupo` desde `dim_unidades`.
* No depende de `fct_ventas`, por lo que puede incluir ingresos sin venta relacionada. Eso puede ser correcto, pero debe documentarse.
* No tiene surrogate key ni test de unicidad por combinación de columnas.

Recomendación: mantenerlo solo si se quiere un reporte de ingresos por periodo. No es central para reemplazar `tc_gl_Dash_Cron`.

---

## Estado del YAML `_mart__models.yml`

Actualmente el YAML documenta/tests para:

```text
mart_comercial_ventas
mart_cobranza_por_venta
mart_dash_cron
mart_facturacion
mart_dash_cron_reconstruido
```

Faltan entradas para:

```text
mart_cartera_vencida_por_venta
mart_ingresos_por_periodo
```

También sería recomendable mejorar descripciones de:

* `mart_facturacion`;
* `mart_ingresos_por_periodo`;
* `mart_cartera_vencida_por_venta`.

---

## Recomendación de organización

Separar mentalmente los marts en tres grupos:

### Oficiales actuales

```text
mart_comercial_ventas
mart_cobranza_por_venta
mart_dash_cron
```

### Soporte / análisis secundario

```text
mart_cartera_vencida_por_venta
mart_ingresos_por_periodo
mart_facturacion
```

### Experimental / futuro

```text
mart_dash_cron_reconstruido
```

El mart principal de fase 2 debe ser `mart_dash_cron`.

`mart_dash_cron_reconstruido` no debe reemplazar todavía a `mart_dash_cron`; debe tratarse como una futura versión analítica que reconstruye métricas desde facts del warehouse.