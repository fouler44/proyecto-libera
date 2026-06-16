uuid de facturas tal vez upper, pero de momento no

En status_ingreso de ingresos cancelados hay valores raros, no tienen mas valores, parecen filas inservibles

Lugar de nacimiento está bastante sucio, pero lo dejare para después

No se que hacer aún con asesor, parece ser solo un nombre, habría que confirmar que siempre este escrito igual

---

# Plan para recrear `rp_dashboard_operaciones` y añadir columnas a otras tablas

- `PRECIOLISTA` y `PRECIOM2` está en `rp_dashboard_operaciones`, podría ir a dim_unidades

- `CAMPANIA` está en `rp_dashboard_operaciones` y rp_cronograma_unidades, tal vez debería ir a fct_ventas

- `VENDEDOREXTERNO` está en `rp_dashboard_operaciones`, no se que hacer con esto. Tal vez debería ir a ventas

- `FECHADESTATUS` está en `rp_dashboard_operaciones`. Probable fecha derivada según status de rp_cronograma_unidades. Tal vez debería ir a ventas

- `NUMEROENGANCHES` está en `rp_dashboard_operaciones`. Probablemente derivable de flujo_ingresos, conteo de pagos de enganche. No se si debería ir a otra tabla, es posible que se use en un mart que remplace dashboard_operaciones.

- `PRECIOM2V` está en `rp_dashboard_operaciones`. Tal vez a fct_ventas

- `TOTAL_COBRADO` derivable de flujo_ingresos.monto_pagado. Se usaría en un mart que remplace dashboard_operaciones.

- `SALDOTOTAL` probablemente es derivable.  

- `SIELTOTALCOBRADOESMENORQUEELENGANCHE` es derivable. Se usaría en un mart que remplace dashboard_operaciones.

- `REQUIERE_FACTURA` está en `rp_dashboard_operaciones`. Aún no se si agregarlo a una tabla ya existente, no creo que tenga sentido hacer una tabla nueva.

- `FECHAPRIMERENGANCHE` está en `rp_dashboard_operaciones` y `fct_ventas`, tal vez se puede quitar de fct_ventas y dejarlo en el nuevo mart.

- `FECHAULTIMOPAGOENGANCHE` mismo caso de `FECHAPRIMERENGANCHE`

- `MONTODELPRIMERENGANCHE` derivable de flujo_ingresos. Se usaría en un mart que remplace dashboard_operaciones.

- `COMISIONASESOR` está en `rp_dashboard_operaciones`, de momento no se si colocarlo en otro lugar, asi que probablemente se usa en el nuevo mart.

- `COMISIONLIBERA` está en `rp_dashboard_operaciones`, mismo caso de `COMISIONASESOR`




# Conclusiones

- PRECIOLISTA y PRECIOM2 a dim_unidades, confirmar si cambian con el tiempo o dependen del momento de venta

- PRECIOM2V a fct_venta

- CAMPANIA si podría formar parte de ventas, pero en `stg_reports__cronograma_unidades` no hay id_venta

- REQUIERE_FACTURA si podría estar en ventas, segun yo no hay más columnas sobre las facturas

- TOTAL_COBRADO es una métrica derivada, consumirá en mart_dashboard_operaciones y mart_cobranza_por_venta. Asegurarse de filtrarlo correctamente

- TOTALVENCIDO Viene del dominio de cobranza/cartera vencida y se consumirá en mart_dashboard_operaciones.

- SALDOTOTAL es un derivado, hay que validar en rp_dashboard_operaciones y se consumirá en mart_dashboard_operaciones.

- SIELTOTALCOBRADOESMENORQUEELENGANCHE se usará en mart_dashboard_operaciones.

- NUMEROENGANCHES descubrir si es Número de enganches pactados en el contrato o Número de pagos de enganche realmente realizados, no lo quiero meter a fct_ventas de momento, si a mart_dashboard_operaciones.

- MONTODELPRIMERENGANCHE descubrir si es monto pactado del primer enganche o monto del primer pago real registrado como enganche, se va a usar en mart_dashboard_operaciones

- FECHAPRIMERENGANCHE y FECHAULTIMOPAGOENGANCHE se quedarán en fct_ventas y se usarán en mart_dashboard_operaciones, descubrir si vienen de la venta/contrato o calcularse en fct_ingresos

- FECHADESTATUS se usará en mart_dashboard_operaciones

- VENDEDOREXTERNO se usará en mart_dashboard_operaciones

- COMISIONASESOR y COMISIONLIBERA se usarán en mart_dashboard_operaciones