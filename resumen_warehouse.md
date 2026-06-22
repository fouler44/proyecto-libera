# Resumen de la capa warehouse

Este documento resume el estado actual de `models/warehouse/` en el proyecto dbt
de Libera. Su objetivo es explicar que hay en esta capa, que representa cada
modelo, cual es su grano, que pruebas existen y que decisiones siguen abiertas.

La revision se hizo contra el SQL y YAML actuales del repositorio, usando los
documentos de contexto solo como apoyo.

## Rol de warehouse

`warehouse` es la capa donde los reportes limpios de `staging` dejan de verse
como tablas del CRM y se organizan como entidades analiticas:

- modelos intermedios;
- dimensiones;
- facts;
- tabla puente.

En `dbt_project.yml`, warehouse esta configurado asi:

```yaml
warehouse:
  +schema: warehouse
  +materialized: view

  int:
    +materialized: ephemeral
```

Esto significa:

- los modelos `warehouse/int` son `ephemeral`;
- los modelos de `dimensions` y `facts` son vistas por defecto;
- `dim_date` se sobreescribe explicitamente como tabla con `config(materialized='table')`.

## Estructura actual

```text
models/warehouse/
  int/
  dimensions/
  facts/
  _warehouse__models.yml
```

Hay 12 modelos:

- 3 intermedios;
- 4 dimensiones/puente;
- 5 facts.

## Resumen rapido

| Modelo | Tipo | Grano | Uso principal |
| --- | --- | --- | --- |
| `int_unidades_atributos` | Intermedio | 1 fila por `desarrollo_largo + unidad` | Preparar atributos de unidad desde clientes |
| `int_ventas_atributos` | Intermedio | 1 fila por `id_venta` | Preparar atributos extra de venta desde clientes |
| `int_venta_persona` | Intermedio | Persona asociada a venta | Unificar clientes y copropietarios |
| `dim_unidades` | Dimension | 1 fila por `desarrollo_largo + unidad` | Describir unidades observadas |
| `dim_personas` | Dimension | 1 fila por `persona_natural_key` | Deduplicar personas |
| `dim_date` | Dimension | 1 fila por dia | Calendario analitico |
| `bridge_venta_persona` | Puente | 1 fila por venta/persona/rol | Resolver ventas con varias personas |
| `fct_ventas` | Fact | 1 fila por `id_venta` | Evento principal de venta |
| `fct_ingresos` | Fact | 1 fila por movimiento de ingreso | Movimientos cobrados/ingresados |
| `fct_facturas` | Fact | 1 fila por factura/UUID | Facturacion emitida |
| `fct_pagos_vencidos` | Fact | 1 fila por pago vencido | Cartera vencida detallada |
| `fct_cronograma_unidades` | Fact snapshot | 1 fila por unidad | Avance operativo de unidad |

## Lineage mental

```text
staging reports
  -> warehouse/int
  -> warehouse/dimensions + warehouse/facts
  -> marts
```

Puntos clave:

- `fct_ventas` es la fact central de ventas.
- `dim_unidades` describe unidades observadas, no inventario completo.
- `dim_personas` deduplica personas usando una llave natural.
- `bridge_venta_persona` evita poner una sola persona directamente en ventas.
- `fct_ingresos`, `fct_pagos_vencidos`, `fct_facturas` y
  `fct_cronograma_unidades` no fuerzan relacion obligatoria contra ventas.

## Verificacion de riesgos 2026-06-22

Riesgo 3, uso de `max(...)` para deduplicar: mitigado con auditorias
singulares iniciales. Existen tests para detectar conflictos en:

- unidades con mas de una etapa o desarrollo corto;
- ventas con multiples atributos comerciales, incluido `status_escritura`;
- misma `persona_natural_key` con multiples RFC/CURP/email;
- cronograma con multiples fechas para la misma unidad;
- asesores distintos por venta;
- unidades sin grupo proveniente del seed manual;
- ventas sin exactamente un cliente principal.

