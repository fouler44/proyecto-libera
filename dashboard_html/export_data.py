import os
from pathlib import Path

import pandas as pd
from databricks import sql
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BASE_DIR / "data"
OUTPUT_FILE = OUTPUT_DIR / "ventas_por_desarrollo.json"

RANGES = (
    (1, "\u00daltimo d\u00eda"),
    (7, "\u00daltimos 7 d\u00edas"),
    (30, "\u00daltimos 30 d\u00edas"),
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


def load_sales_by_desarrollo(catalog: str, schema: str, days: int, label: str) -> pd.DataFrame:
    ventas = query_databricks(f"""
        select
            desarrollo_corto as desarrollo,
            count(*) as total_ventas,
            sum(coalesce(precio_venta, 0)) as precio_venta_total,
            avg(precio_venta) as precio_venta_promedio
        from {catalog}.{schema}.mart_comercial_ventas
        where fecha_registro_venta >= date_sub(current_date(), {int(days)})
        group by desarrollo_corto
        order by total_ventas desc
    """)

    ventas.insert(0, "rango_label", label)
    ventas.insert(0, "rango_dias", days)
    return ventas


def main() -> None:
    load_dotenv()

    catalog = os.getenv("CATALOG")
    schema = os.getenv("SCHEMA")

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
        OUTPUT_FILE,
        orient="records",
        force_ascii=False,
        indent=2,
    )

    print(f"Wrote {len(ventas):,} rows to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
