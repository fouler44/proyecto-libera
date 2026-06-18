Sí, muy buena idea. Esto conviene documentarlo como una sección tipo **“Pendientes / Consideraciones futuras”** o **“Decisiones abiertas”**. Así queda claro que algunas cosas no son errores, sino decisiones conscientes para no forzar relaciones.

# Cosas a tener en cuenta para el futuro

## 1. Relación entre `fct_cartera_vencida_detallado` y `fct_ventas`

Por ahora, `fct_cartera_vencida_detallado` puede generar `venta_key` usando `id_venta`, pero **todavía no se debe forzar una relación obligatoria contra `fct_ventas`**.

Esto es parecido a lo que pasa con `fct_ingresos`.

### Por qué importa

Puede haber registros de cartera vencida cuyo `id_venta` no exista en `fct_ventas`, especialmente si vienen de ventas canceladas, ventas históricas no incluidas en `rp_vista_ventas`, o diferencias entre reportes del CRM.

### Pendiente futuro

Validar cuántos registros de cartera vencida no tienen venta relacionada:

```sql
select
    count(*) as total_registros,
    count(v.venta_key) as registros_con_venta,
    count(*) - count(v.venta_key) as registros_sin_venta
from {{ ref('fct_cartera_vencida_detallado') }} c
left join {{ ref('fct_ventas') }} v
    on c.venta_key = v.venta_key
```

Si la cobertura es alta y estable, se podría considerar agregar un test de relación. Si no, se mantiene como fact independiente.

---

## 2. Relación entre `fct_ingresos` y `fct_ventas`

Ya existe `venta_key` en `fct_ingresos`, pero no se está forzando una relación obligatoria contra `fct_ventas`.

### Por qué importa

Hay ingresos cuyo `id_venta` no aparece en la vista principal de ventas. Si se hiciera un `inner join` contra `fct_ventas`, esos ingresos se perderían.

### Pendiente futuro

Clasificar los ingresos sin venta relacionada:

* ¿son ventas canceladas?
* ¿son ventas históricas?
* ¿son errores de captura?
* ¿pertenecen a otro proceso que no está en `rp_vista_ventas`?

Esto podría derivar en un mart de auditoría:

```text
mart_ingresos_sin_venta
```

---

## 3. Relación entre `fct_facturas` y ventas

`fct_facturas` sigue independiente porque no contiene `id_venta`.

### Por qué importa

No conviene unir facturas con ventas usando campos débiles si no hay una llave confiable. Una relación mal hecha podría asignar facturas a ventas incorrectas.

### Pendiente futuro

Investigar si alguno de estos campos puede servir para relacionar facturas con otros procesos:

* `folio_seguimiento`
* `folio_general`
* `rfc_receptor`
* `fecha_timbrado`
* `total_factura`
* algún folio compartido con ingresos

Hasta no validarlo, `fct_facturas` debe seguir independiente.

---

## 4. Ventas canceladas

Las tablas canceladas todavía no forman parte del modelo principal.

### Por qué importa

Las canceladas pueden explicar muchos registros que hoy no conectan bien con ventas activas, por ejemplo:

* ingresos sin venta relacionada;
* cartera vencida sin venta relacionada;
* personas asociadas a ventas que no existen en `fct_ventas`.

### Pendiente futuro

Modelar canceladas como un subdominio separado:

```text
fct_ventas_canceladas
bridge_venta_persona_cancelada
fct_ingresos_cancelados
```

Después de eso, se podría evaluar si conviene crear una vista consolidada:

```text
mart_ventas_consolidado
```

con ventas activas y canceladas.

---

## 5. Validar si `rp_vista_ventas` representa solo ventas vigentes

Hasta ahora `rp_vista_ventas` se usa como base de `fct_ventas`, porque `id_venta` es único y representa bien el evento de venta.

### Por qué importa

Si `rp_vista_ventas` solo contiene ventas actuales/vigentes, entonces no representa todo el historial comercial.

