-- Reconciliacion exploratoria entre el dashboard operativo legacy y el mart
-- reconstruido desde facts. Las diferencias no implican por si solas que un
-- modelo este mal: sirven para encontrar brechas explicables.
select
    d.id_venta,

    d.total_cobrado as total_cobrado_legacy,
    r.total_cobrado as total_cobrado_reconstruido,
    d.total_cobrado - r.total_cobrado as diferencia_total_cobrado,

    d.total_vencido as total_vencido_legacy,
    r.total_vencido as total_vencido_reconstruido,
    d.total_vencido - r.total_vencido as diferencia_total_vencido,

    d.saldo_total as saldo_total_legacy,
    r.saldo_total_estimado,
    d.saldo_total - r.saldo_total_estimado as diferencia_saldo,

    case
        when r.id_venta is null then true
        else false
    end as sin_reconstruido
from {{ ref('mart_dash_cron') }} d
left join {{ ref('mart_dash_cron_reconstruido') }} r
    on d.id_venta = r.id_venta