## Modelos intermedios

Los modelos en `warehouse/int` son `ephemeral`. No se crean como tablas fisicas;
se incrustan dentro de los modelos que los usan.

## `int_unidades_atributos`

### Objetivo

Recuperar atributos de unidad desde `stg_reports__clientes`, especialmente
`desarrollo_corto` y `etapa`, para enriquecer `dim_unidades`.

### Fuente

- `stg_reports__clientes`

### Grano

Una fila por:

- `desarrollo_largo`
- `unidad`

### Logica

1. Toma filas de clientes con `desarrollo_largo` y `unidad` no nulos.
2. Agrupa por `desarrollo_largo + unidad`.
3. Usa `max(desarrollo_corto)` y `max(etapa)` para deduplicar.

### Uso downstream

- `dim_unidades`

### Tests actuales

No tiene tests ni documentacion propia en `_warehouse__models.yml`.

### Riesgos o pendientes

- El uso de `max(...)` puede ocultar conflictos si una misma unidad tiene varias
  etapas o desarrollos cortos en raw.
- El riesgo de normalizacion de `unidad` queda mitigado porque staging ya usa
  `trim(upper(UNIDAD))` de forma consistente. Aun asi, conviene vigilar cambios
  futuros en fuentes raw.

## `int_ventas_atributos`

### Objetivo

Recuperar atributos de venta desde `stg_reports__clientes` para enriquecer
`fct_ventas`.

### Fuente

- `stg_reports__clientes`

### Grano

Una fila por:

- `id_venta`

### Columnas principales

- datos de desarrollo y unidad;
- `asesor`;
- fechas contractuales;
- `plan`;
- `num_mensualidades`;
- `precio_venta`;
- `enganche`;
- `financiamiento`;
- `status_escritura`;
- `valor_escritura`;
- `dia_pago`;
- `entro_dv`.

### Logica

Agrupa por `id_venta` y usa `max(...)` para seleccionar un valor por atributo.

### Uso downstream

- `fct_ventas`

### Tests actuales

No tiene tests ni documentacion propia en `_warehouse__models.yml`.

### Riesgos o pendientes

- El uso de `max(...)` simplifica el grano, pero puede esconder diferencias entre
  filas del mismo `id_venta`.
- Si una venta tiene datos conflictivos en clientes, el modelo no los evidencia
  por si solo.
- Ya existe el test singular `distintos_asesores` para detectar ventas con mas
  de un asesor en `stg_reports__clientes`.

## `int_venta_persona`

### Objetivo

Unificar clientes principales y copropietarios en una sola estructura de
personas asociadas a ventas.

### Fuentes

- `stg_reports__clientes`
- `stg_reports__copropiedades`

### Grano

Una persona asociada a una venta con su rol.

Roles actuales:

- `cliente_principal`
- `copropietario`

### Logica

1. Hace `union all` entre clientes y copropietarios.
2. Calcula `nombre_completo`.
3. Construye `persona_natural_key` con esta jerarquia:
   - `curp`;
   - `rfc`;
   - `email` en minusculas;
   - `nombre + apellidos + telefono_celular`.
4. Excluye filas sin `id_venta`.
5. Devuelve `select distinct`.

### Uso downstream

- `dim_personas`
- `bridge_venta_persona`

### Tests actuales

No tiene tests ni documentacion propia en `_warehouse__models.yml`.

### Riesgos o pendientes

- Si la informacion de persona viene incompleta o inconsistente, la llave natural
  puede deduplicar de mas o de menos.
- No incorpora tablas de canceladas en esta fase.

## Dimensiones y puente

## `dim_unidades`

### Objetivo

Representar unidades observadas en ventas y enriquecerlas con atributos
adicionales.

### Fuentes

- `stg_reports__vista_ventas`
- `int_unidades_atributos`
- seed `grupos_desarrollos`

### Grano

Una fila por:

- `desarrollo_largo`
- `unidad`

