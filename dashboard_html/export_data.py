import json
import os
from pathlib import Path

import pandas as pd
from databricks import sql
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BASE_DIR / "data"
SALES_OUTPUT_FILE = OUTPUT_DIR / "ventas_por_desarrollo.json"
DASH_CRON_OUTPUT_FILE = OUTPUT_DIR / "dash_cron.json"

RANGES = (
    (1, "\u00daltimo d\u00eda"),
    (7, "\u00daltimos 7 d\u00edas"),
    (30, "\u00daltimos 30 d\u00edas"),
    (90, "\u00daltimos 3 meses"),
    (180, "\u00daltimos 6 meses"),
    (None, "Todo el tiempo"),
)


def env(name: str, default: str | None = None) -> str:
    value = os.getenv(name, default)
    if value is None or value == "":
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def query_databricks(query: str) -> pd.DataFrame:
    with sql.connect(
        server_hostname=env("DATABRICKS_SERVER_HOSTNAME"),
        http_path=env("DATABRICKS_HTTP_PATH"),
        access_token=env("DATABRICKS_TOKEN"),
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute(query)
            return cursor.fetchall_arrow().to_pandas()


def date_filter_clause(column_name: str, days: int | None) -> str:
    if days is None:
        return ""

    return f"where {column_name} >= date_sub(current_date(), {int(days)})"


def records(df: pd.DataFrame) -> list[dict]:
    return json.loads(df.to_json(orient="records", force_ascii=False))


def load_sales_by_desarrollo(catalog: str, schema: str, days: int | None, label: str) -> pd.DataFrame:
    date_filter = date_filter_clause("fecha_registro_venta", days)

    ventas = query_databricks(f"""
        select
            desarrollo_corto as desarrollo,
            count(*) as total_ventas,
            sum(coalesce(precio_venta, 0)) as precio_venta_total,
            avg(precio_venta) as precio_venta_promedio
        from {catalog}.{schema}.mart_comercial_ventas
        {date_filter}
        group by desarrollo_corto
        order by total_ventas desc
    """)

    ventas.insert(0, "rango_label", label)
    ventas.insert(0, "rango_dias", days)
    return ventas


def load_dash_cron_kpis(catalog: str, schema: str, days: int | None) -> pd.DataFrame:
    date_filter = date_filter_clause("fecha_de_status", days)

    return query_databricks(f"""
        select
            count(id_venta) as total_ventas,
            sum(coalesce(precio_venta, 0)) as precio_venta_total,
            sum(coalesce(total_cobrado, 0)) as total_cobrado,
            sum(coalesce(total_vencido, 0)) as total_vencido,
            sum(coalesce(saldo_total, 0)) as saldo_total,
            sum(
                case
                    when coalesce(total_vencido, 0) > 0 then 1
                    else 0
                end
            ) as unidades_con_vencido
        from {catalog}.{schema}.mart_dash_cron
        {date_filter}
    """)


def load_dash_cron_counts(
    catalog: str,
    schema: str,
    days: int | None,
    column_name: str,
    alias: str,
    empty_label: str,
) -> pd.DataFrame:
    date_filter = date_filter_clause("fecha_de_status", days)

    return query_databricks(f"""
        select
            coalesce(nullif({column_name}, ''), '{empty_label}') as {alias},
            count(id_venta) as cantidad
        from {catalog}.{schema}.mart_dash_cron
        {date_filter}
        group by 1
        order by cantidad desc
    """)


def load_dash_cron_range(catalog: str, schema: str, days: int | None, label: str) -> dict:
    kpis = records(load_dash_cron_kpis(catalog, schema, days))

    return {
        "rango_dias": days,
        "rango_label": label,
        "kpis": kpis[0] if kpis else {},
        "status_unidad": records(
            load_dash_cron_counts(catalog, schema, days, "status_unidad", "status_unidad", "SIN STATUS_UNIDAD")
        ),
        "status_venta": records(
            load_dash_cron_counts(catalog, schema, days, "status_venta", "status_venta", "SIN STATUS_VENTA")
        ),
        "grupo": records(
            load_dash_cron_counts(catalog, schema, days, "grupo", "grupo", "SIN GRUPO")
        ),
    }


def main() -> None:
    load_dotenv(BASE_DIR / ".env")

    catalog = env("CATALOG", "analyticsgl")
    schema = env("SCHEMA", "dev_aurbano")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    ventas = pd.concat(
        [
            load_sales_by_desarrollo(
                catalog=catalog,
                schema=schema,
                days=days,
                label=label,
            )
            for days, label in RANGES
        ],
        ignore_index=True,
    )

    ventas.to_json(
        SALES_OUTPUT_FILE,
        orient="records",
        force_ascii=False,
        indent=2,
    )

    dash_cron = {
        "ranges": [
            load_dash_cron_range(
                catalog=catalog,
                schema=schema,
                days=days,
                label=label,
            )
            for days, label in RANGES
        ]
    }

    DASH_CRON_OUTPUT_FILE.write_text(
        json.dumps(dash_cron, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"Wrote {len(ventas):,} rows to {SALES_OUTPUT_FILE}")
    print(f"Wrote {len(dash_cron['ranges']):,} ranges to {DASH_CRON_OUTPUT_FILE}")


if __name__ == "__main__":
    main()
