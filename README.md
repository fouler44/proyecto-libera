# Pipeline Libera dbt

Proyecto dbt para transformar reportes operativos del CRM de Libera en un modelo analítico sobre Databricks.

El pipeline toma tablas fuente de reportes, las limpia en `staging`, construye entidades reutilizables en `warehouse` y expone tablas finales en `marts` para análisis comercial, cobranza, ingresos, cartera vencida y facturación.

Flujo principal:

```text
raw -> staging -> warehouse -> marts
```

## Estructura del proyecto

```text
.agents/
  skills/                    # Workflows locales para agentes, cuando aplican
.github/
  workflows/
    ci.yml                   # dbt build en pull requests hacia main
    desploy_dashboard.yml    # Export y deploy del dashboard estático
docs/
  resumen_staging.md         # Resumen de la capa staging
  resumen_warehouse.md       # Resumen de la capa warehouse
  resumen_marts.md           # Resumen de marts y decisiones de consumo
  data_flow.png              # Lineage principal
  dimensional_model.png      # Modelo dimensional
libera_dbt/
  analyses/                  # Consultas ad hoc y reconciliaciones
  macros/
    generate_schema_name.sql # Ruteo de schemas por target
  models/
    staging/
      reports/               # Views 1:1 con fuentes raw
    warehouse/
      int/                   # Modelos intermedios ephemeral
      dimensions/            # dim_ y bridge_
      facts/                 # fct_
    marts/                   # Tablas finales para consumo
  seeds/
  tests/
    singular/                # Pruebas singulares de auditoría
  dbt_project.yml
  packages.yml
pyproject.toml               # Dependencias Python del proyecto
uv.lock                      # Lockfile de uv
.python-version              # Versión esperada de Python

# Archivos locales no versionados
.env                         # Variables locales, gitignored
~/.dbt/profiles.yml          # Perfil local de dbt, fuera del repo
```

## Requisitos

- Python `>=3.13`.
- [`uv`](https://docs.astral.sh/uv/) recomendado para manejar el entorno local.
- Acceso a Databricks SQL Warehouse o cualquier Warehouse que se vaya a usar (los requisitos para la conexión pueden variar).
- Token, host y HTTP path de Databricks configurados como variables de entorno o en `~/.dbt/profiles.yml`.

El proyecto dbt vive en `libera_dbt/`; ejecuta los comandos de dbt desde esa carpeta.

## Instalación con uv

Desde la raíz del repositorio:

```powershell
uv sync
```

Instala los paquetes de dbt:

```powershell
cd libera_dbt
uv run dbt deps
```

Valida la conexión:

```powershell
uv run dbt debug --profiles-dir ~/.dbt --target dev
```

Ejecuta el proyecto completo en desarrollo:

```powershell
uv run dbt build --profiles-dir ~/.dbt --target dev
```

Para iterar sobre un mart específico:

```powershell
uv run dbt build --select mart_facturacion --profiles-dir ~/.dbt --target dev
```

## Alternativa con pip + venv

Si no quieres usar `uv`, también puedes trabajar con `pip + venv`. CI ya usa `pip` para instalar dbt, y las dependencias del proyecto son paquetes Python instalables normalmente.

En Windows:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install "databricks-sql-connector>=4.3.0" "dbt-bigquery>=1.11.3" "dbt-databricks>=1.10.9" "dotenv>=0.9.9"
cd libera_dbt
dbt deps
dbt debug --profiles-dir ~/.dbt --target dev
```

Nota: la `.venv` creada por `uv` puede no traer `pip`. Si vas a usar esta alternativa, crea una venv propia con `python -m venv .venv`.

## Perfiles de dbt

El proyecto espera un perfil llamado `pipeline_libera_dbt`, definido en `libera_dbt/dbt_project.yml`.

El archivo `profiles.yml` no se versiona. Debe vivir en `~/.dbt/profiles.yml` y leer credenciales desde variables de entorno.

Ejemplo base:

```yaml
pipeline_libera_dbt:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: analyticsgl
      schema: dev_<tu_nombre>
      host: "{{ env_var('DATABRICKS_HOST') }}"
      http_path: "{{ env_var('DATABRICKS_HTTP_PATH') }}"
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
      auth_type: token
      threads: 4

    ci:
      type: databricks
      catalog: analyticsgl
      schema: ci
      host: "{{ env_var('DATABRICKS_HOST') }}"
      http_path: "{{ env_var('DATABRICKS_HTTP_PATH') }}"
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
      auth_type: token
      threads: 16

    prod:
      type: databricks
      catalog: analyticsgl
      schema: default
      host: "{{ env_var('DATABRICKS_HOST') }}"
      http_path: "{{ env_var('DATABRICKS_HTTP_PATH') }}"
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
      auth_type: token
      threads: 16
```

### Target dev

Uso local. Apunta a un schema personal, por ejemplo `dev_jdoe`.

El macro `generate_schema_name` hace que, en `dev`, todos los modelos usen `target.schema`. Esto evita crear múltiples schemas durante desarrollo y mantiene el trabajo aislado por persona.

Comando típico:

```powershell
uv run dbt build --profiles-dir ~/.dbt --target dev
```

### Target ci

Uso de pruebas automatizadas. El workflow `.github/workflows/ci.yml` crea este perfil durante pull requests a `main`.

También usa un schema único (`ci`) para que los builds de validación no publiquen en los schemas productivos.

Comando para reproducir CI localmente:

```powershell
uv run dbt build --profiles-dir ~/.dbt --target ci
```

### Target prod

Uso productivo. En `prod`, el macro respeta los schemas configurados por capa en `dbt_project.yml`:

- `staging` para modelos de staging.
- `warehouse` para dimensiones, facts e intermedios materializados.
- `marts` para tablas finales.
- `seeds` para seeds.

Ejecuta `prod` solo cuando el cambio ya haya pasado por `dev` y CI.

```powershell
uv run dbt build --profiles-dir ~/.dbt --target prod
```

## Variables de entorno

Para dbt:

```powershell
$env:DATABRICKS_HOST = "<host>"
$env:DATABRICKS_HTTP_PATH = "<http-path>"
$env:DBT_DATABRICKS_TOKEN = "<token>"
```

No subas `.env`, tokens, `profiles.yml`, `target/`, `dbt_packages/` ni logs.

## Comandos útiles

```powershell
cd libera_dbt

# Instalar paquetes dbt
uv run dbt deps

# Validar configuración y conexión
uv run dbt debug --profiles-dir ~/.dbt --target dev

# Compilar, ejecutar y probar todo
uv run dbt build --profiles-dir ~/.dbt --target dev

# Ejecutar una selección
uv run dbt build --select mart_dash_cron --profiles-dir ~/.dbt --target dev

# Limpiar artefactos generados
uv run dbt clean
```

## Documentación de capas

Este README es una guía de instalación y orientación rápida. Para entender el detalle del modelo, decisiones de grano, riesgos y uso recomendado de tablas, consulta:

- [Resumen de staging](docs/resumen_staging.md)
- [Resumen de warehouse](docs/resumen_warehouse.md)
- [Resumen de marts](docs/resumen_marts.md)

## Recursos para aprender

Estos recursos pueden servir para reforzar conceptos de dbt, modelado analítico y buenas prácticas de analytics engineering:

- [Kahan Data Solutions en YouTube](https://www.youtube.com/@KahanDataSolutions)
- [Video recomendado de dbt](https://www.youtube.com/watch?v=-Z7gPn5Jv0I)
