import pandas as pd
import streamlit as st
from databricks import sql

st.set_page_config(
    page_title="Dashboard Operaciones Libera",
    page_icon="🌿",
    layout="wide",
)

# Connection settings from environment
CATALOG = st.secrets["CATALOG"]
SCHEMA = st.secrets["SCHEMA"]

def sqlQuery(query: str) -> pd.DataFrame:
    with sql.connect(server_hostname = st.secrets["DATABRICKS_SERVER_HOSTNAME"],
                     http_path       = st.secrets["DATABRICKS_HTTP_PATH"],
                     access_token    = st.secrets["DATABRICKS_TOKEN"]
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute(query)
            return cursor.fetchall_arrow().to_pandas()


def date_filter_clause(column_name: str, dias: int | None) -> str:
    if dias is None:
        return ""

    dias = int(dias)
    return f"where {column_name} >= date_sub(current_date(), {dias})"


@st.cache_data(ttl=300)
def load_sales_by_desarrollo(min_ventas: int = 0, dias: int | None = 30) -> pd.DataFrame:
    """Carga ventas agregadas por desarrollo_corto desde mart_comercial_ventas."""

    min_ventas = int(min_ventas)
    date_filter = date_filter_clause("fecha_registro_venta", dias)

    query = f"""
        select
            desarrollo_corto,
            count(*) as total_ventas,
            sum(coalesce(precio_venta, 0)) as precio_venta_total,
            avg(precio_venta) as precio_venta_promedio
        from {CATALOG}.{SCHEMA}.mart_comercial_ventas
        {date_filter}
        group by desarrollo_corto
        having count(*) >= {min_ventas}
        order by total_ventas desc
    """

    return sqlQuery(query)


@st.cache_data(ttl=300)
def load_dash_cron_kpis(dias: int | None = 30) -> pd.DataFrame:
    """Carga KPIs generales desde mart_dash_cron."""

    date_filter = date_filter_clause("fecha_de_status", dias)

    query = f"""
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
        from {CATALOG}.{SCHEMA}.mart_dash_cron
        {date_filter}
    """

    return sqlQuery(query)


@st.cache_data(ttl=300)
def load_dash_cron_status_unidad_counts(dias: int | None = 30) -> pd.DataFrame:
    """Carga conteo de ventas por status_unidad desde mart_dash_cron."""

    date_filter = date_filter_clause("fecha_de_status", dias)

    query = f"""
        select
            coalesce(nullif(status_unidad, ''), 'SIN STATUS_UNIDAD') as status_unidad,
            count(id_venta) as cantidad
        from {CATALOG}.{SCHEMA}.mart_dash_cron
        {date_filter}
        group by 1
        order by cantidad desc
    """

    return sqlQuery(query)


@st.cache_data(ttl=300)
def load_dash_cron_status_venta_counts(dias: int | None = 30) -> pd.DataFrame:
    """Carga conteo de ventas por status_venta desde mart_dash_cron."""

    date_filter = date_filter_clause("fecha_de_status", dias)

    query = f"""
        select
            coalesce(nullif(status_venta, ''), 'SIN STATUS_VENTA') as status_venta,
            count(id_venta) as cantidad
        from {CATALOG}.{SCHEMA}.mart_dash_cron
        {date_filter}
        group by 1
        order by cantidad desc
    """

    return sqlQuery(query)


@st.cache_data(ttl=300)
def load_dash_cron_grupo_counts(dias: int | None = 30) -> pd.DataFrame:
    """Carga conteo de ventas por grupo desde mart_dash_cron."""

    date_filter = date_filter_clause("fecha_de_status", dias)

    query = f"""
        select
            coalesce(nullif(grupo, ''), 'SIN GRUPO') as grupo,
            count(id_venta) as cantidad
        from {CATALOG}.{SCHEMA}.mart_dash_cron
        {date_filter}
        group by 1
        order by cantidad desc
    """

    return sqlQuery(query)


def format_number(value) -> str:
    if value is None or pd.isna(value):
        value = 0
    return f"{float(value):,.0f}"


def format_currency(value) -> str:
    if value is None or pd.isna(value):
        value = 0
    return f"${float(value):,.2f}"


def main():
    st.title("🌿 Dashboard Operaciones Libera")
    
    st.markdown("""
    Este dashboard consume los modelos analíticos construidos con dbt sobre Databricks.
    """)
    
    st.sidebar.header("Filtros")
    
    time_options = {
        "Último día": 1,
        "Últimos 7 días": 7,
        "Últimos 30 días": 30,
        "Últimos 3 meses": 90,
        "Últimos 6 meses": 180,
        "Todo el tiempo": None,
    }
    
    selected_time = st.sidebar.selectbox(
        "Rango de tiempo",
        options=list(time_options.keys()),
        index=2
    )
    days = time_options[selected_time]
    
    min_ventas = st.sidebar.number_input(
        "Mínimo de ventas por desarrollo",
        min_value=0,
        value=0,
        step=1,
    )
    
    tab_sales, tab_dash_cron = st.tabs(["Ventas por desarrollo", "Dash cron"])

    with tab_sales:
        with st.spinner("Cargando datos..."):
            try:
                df_sales = load_sales_by_desarrollo(min_ventas=min_ventas, dias=days)
            except Exception as e:
                st.error(f"Error al cargar los datos: {e}")
                df_sales = None

        if df_sales is None:
            pass
        elif df_sales.empty:
            st.warning("No hay ventas para los filtros seleccionados.")
        else:
            col1, col2, col3 = st.columns(3)

            with col1:
                st.metric(
                    "Desarrollos",
                    f"{df_sales['desarrollo_corto'].nunique():,}",
                )

            with col2:
                st.metric(
                    "Total ventas",
                    f"{df_sales['total_ventas'].sum():,}",
                )

            with col3:
                st.metric(
                    "Precio venta total",
                    f"${df_sales['precio_venta_total'].sum():,.2f}",
                )

            st.divider()

            st.subheader("Ventas por desarrollo")

            chart_data = df_sales.set_index("desarrollo_corto")["total_ventas"]
            st.bar_chart(chart_data)

            st.subheader("Detalle")

            st.dataframe(
                df_sales,
                use_container_width=True,
                hide_index=True,
            )

    with tab_dash_cron:
        with st.spinner("Cargando datos..."):
            try:
                df_kpis = load_dash_cron_kpis(dias=days)
                df_status_unidad = load_dash_cron_status_unidad_counts(dias=days)
                df_status_venta = load_dash_cron_status_venta_counts(dias=days)
                df_grupo = load_dash_cron_grupo_counts(dias=days)
            except Exception as e:
                st.error(f"Error al cargar los datos: {e}")
                df_kpis = None

        if df_kpis is None:
            pass
        elif df_kpis.empty:
            st.warning("No hay datos de mart_dash_cron disponibles.")
        else:
            kpis = df_kpis.iloc[0]

            kpi_col1, kpi_col2, kpi_col3 = st.columns(3)
            with kpi_col1:
                st.metric("Total ventas", format_number(kpis["total_ventas"]))
            with kpi_col2:
                st.metric("Precio venta total", format_currency(kpis["precio_venta_total"]))
            with kpi_col3:
                st.metric("Total cobrado", format_currency(kpis["total_cobrado"]))

            kpi_col4, kpi_col5, kpi_col6 = st.columns(3)
            with kpi_col4:
                st.metric("Total vencido", format_currency(kpis["total_vencido"]))
            with kpi_col5:
                st.metric("Saldo total", format_currency(kpis["saldo_total"]))
            with kpi_col6:
                st.metric("Unidades con vencido", format_number(kpis["unidades_con_vencido"]))

            st.divider()

            chart_col1, chart_col2, chart_col3 = st.columns(3)

            with chart_col1:
                st.subheader("Ventas por status_unidad")
                if df_status_unidad.empty:
                    st.warning("No hay datos de status_unidad disponibles.")
                else:
                    chart_data = df_status_unidad.set_index("status_unidad")["cantidad"]
                    st.bar_chart(chart_data)

            with chart_col2:
                st.subheader("Ventas por status_venta")
                if df_status_venta.empty:
                    st.warning("No hay datos de status_venta disponibles.")
                else:
                    chart_data = df_status_venta.set_index("status_venta")["cantidad"]
                    st.bar_chart(chart_data)

            with chart_col3:
                st.subheader("Ventas por grupo")
                if df_grupo.empty:
                    st.warning("No hay datos de grupo disponibles.")
                else:
                    chart_data = df_grupo.set_index("grupo")["cantidad"]
                    st.bar_chart(chart_data)

            st.subheader("Detalle")

            detail_col1, detail_col2, detail_col3 = st.columns(3)

            with detail_col1:
                st.caption("status_unidad")
                st.dataframe(
                    df_status_unidad,
                    use_container_width=True,
                    hide_index=True,
                )

            with detail_col2:
                st.caption("status_venta")
                st.dataframe(
                    df_status_venta,
                    use_container_width=True,
                    hide_index=True,
                )

            with detail_col3:
                st.caption("grupo")
                st.dataframe(
                    df_grupo,
                    use_container_width=True,
                    hide_index=True,
                )

if __name__ == "__main__":
    main()