### Pendiente futuro

Confirmar con negocio o con datos si incluye:

* ventas activas;
* ventas canceladas;
* ventas liquidadas;
* ventas escrituradas;
* ventas históricas.

Esto afecta la interpretación de `fct_ventas`.

---

## 6. `dim_unidades` representa unidades observadas, no inventario completo

`dim_unidades` se construye desde ventas y se enriquece con atributos adicionales.

### Por qué importa

Eso significa que, por ahora, `dim_unidades` contiene unidades observadas en los reportes usados, no necesariamente todo el inventario de unidades de la empresa.

### Pendiente futuro

Si aparece una tabla maestra de unidades/inventario, habría que evaluar si debe reemplazar o enriquecer `dim_unidades`.

---

## 7. Grupos de desarrollo desde seed

La seed `grupos_desarrollos` se usó para enriquecer `dim_unidades`.

### Por qué importa

Es una tabla manual, útil y controlada, pero debe mantenerse actualizada si aparecen nuevos desarrollos o cambios de clasificación.

### Pendiente futuro

Agregar validaciones para detectar unidades sin grupo:

```sql
select
    desarrollo_largo,
    desarrollo_corto,
    unidad
from {{ ref('dim_unidades') }}
where grupo is null
```

También conviene revisar si la combinación:

```text
desarrollo_largo + desarrollo_corto
```

sigue siendo única en la seed.

---

## 8. `precio_lista` y `precio_m2_lista`

Todavía hay que decidir si estos campos deben vivir en `dim_unidades` o en un modelo operativo/mart.

### Por qué importa

Si son atributos estables de la unidad, podrían ir en `dim_unidades`.

Pero si cambian con el tiempo o dependen del momento de venta, deberían vivir en una fact o mart, no en una dimensión.

### Pendiente futuro

Validar si para una misma unidad existen varios valores:

```sql
select
    desarrollo_largo,
    unidad,
    count(distinct precio_lista) as distintos_precio_lista,
    count(distinct precio_m2_lista) as distintos_precio_m2_lista
from {{ ref('stg_reports__dashboard_operaciones') }}
group by 1, 2
having count(distinct precio_lista) > 1
    or count(distinct precio_m2_lista) > 1
```

---

## 9. `total_cobrado`, `saldo_total` y `total_vencido`

Estos campos existen en `rp_dashboard_operaciones`, pero parecen métricas derivadas del reporte original.

### Por qué importa

No conviene copiarlos directamente como “verdad final” si ya puedes calcularlos desde facts más atómicas:

* `total_cobrado` desde `fct_ingresos`;
* `total_vencido` desde `fct_cartera_vencida_detallado`;
* `saldo_total` desde venta menos ingresos, o con reglas de negocio específicas.

### Pendiente futuro

Crear un modelo de reconciliación:

```text
mart_dashboard_operaciones_reconciliacion
```

Comparando:

| Métrica       | Origen operativo                         | Cálculo dbt                                        |
| ------------- | ---------------------------------------- | -------------------------------------------------- |
| Total cobrado | `rp_dashboard_operaciones.TOTAL_COBRADO` | `sum(fct_ingresos.monto_pagado)`                   |
| Total vencido | `rp_dashboard_operaciones.TOTALVENCIDO`  | `sum(fct_cartera_vencida_detallado.monto_vencido)` |
| Saldo total   | `rp_dashboard_operaciones.SALDOTOTAL`    | cálculo propio en mart                             |

---

## 10. Cronograma sin `id_venta`

`rp_cronograma_unidades` no tiene `id_venta`, por lo que no se puede relacionar directamente con `fct_ventas`.

### Por qué importa

La relación debe hacerse por unidad/desarrollo, pero esto puede ser menos fuerte que una llave de venta.

### Pendiente futuro

Validar que la relación por:

```text
desarrollo_largo + unidad
```

