uuid de facturas tal vez upper, pero de momento no

En status_ingreso de ingresos cancelados hay valores raros, no tienen mas valores, parecen filas inservibles

Lugar de nacimiento está bastante sucio, pero lo dejare para después

No se que hacer aún con asesor, parece ser solo un nombre, habría que confirmar que siempre este escrito igual

---

2. Actualizar mart_cobranza_por_venta

Tu mart_cobranza_por_venta ya compara:

precio_venta vs total_ingresado

Ahora debería agregar cartera vencida:

total_vencido
numero_pagos_vencidos
dias_atraso_maximo
Nueva lógica
fct_ventas
  + ingresos_por_venta
  + cartera_por_venta
  + dim_unidades
Métricas finales recomendadas
precio_venta
total_ingresado
saldo_estimado
porcentaje_cobrado
total_vencido
numero_pagos_vencidos
dias_atraso_maximo
estatus_cobranza_estimado
Estatus útil

Agrega algo así:

case
    when coalesce(total_ingresado, 0) = 0 then 'sin_ingresos'
    when coalesce(total_ingresado, 0) >= precio_venta then 'cobrado_total'
    when coalesce(total_vencido, 0) > 0 then 'con_vencido'
    else 'cobranza_al_corriente'
end as estatus_cobranza_estimado

Esto ya lo hace mucho más útil para negocio.