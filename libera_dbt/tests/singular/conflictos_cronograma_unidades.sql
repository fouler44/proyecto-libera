select
    desarrollo_largo,
    unidad,
    count(distinct rechazado) as rechazados_distintos,
    count(distinct proceso) as procesos_distintos,
    count(distinct esperando_autorizacion) as esperando_autorizacion_distintas,
    count(distinct aprobado_direccion_ventas) as aprobados_direccion_ventas_distintos,
    count(distinct aprobado_juridico) as aprobados_juridico_distintos,
    count(distinct finalizado) as finalizados_distintos,
    count(distinct finalizado_liquidado) as finalizados_liquidados_distintos
from {{ ref('stg_reports__cronograma_unidades') }}
where desarrollo_largo is not null
  and unidad is not null
group by
    desarrollo_largo,
    unidad
having count(distinct rechazado) > 1
    or count(distinct proceso) > 1
    or count(distinct esperando_autorizacion) > 1
    or count(distinct aprobado_direccion_ventas) > 1
    or count(distinct aprobado_juridico) > 1
    or count(distinct finalizado) > 1
    or count(distinct finalizado_liquidado) > 1