### Columnas principales

- `unidad_key`
- `desarrollo_largo`
- `desarrollo_corto`
- `grupo`
- `etapa`
- `unidad`
- `modelo`

### Logica

1. Parte de unidades observadas en `stg_reports__vista_ventas`.
2. Enriquecce con `desarrollo_corto` y `etapa` desde `int_unidades_atributos`.
3. Genera `unidad_key` con `desarrollo_largo + unidad`.
4. Une el seed `grupos_desarrollos` para traer `grupo_2` como `grupo`.

### Tests actuales

- `unidad_key`: `not_null`, `unique`
- combinacion unica: `desarrollo_largo + unidad`

### Riesgos o pendientes

- No es inventario maestro completo; solo contiene unidades observadas en las
  fuentes usadas.
- El grupo viene de un seed manual. Si aparece un nuevo desarrollo, `grupo` puede
  quedar nulo.
- No tiene test `not_null` obligatorio sobre `grupo`, pero existe la auditoria
  warning `unidades_sin_grupo`.
- Depende de que `desarrollo_largo + unidad` siga normalizado de forma estable
  en staging.

## `dim_personas`

### Objetivo

Deduplicar personas entre clientes principales y copropietarios.

### Fuente

- `int_venta_persona`

### Grano

Una fila por:

- `persona_natural_key`

### Columnas principales

- `persona_key`
- `persona_natural_key`
- `nombre_completo`
- `nombre_cliente`
- `apellido_paterno`
- `apellido_materno`
- `edad`
- `rfc`
- `curp`
- `email`
- telefonos;
- sexo, estado civil, regimen;
- ocupacion, nacionalidad;
- domicilio e identificacion.

### Logica

1. Filtra personas con `persona_natural_key` no nulo.
2. Genera `persona_key` desde `persona_natural_key`.
3. Agrupa por `persona_natural_key`.
4. Usa `max(...)` para escoger atributos descriptivos.

### Tests actuales

- `persona_key`: `not_null`, `unique`
- `persona_natural_key`: `not_null`, `unique`

### Riesgos o pendientes

- `max(...)` puede esconder diferencias de atributos para la misma persona.
- La calidad de `persona_natural_key` depende de `curp`, `rfc`, `email` y
  telefono. Si estos datos estan mal capturados, la deduplicacion puede ser
  imperfecta.

## `dim_date`

### Objetivo

Crear una dimension calendario para analisis temporal.

### Grano

Una fila por dia.

### Rango actual

Segun el SQL actual:

```text
2018-01-01 a 2030-12-31
```

### Columnas principales

- `date_day`
- `year`
- `quarter`
- `month`
- `month_name`
- `day_of_month`
- `day_of_week`
- `day_name`
- `week_of_year`
- `is_weekend`

### Tests actuales

- `date_day`: `not_null`, `unique`

### Riesgos o pendientes

- El README anterior mencionaba un rango desde 2020, pero el SQL actual empieza
  en 2018. El documento vigente debe considerar el SQL como fuente de verdad.
- Si aparecen datos fuera de 2030, habra que extender la dimension.

## `bridge_venta_persona`

### Objetivo

Resolver la relacion muchos-a-muchos entre ventas y personas.

Una venta puede tener:

- un cliente principal;
- cero o varios copropietarios.

### Fuentes

- `int_venta_persona`
- `fct_ventas`

### Grano

Una fila por:

- `venta_key`
- `persona_key`
- `rol_persona_en_venta`

### Logica

1. Toma personas de `int_venta_persona`.
2. Hace `inner join` con `fct_ventas` por `id_venta`.
3. Genera `persona_key` desde `persona_natural_key`.
4. Conserva solo filas con `id_venta` y `persona_natural_key` no nulos.

### Tests actuales

- combinacion unica: `venta_key + persona_key + rol_persona_en_venta`
- `venta_key`: `not_null` y relationship hacia `fct_ventas.venta_key`
- `persona_key`: `not_null` y relationship hacia `dim_personas.persona_key`

