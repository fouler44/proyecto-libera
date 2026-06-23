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

@st.cache_data(ttl=300)
def load_sales_by_desarrollo(min_ventas: int = 0, dias: int = 30) -> pd.DataFrame:
    """Carga ventas agregadas por desarrollo_corto desde mart_comercial_ventas."""

    min_ventas = int(min_ventas)
    dias = int(dias)

    query = f"""
        select
            desarrollo_corto,
            count(*) as total_ventas,
            sum(coalesce(precio_venta, 0)) as precio_venta_total,
            avg(precio_venta) as precio_venta_promedio
        from {CATALOG}.{SCHEMA}.mart_comercial_ventas
        where fecha_registro_venta >= date_sub(current_date(), {dias})
        group by desarrollo_corto
        having count(*) >= {min_ventas}
        order by total_ventas desc
    """

    return sqlQuery(query)


def main():
    st.title("🌿 Dashboard Operaciones Libera")
    
    st.markdown("""
    Este dashboard consume los modelos analíticos construidos con dbt sobre Databricks.
    """)
    
    st.sidebar.header("Filtros")
    
    time_options = {
        "Último día": 1,
        "Últimos 7 días": 7,
        "Últimos 30 días": 30
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
    
    loading_msg = "Cargando datos..."
    with st.spinner(loading_msg):
        try:
            df_sales = load_sales_by_desarrollo(min_ventas=min_ventas, dias=days)
        except Exception as e:
            st.error(f"Error al cargar los datos: {e}")
            return
        
    if df_sales.empty:
        st.warning("No hay ventas para los filtros seleccionados.")
        return

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

if __name__ == "__main__":
    main()