o por `unidad_key` sea confiable.

También conviene documentar que:

```text
fct_cronograma_unidades
```

representará avance operativo de la unidad, no necesariamente de la venta.

---

## 11. Posible inversión de columnas en cronograma

El query original une:

```sql
DASH.UNIDAD = CRON.UNIDAD
AND DASH.DESARROLLO_LARGO = CRON.DESARROLLO_CORTO
```

Esto sugiere que en `rp_cronograma_unidades` los campos de desarrollo pueden estar invertidos o nombrados de forma distinta.

### Pendiente futuro

Mantener un modelo intermedio:

```text
int_cronograma_unidades_normalizado
```

para corregir esa lógica una sola vez y no repetir joins confusos en marts.

---

## 12. Campaña, vendedor externo y comisiones

Campos como:

```text
campania
vendedor_externo
comision_asesor
comision_libera
```

todavía deben tratarse con cuidado.

### Por qué importa

No está 100% claro si son atributos de la venta, del cronograma, del asesor, o del reporte operativo.

### Pendiente futuro

Mantenerlos inicialmente en `mart_dashboard_operaciones` y no moverlos a dimensiones o facts centrales hasta validar su significado y estabilidad.

---

## 13. Relación entre personas y cartera vencida

`fct_cartera_vencida_detallado` trae datos de contacto del cliente como texto:

```text
cliente
correo_electronico
telefono_celular
telefono_local
```

### Por qué importa

No necesariamente se debe conectar directo con `dim_personas`, porque puede haber diferencias de nombres, emails o teléfonos.

### Pendiente futuro

Evaluar si se puede relacionar cartera con personas usando:

* `id_venta` → `bridge_venta_persona`;
* o alguna llave natural de persona.

Por ahora, lo más seguro es mantener esos datos como texto informativo en la fact o en el mart.

---

## 14. Métricas de cartera acumulada

Mencionaste que existe una tabla acumulada de cartera vencida.

### Por qué importa

Si esa tabla es una agregación, no conviene usarla como fuente principal si ya existe el detalle.

### Pendiente futuro

Reconstruir el acumulado desde:

```text
fct_cartera_vencida_detallado
```

para crear marts como:

```text
mart_cartera_vencida_por_venta
mart_cartera_vencida_acumulado
```

Así la lógica queda transparente y versionada en dbt.

---

## 15. Tests que todavía no deben ser obligatorios

Por ahora, estos tests **no deberían ser obligatorios** hasta validar cobertura:

```text
fct_ingresos.venta_key → fct_ventas.venta_key
fct_cartera_vencida_detallado.venta_key → fct_ventas.venta_key
fct_facturas → fct_ventas
fct_cronograma_unidades → fct_ventas
```

En cambio, pueden existir como auditorías o queries exploratorias.

---

# Resumen corto

Las principales cosas a recordar para el futuro son:

| Tema                | Estado actual                 | Futuro                               |
| ------------------- | ----------------------------- | ------------------------------------ |
| Cartera vs ventas   | Relación no forzada           | Validar cobertura por `id_venta`     |
| Ingresos vs ventas  | Relación no forzada           | Clasificar ingresos sin venta        |
| Facturas vs ventas  | Sin relación confiable        | Investigar folios/RFC/montos         |
| Canceladas          | Fuera del modelo principal    | Modelarlas como subdominio           |
| Cronograma          | Sin `id_venta`                | Relacionar por unidad con cuidado    |
| Grupos              | Seed manual                   | Mantener actualizada y validar nulos |
| Métricas operativas | Recalcular en marts           | Reconciliar contra origen            |
| Cartera acumulada   | No usar como fuente principal | Reconstruir desde detalle            |

La idea general es:

> Todo lo que no tenga una relación confiable todavía debe quedarse como relación opcional, auditoría o mart independiente. Mejor un modelo honesto con relaciones claras que uno aparentemente completo pero con joins débiles.