### Riesgos o pendientes

- Al usar `inner join` contra `fct_ventas`, excluye personas de ventas que no
  existen en la fact principal.
- No incluye ventas canceladas.
- Existe la auditoria warning `ventas_con_mas_de_un_cliente_principal` para
  detectar ventas con cero o multiples clientes principales.

## Facts

## `fct_ventas`

### Objetivo

Representar el evento principal de venta.

### Fuentes

- `stg_reports__vista_ventas`
- `int_ventas_atributos`
- `stg_reports__dashboard_operaciones`

### Grano

Una fila por:

- `id_venta`

### Columnas principales

- `venta_key`
- `id_venta`
- `unidad_key`
- `status_venta`
- `status_unidad`
- `plan`
- `equipo`
- `asesor`
- `status_escritura`
- fechas de enganche, contrato, escritura y registro;
- `precio_venta`
- `precio_m2_venta`
- `enganche`
- `financiamiento`
- `valor_escritura`
- `num_mensualidades`
- `dia_pago`
- `entro_dv`
- `requiere_factura`

### Logica

1. Parte de `stg_reports__vista_ventas`.
2. Genera `venta_key` con `id_venta`.
3. Genera `unidad_key` con `desarrollo_largo + unidad`.
4. Enriquece con atributos de `int_ventas_atributos`.
5. Enriquece con `precio_m2_venta` y `requiere_factura` desde
   `stg_reports__dashboard_operaciones`.

### Tests actuales

- `venta_key`: `not_null`, `unique`
- `id_venta`: `not_null`, `unique`
- `unidad_key`: `not_null` y relationship hacia `dim_unidades.unidad_key`
- expresion: `fecha_ultimo_pago_enganche >= fecha_primer_enganche`

### Riesgos o pendientes

- Depende de que `rp_vista_ventas` represente correctamente el universo de
  ventas que se quiere analizar.
- Las ventas canceladas no estan incluidas en esta fact.

## `fct_ingresos`

### Objetivo

Representar movimientos validos de ingreso.

### Fuente

- `stg_reports__flujo_ingresos`

### Grano

Una fila por movimiento de ingreso valido.

### Columnas principales

- `ingreso_key`
- `venta_key`
- `id_venta`
- `unidad_key`
- `folio`
- `status_ingreso`
- `status_venta`
- `fecha_ingreso`
- `fecha_amortizacion`
- `fecha_captura`
- `banco`
- `forma_pago`
- `concepto`
- `referencia_ingresos`
- `status_tercero`
- `nombre_tercero`
- `cliente`
- `monto_pagado`

### Logica

1. Filtra filas completamente vacias.
2. Excluye ingresos con `monto_pagado` nulo.
3. Genera `ingreso_key` con una combinacion de columnas porque `folio` no es
   unico. La llave incluye `id_venta`, `folio`, `status_ingreso`,
   `status_venta`, fechas, referencia, monto, concepto, forma de pago y banco.
4. Genera `venta_key` desde `id_venta`.
5. Genera `unidad_key` desde `desarrollo_largo + unidad`.

### Tests actuales

- `ingreso_key`: `not_null`, `unique`
- `monto_pagado`: `not_null`

### Riesgos o pendientes

- No se fuerza relacion con `fct_ventas`. Esto es intencional porque puede haber
  ingresos cuyo `id_venta` no exista en `fct_ventas`.
- `venta_key` por si sola no garantiza que exista una venta relacionada.
- Caso observado en build: el `id_venta` 2303 y folio 19311 existia dos veces
  con la misma referencia, monto y fechas, pero con `status_ingreso` `Activo` y
  `Cancelado`. Se conserva como dos movimientos operativos distintos al incluir
  estatus en `ingreso_key`.
- `fct_ingresos` conserva ingresos activos y cancelados. Los marts deben elegir
  explicitamente si usan metricas brutas o solo `status_ingreso = 'Activo'`.
  `mart_cobranza_por_venta` y el mart reconstruido experimental ya separan esas
  metricas.
- No hay test sobre `fecha_ingreso`, `id_venta` o `unidad_key`.

## `fct_facturas`

### Objetivo

Representar facturas emitidas.

### Fuente

- `stg_reports__facturas`

### Grano

Una fila por factura, normalmente identificada por `uuid`.

### Columnas principales

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
- `tipo_factura`
- `tipo_pago`
- `total_factura`

### Logica

1. Si `uuid` existe, genera `factura_key` desde `uuid`.
2. Si falta `uuid`, genera fallback con:
   - `folio_general`;
   - `folio_seguimiento`;
   - `fecha_timbrado`;
   - `total_factura`.

### Tests actuales

- `factura_key`: `not_null`, `unique`
- `total_factura`: `not_null`
- `uuid`: `not_null`, `unique`

### Riesgos o pendientes

- Hay una tension entre la logica fallback de `factura_key` y el test que exige
  `uuid not_null`. Si UUID es obligatorio, el fallback casi no se usaria; si no
  es obligatorio, el test debe cambiar.
- No existe relacion confiable con ventas, por eso se mantiene independiente.
- Se conserva como soporte fiscal aislado y no debe usarse para analisis directo
  de ventas o cobranza.

## `fct_pagos_vencidos`

### Objetivo

Representar el detalle de pagos vencidos, antes conocido en documentos viejos
como `fct_cartera_vencida_detallado`.

El nombre actual correcto es:

```text
fct_pagos_vencidos
```

### Fuente

- `stg_reports__cartera_vencida`

### Grano

Una fila por pago vencido, definido por:

- `id_venta`
- `no_pago`
- `fecha_pago`
- `tipo_pago`

### Columnas principales

- `pago_vencido_key`
- `venta_key`
- `unidad_key`
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

### Logica

1. Parte de `stg_reports__cartera_vencida`.
2. Filtra registros con `monto_vencido` nulo.
3. Genera `pago_vencido_key` con `id_venta + no_pago + fecha_pago + tipo_pago`.
4. Genera `venta_key` solo si `id_venta` no es nulo.
5. Genera `unidad_key` solo si `desarrollo_largo` y `unidad` no son nulos.

### Tests actuales

- `pago_vencido_key`: `not_null`, `unique`
- `no_pago`: `not_null`
- `fecha_pago`: `not_null`
- `monto_vencido`: `not_null`
- `dias_atraso`: `not_null`
- combinacion unica: `id_venta + no_pago + fecha_pago + tipo_pago`

### Riesgos o pendientes

- No se fuerza relacion con `fct_ventas`. Esto es intencional por ahora.
- Puede haber pagos vencidos de ventas historicas, canceladas o no presentes en
  `rp_vista_ventas`.
- Los datos de contacto del cliente se conservan como texto; no se conectan
  todavia con `dim_personas`.

## `fct_cronograma_unidades`

### Objetivo

Representar el avance operativo de una unidad a traves de hitos del cronograma.

### Fuente

- `stg_reports__cronograma_unidades`

### Grano

Una fila por:

- `desarrollo_largo`
- `unidad`

### Columnas principales

- `cronograma_unidad_key`
- `unidad_key`
- `desarrollo_largo`
- `desarrollo_corto`
- `unidad`
- `equipo`
- `asesor`
- `cliente`
- `campania`
- fechas de hitos;
- `estatus_cronograma_actual`
- dias entre hitos.

### Logica

1. Agrupa cronograma por `desarrollo_largo + unidad`.
2. Usa `max(...)` para fechas y atributos.
3. Genera `cronograma_unidad_key` y `unidad_key`.
4. Deriva `estatus_cronograma_actual` con prioridad:
   - `finalizado_liquidado`;
   - `finalizado`;
   - `aprobado_juridico`;
   - `aprobado_direccion_ventas`;
   - `esperando_autorizacion`;
   - `proceso`;
   - `rechazado`;
   - `sin_estatus`.
5. Calcula dias entre hitos con `datediff`.

### Tests actuales

- `cronograma_unidad_key`: `not_null`, `unique`
- `unidad_key`: `not_null`
- `desarrollo_largo`: `not_null`
- `unidad`: `not_null`
- combinacion unica: `desarrollo_largo + unidad`

### Riesgos o pendientes

- No tiene `id_venta`; debe interpretarse como avance operativo de unidad, no
  necesariamente de venta.
- Usa `max(...)` para consolidar filas. Si hay datos conflictivos en cronograma,
  el modelo no los expone.
- No fuerza relationship con `dim_unidades` ni con `fct_ventas`.
- Pendiente a revisar: en `stg_reports__cronograma_unidades`,
  `DESARROLLO_CORTO` se asigna a `desarrollo_largo` y `DESARROLLO_LARGO` se
  asigna a `desarrollo_corto`.

## Tests actuales de warehouse

La seleccion `path:models/warehouse` contiene:

- 12 modelos;
- 43 tests;
- 53 nodos totales procesados por `dbt compile` incluyendo modelos y tests.

Modelos con tests declarados:

- `dim_unidades`
- `fct_ventas`
- `fct_pagos_vencidos`
- `fct_cronograma_unidades`
- `dim_personas`
- `bridge_venta_persona`
- `fct_ingresos`
- `fct_facturas`
- `dim_date`

Modelos sin tests/documentacion directa:

- `int_unidades_atributos`
- `int_ventas_atributos`
- `int_venta_persona`

## Decisiones importantes

### Relaciones no forzadas contra ventas

Por ahora no se fuerzan estas relaciones:

- `fct_ingresos.venta_key -> fct_ventas.venta_key`
- `fct_pagos_vencidos.venta_key -> fct_ventas.venta_key`
- `fct_facturas -> fct_ventas`
- `fct_cronograma_unidades -> fct_ventas`

Esto es correcto en el estado actual porque hay fuentes que pueden tener datos
que no aparecen en `rp_vista_ventas`.

### Auditorias de cobertura

Las relaciones debiles no se fuerzan como tests obligatorios, pero se auditan en
`analyses/cobertura_relaciones_debiles.sql`.

La analysis mide:

- `fct_ingresos -> fct_ventas`
- `fct_pagos_vencidos -> fct_ventas`
- `fct_cronograma_unidades -> dim_unidades`
- `fct_facturas -> fct_ventas`, marcado como `sin_llave_confiable`

Esto permite reportar cobertura sin convertir relaciones incompletas o
conceptualmente debiles en fallas de build.

Aclaracion: ingresos y pagos vencidos sin venta estan cubiertos por esta
analysis, no por tests singulares separados.

Ultima ejecucion observada:

| Relacion | Total | Con relacion | Sin relacion | Cobertura |
| --- | ---: | ---: | ---: | ---: |
| `fct_ingresos -> fct_ventas` | 5000 | 5000 | 0 | 100.00% |
| `fct_pagos_vencidos -> fct_ventas` | 4348 | 4348 | 0 | 100.00% |
| `fct_cronograma_unidades -> dim_unidades` | 5000 | 3312 | 1688 | 66.24% |
| `fct_facturas -> fct_ventas` | 5000 | n/a | n/a | n/a |

### Ventas canceladas fuera del warehouse principal

Aunque staging ya tiene modelos de canceladas, warehouse todavia no los integra.
Esto evita mezclar ventas activas/observadas con canceladas sin una regla clara.

### Unidades observadas, no inventario completo

`dim_unidades` nace desde ventas observadas. No debe asumirse como inventario
maestro completo.

### Grupos desde seed manual

`dim_unidades.grupo` viene del seed `grupos_desarrollos`. Este archivo debe
mantenerse actualizado si aparecen desarrollos nuevos o cambios de grupo.

### Uso de `max(...)`

Varios modelos usan `max(...)` para deduplicar:

- `int_unidades_atributos`
- `int_ventas_atributos`
- `dim_personas`
- `fct_cronograma_unidades`

Esto mantiene un grano claro, pero puede ocultar conflictos. Existen auditorias
singulares iniciales en `tests/singular/`:

- `conflictos_unidades_atributos`
- `conflictos_ventas_atributos`
- `conflictos_persona_natural_key`
- `conflictos_cronograma_unidades`
- `distintos_asesores`
- `unidades_sin_grupo`
- `ventas_con_mas_de_un_cliente_principal`

Verificacion con datos: `conflictos_persona_natural_key` devuelve filas en el
estado actual. Hay personas naturales con multiples RFC o emails asociados, por
lo que se debe decidir si se limpia la fuente, si se ajusta la llave natural o
si este test queda temporalmente como advertencia.

Decision actual: `conflictos_persona_natural_key` queda configurado con
`severity='warn'`. Es una auditoria de calidad util para seguimiento, pero no
debe bloquear el build mientras se resuelve la causa de fondo.

Decision actual adicional: `unidades_sin_grupo` y
`ventas_con_mas_de_un_cliente_principal` tambien quedan como warnings. Son
auditorias nuevas de monitoreo para no bloquear el pipeline mientras se observa
la calidad real de datos.

El resto de tests mantiene severidad de error por defecto.

Warnings esperados en `dbt build`: `conflictos_persona_natural_key`,
`unidades_sin_grupo` y `ventas_con_mas_de_un_cliente_principal`.

## Problemas o gaps prioritarios

1. Documentar y testear los tres modelos `int`.
2. Mantener y ajustar auditorias singulares conforme se descubran nuevos
   conflictos de calidad.
3. Mantener sin relationship obligatorio ingresos/cartera/facturas/cronograma
   contra ventas hasta validar cobertura.
4. Aclarar si `uuid` debe seguir siendo obligatorio en facturacion.
5. Mantener la auditoria de unidades sin `grupo` y actualizar el seed cuando
   aparezcan desarrollos nuevos.
6. Validar que `dim_date` cubre todo el rango temporal necesario.
7. Modelar canceladas como subdominio separado si el negocio lo requiere.

## Verificacion realizada

Durante la revision se ejecuto:

```bash
dbt parse
dbt ls --select path:models/warehouse --output name
dbt ls --select path:models/warehouse --resource-type test --output name
dbt compile --select path:models/warehouse
```

Resultados:

- `dbt parse` termino correctamente.
- dbt detecto 12 modelos warehouse.
- dbt detecto 43 tests asociados a warehouse.
- `dbt compile --select path:models/warehouse` termino correctamente con red
  habilitada.

Warning observado:

- dbt no pudo descargar deferral manifest porque no hay deferral environment
  configurado en dbt Cloud. Esto no bloqueo la compilacion local.

Importante: `dbt compile` valida grafo, Jinja y compilacion, pero no ejecuta los
modelos contra Databricks como lo haria `dbt build`. Para validar datos reales,
tests y relaciones sobre la base, hace falta correr `dbt build`.

## Lectura recomendada

Para entender warehouse rapidamente:

1. Empieza por `fct_ventas`, porque es la fact central.
2. Lee `dim_unidades`, porque explica como se identifican unidades.
3. Lee `int_venta_persona`, `dim_personas` y `bridge_venta_persona` juntos.
4. Lee `fct_ingresos` como fact independiente de cobranza/ingresos.
5. Lee `fct_pagos_vencidos` como fact independiente de cartera vencida.
6. Lee `fct_facturas` como fact fiscal aislada de ventas.
7. Lee `fct_cronograma_unidades` como snapshot operativo por unidad.
8. Usa los marts para responder preguntas finales; warehouse debe quedarse como
   base reutilizable.
