/* Legacy implementation replaced by the dashboard redesign below.
const DATA_URL = "data/ventas_por_desarrollo.json";

const RANGE_LABELS = new Map([
  [1, "\u00daltimo d\u00eda"],
  [7, "\u00daltimos 7 d\u00edas"],
  [30, "\u00daltimos 30 d\u00edas"],
]);

const numberFormatter = new Intl.NumberFormat("es-MX", {
  maximumFractionDigits: 0,
});

const currencyFormatter = new Intl.NumberFormat("es-MX", {
  style: "currency",
  currency: "MXN",
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const state = {
  rows: [],
  hasRangeData: false,
  selectedDays: 30,
  minVentas: 0,
};

const els = {
  filters: document.querySelector("#filters"),
  rangeGroup: document.querySelector("#rangeGroup"),
  minVentas: document.querySelector("#minVentas"),
  dataStatus: document.querySelector("#dataStatus"),
  notice: document.querySelector("#notice"),
  snapshotLabel: document.querySelector("#snapshotLabel"),
  kpiDevelopments: document.querySelector("#kpiDevelopments"),
  kpiSales: document.querySelector("#kpiSales"),
  kpiRevenue: document.querySelector("#kpiRevenue"),
  chartSummary: document.querySelector("#chartSummary"),
  chart: document.querySelector("#chart"),
  detailTable: document.querySelector("#detailTable"),
};

function toNumber(value) {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : 0;
}

function normalizeRow(row) {
  const source = row || {};
  const desarrollo = String(source.desarrollo || source.desarrollo_corto || "Sin desarrollo").trim();
  const totalVentas = toNumber(source.total_ventas);
  const precioVentaTotal = toNumber(source.precio_venta_total);
  const explicitAverage = toNumber(source.precio_venta_promedio);

  return {
    rangeDays: source.rango_dias === undefined || source.rango_dias === null ? null : toNumber(source.rango_dias),
    rangeLabel: source.rango_label || null,
    desarrollo: desarrollo || "Sin desarrollo",
    totalVentas,
    precioVentaTotal,
    precioVentaPromedio: explicitAverage || (totalVentas > 0 ? precioVentaTotal / totalVentas : 0),
  };
}

function setNotice(type, message) {
  els.notice.hidden = !message;
  els.notice.textContent = message || "";
  els.notice.className = type ? `notice ${type}` : "notice";
}

function setDataStatus(message) {
  if (els.dataStatus) {
    els.dataStatus.textContent = message;
  }
}

function setRangeAvailability() {
  const inputs = els.rangeGroup.querySelectorAll("input[name='rangeDays']");
  inputs.forEach((input) => {
    input.disabled = !state.hasRangeData;
  });

  if (state.hasRangeData) {
    els.rangeGroup.classList.remove("is-disabled");
    return;
  }

  els.rangeGroup.classList.add("is-disabled");
}

function getFilteredRows() {
  const rowsForRange = state.hasRangeData
    ? state.rows.filter((row) => row.rangeDays === state.selectedDays)
    : state.rows;

  return rowsForRange
    .filter((row) => row.totalVentas >= state.minVentas)
    .sort((a, b) => {
      if (b.totalVentas !== a.totalVentas) {
        return b.totalVentas - a.totalVentas;
      }
      return a.desarrollo.localeCompare(b.desarrollo, "es-MX");
    });
}

function renderKpis(rows) {
  const desarrollos = new Set(rows.map((row) => row.desarrollo)).size;
  const totalVentas = rows.reduce((sum, row) => sum + row.totalVentas, 0);
  const precioVentaTotal = rows.reduce((sum, row) => sum + row.precioVentaTotal, 0);

  els.kpiDevelopments.textContent = numberFormatter.format(desarrollos);
  els.kpiSales.textContent = numberFormatter.format(totalVentas);
  els.kpiRevenue.textContent = currencyFormatter.format(precioVentaTotal);
}

function renderChart(rows) {
  els.chart.replaceChildren();
  els.chartSummary.textContent = `${numberFormatter.format(rows.length)} desarrollos`;

  if (rows.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty-row";
    empty.textContent = "No hay ventas para los filtros seleccionados.";
    els.chart.append(empty);
    return;
  }

  const maxVentas = Math.max(...rows.map((row) => row.totalVentas), 1);
  const fragment = document.createDocumentFragment();

  rows.forEach((row) => {
    const width = Math.max((row.totalVentas / maxVentas) * 100, 2);
    const item = document.createElement("div");
    item.className = "bar-row";

    const label = document.createElement("div");
    label.className = "bar-label";
    label.title = row.desarrollo;
    label.textContent = row.desarrollo;

    const track = document.createElement("div");
    track.className = "bar-track";

    const fill = document.createElement("div");
    fill.className = "bar-fill";
    fill.style.setProperty("--bar-width", `${width}%`);
    track.append(fill);

    const value = document.createElement("div");
    value.className = "bar-value";
    value.textContent = numberFormatter.format(row.totalVentas);

    item.append(label, track, value);
    fragment.append(item);
  });

  els.chart.append(fragment);
}

function renderTable(rows) {
  els.detailTable.replaceChildren();

  if (rows.length === 0) {
    const tr = document.createElement("tr");
    tr.className = "empty-row";
    const td = document.createElement("td");
    td.colSpan = 4;
    td.textContent = "No hay ventas para los filtros seleccionados.";
    tr.append(td);
    els.detailTable.append(tr);
    return;
  }

  const fragment = document.createDocumentFragment();

  rows.forEach((row) => {
    const tr = document.createElement("tr");

    const desarrollo = document.createElement("td");
    desarrollo.textContent = row.desarrollo;

    const ventas = document.createElement("td");
    ventas.className = "numeric";
    ventas.textContent = numberFormatter.format(row.totalVentas);

    const total = document.createElement("td");
    total.className = "numeric";
    total.textContent = currencyFormatter.format(row.precioVentaTotal);

    const promedio = document.createElement("td");
    promedio.className = "numeric";
    promedio.textContent = currencyFormatter.format(row.precioVentaPromedio);

    tr.append(desarrollo, ventas, total, promedio);
    fragment.append(tr);
  });

  els.detailTable.append(fragment);
}

function updateSnapshotLabel() {
  const selectedRange = state.rows.find((row) => row.rangeDays === state.selectedDays && row.rangeLabel);
  const rangeText = state.hasRangeData
    ? selectedRange?.rangeLabel || RANGE_LABELS.get(state.selectedDays) || `${state.selectedDays} d\u00edas`
    : "Agregado disponible";
  els.snapshotLabel.textContent = rangeText;
}

function render() {
  const rows = getFilteredRows();

  renderKpis(rows);
  renderChart(rows);
  renderTable(rows);
  updateSnapshotLabel();

  if (rows.length === 0) {
    setNotice("warning", "No hay ventas para los filtros seleccionados.");
    return;
  }

  if (!state.hasRangeData) {
    setNotice("warning", "El archivo de datos actual no incluye rangos; se muestra el agregado disponible.");
    return;
  }

  setNotice("", "");
}

function bindEvents() {
  els.filters.addEventListener("input", (event) => {
    const target = event.target;

    if (target.name === "rangeDays") {
      state.selectedDays = toNumber(target.value);
    }

    if (target.name === "minVentas") {
      const value = Math.max(0, Math.floor(toNumber(target.value)));
      state.minVentas = value;
      target.value = value;
    }

    render();
  });
}

async function loadData() {
  setDataStatus("Cargando datos...");

  try {
    const response = await fetch(DATA_URL, { cache: "no-store" });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();

    if (!Array.isArray(data)) {
      throw new Error("El archivo JSON no contiene una lista de registros.");
    }

    state.rows = data.map(normalizeRow);
    state.hasRangeData = state.rows.some((row) => Number.isFinite(row.rangeDays) && row.rangeDays > 0);

    setRangeAvailability();
    setDataStatus(`${numberFormatter.format(state.rows.length)} registros cargados`);
    render();
  } catch (error) {
    setDataStatus("Error al cargar datos");
    setNotice("error", `Error al cargar los datos: ${error.message}`);
    renderKpis([]);
    renderChart([]);
    renderTable([]);
  }
}

bindEvents();
loadData();
*/

const DATA_URL = "data/ventas_por_desarrollo.json";
const THEME_KEY = "libera-dashboard-theme";

const RANGE_LABELS = new Map([
  [1, "\u00daltimo d\u00eda"],
  [7, "\u00daltimos 7 d\u00edas"],
  [30, "\u00daltimos 30 d\u00edas"],
]);

const numberFormatter = new Intl.NumberFormat("es-MX", {
  maximumFractionDigits: 0,
});

const currencyFormatter = new Intl.NumberFormat("es-MX", {
  style: "currency",
  currency: "MXN",
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const state = {
  rows: [],
  hasRangeData: false,
  selectedDays: 30,
  minVentas: 0,
  theme: "dark",
};

const els = {
  body: document.body,
  rangeDays: document.querySelector("#rangeDays"),
  minVentas: document.querySelector("#minVentas"),
  decrementMin: document.querySelector("#decrementMin"),
  incrementMin: document.querySelector("#incrementMin"),
  dataStatus: document.querySelector("#dataStatus"),
  notice: document.querySelector("#notice"),
  snapshotLabel: document.querySelector("#snapshotLabel"),
  themeToggle: document.querySelector("#themeToggle"),
  themeToggleText: document.querySelector("#themeToggleText"),
  themeToggleIcon: document.querySelector(".theme-toggle-icon"),
  metricsSection: document.querySelector(".metrics"),
  kpiDevelopments: document.querySelector("#kpiDevelopments"),
  kpiSales: document.querySelector("#kpiSales"),
  kpiRevenue: document.querySelector("#kpiRevenue"),
  chartSection: document.querySelector(".chart-section"),
  detailSection: document.querySelector(".detail-section"),
  chartSummary: document.querySelector("#chartSummary"),
  chart: document.querySelector("#chart"),
  detailTable: document.querySelector("#detailTable"),
};

function toNumber(value) {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : 0;
}

function normalizeRow(row) {
  const source = row || {};
  const desarrollo = String(source.desarrollo || source.desarrollo_corto || "Sin desarrollo").trim();
  const totalVentas = toNumber(source.total_ventas);
  const precioVentaTotal = toNumber(source.precio_venta_total);
  const explicitAverage = toNumber(source.precio_venta_promedio);

  return {
    rangeDays: source.rango_dias === undefined || source.rango_dias === null ? null : toNumber(source.rango_dias),
    rangeLabel: source.rango_label || null,
    desarrollo: desarrollo || "Sin desarrollo",
    totalVentas,
    precioVentaTotal,
    precioVentaPromedio: explicitAverage || (totalVentas > 0 ? precioVentaTotal / totalVentas : 0),
  };
}

function setNotice(type, message) {
  els.notice.hidden = !message;
  els.notice.className = type ? `notice ${type}` : "notice";
  els.notice.replaceChildren();

  if (!message) {
    return;
  }

  els.notice.textContent = message;
}

function setDataStatus(message) {
  if (els.dataStatus) {
    els.dataStatus.textContent = message;
  }
}

function setTheme(theme) {
  state.theme = theme === "light" ? "light" : "dark";
  els.body.dataset.theme = state.theme;
  localStorage.setItem(THEME_KEY, state.theme);

  const isDark = state.theme === "dark";
  els.themeToggleText.textContent = isDark ? "Modo claro" : "Modo oscuro";
  els.themeToggleIcon.textContent = isDark ? "\u2600" : "\u263e";
}

function initializeTheme() {
  setTheme(localStorage.getItem(THEME_KEY) || "dark");
}

function setMinVentas(value) {
  const safeValue = Math.max(0, Math.floor(toNumber(value)));
  state.minVentas = safeValue;
  els.minVentas.value = safeValue;
  render();
}

function getFilteredRows() {
  const rowsForRange = state.hasRangeData
    ? state.rows.filter((row) => row.rangeDays === state.selectedDays)
    : state.rows;

  return rowsForRange
    .filter((row) => row.totalVentas >= state.minVentas)
    .sort((a, b) => {
      if (b.totalVentas !== a.totalVentas) {
        return b.totalVentas - a.totalVentas;
      }
      return a.desarrollo.localeCompare(b.desarrollo, "es-MX");
    });
}

function renderKpis(rows) {
  const desarrollos = new Set(rows.map((row) => row.desarrollo)).size;
  const totalVentas = rows.reduce((sum, row) => sum + row.totalVentas, 0);
  const precioVentaTotal = rows.reduce((sum, row) => sum + row.precioVentaTotal, 0);

  els.kpiDevelopments.textContent = numberFormatter.format(desarrollos);
  els.kpiSales.textContent = numberFormatter.format(totalVentas);
  els.kpiRevenue.textContent = currencyFormatter.format(precioVentaTotal);
}

function getNiceMax(value) {
  if (value <= 0) {
    return 1;
  }

  const magnitude = 10 ** Math.floor(Math.log10(value));
  const normalized = value / magnitude;
  const rounded = normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10;
  return rounded * magnitude;
}

function getTicks(maxValue) {
  if (maxValue <= 5) {
    return Array.from({ length: maxValue + 1 }, (_, index) => maxValue - index);
  }

  const targetSteps = 5;
  const rawStep = maxValue / targetSteps;
  const magnitude = 10 ** Math.floor(Math.log10(rawStep));
  const normalized = rawStep / magnitude;
  const niceStep = (normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10) * magnitude;
  const top = Math.ceil(maxValue / niceStep) * niceStep;
  const ticks = [];

  for (let value = top; value >= 0; value -= niceStep) {
    ticks.push(Math.round(value));
  }

  return [...new Set(ticks)];
}

function renderEmptyChart(message) {
  els.chart.replaceChildren();
  const empty = document.createElement("div");
  empty.className = "empty-state";
  empty.textContent = message;
  els.chart.append(empty);
}

function renderChart(rows) {
  els.chartSummary.textContent = `${numberFormatter.format(rows.length)} desarrollos`;

  if (rows.length === 0) {
    renderEmptyChart("No hay ventas para los filtros seleccionados.");
    return;
  }

  const maxVentas = getNiceMax(Math.max(...rows.map((row) => row.totalVentas), 1));
  const chartWidth = Math.max(780, rows.length * 128 + 72);
  const canvas = document.createElement("div");
  const yAxis = document.createElement("div");
  const plotArea = document.createElement("div");
  const bars = document.createElement("div");

  canvas.className = "chart-canvas";
  canvas.style.setProperty("--chart-width", `${chartWidth}px`);
  yAxis.className = "y-axis";
  plotArea.className = "plot-area";
  bars.className = "bars";

  getTicks(maxVentas).forEach((tick, index, ticks) => {
    const label = document.createElement("span");
    const line = document.createElement("span");
    const top = `${(index / (ticks.length - 1)) * 100}%`;

    label.textContent = numberFormatter.format(tick);
    line.className = "grid-line";
    line.style.top = top;

    yAxis.append(label);
    plotArea.append(line);
  });

  rows.forEach((row) => {
    const item = document.createElement("div");
    const column = document.createElement("div");
    const value = document.createElement("span");
    const bar = document.createElement("div");
    const label = document.createElement("div");
    const height = row.totalVentas > 0 ? Math.max((row.totalVentas / maxVentas) * 100, 0.8) : 0;

    item.className = "bar-item";
    column.className = "bar-column";
    value.className = "bar-value";
    bar.className = "bar";
    label.className = "x-label";

    item.title = `${row.desarrollo}: ${numberFormatter.format(row.totalVentas)} ventas`;
    item.style.setProperty("--bar-height", `${height}%`);
    value.textContent = numberFormatter.format(row.totalVentas);
    label.textContent = row.desarrollo;

    column.append(value, bar);
    item.append(column, label);
    bars.append(item);
  });

  plotArea.append(bars);
  canvas.append(yAxis, plotArea);
  els.chart.replaceChildren(canvas);
}

function renderTable(rows) {
  els.detailTable.replaceChildren();

  if (rows.length === 0) {
    const tr = document.createElement("tr");
    tr.className = "empty-row";
    const td = document.createElement("td");
    td.colSpan = 4;
    td.textContent = "No hay ventas para los filtros seleccionados.";
    tr.append(td);
    els.detailTable.append(tr);
    return;
  }

  const fragment = document.createDocumentFragment();

  rows.forEach((row) => {
    const tr = document.createElement("tr");

    const desarrollo = document.createElement("td");
    desarrollo.textContent = row.desarrollo;

    const ventas = document.createElement("td");
    ventas.className = "numeric";
    ventas.textContent = numberFormatter.format(row.totalVentas);

    const total = document.createElement("td");
    total.className = "numeric";
    total.textContent = currencyFormatter.format(row.precioVentaTotal);

    const promedio = document.createElement("td");
    promedio.className = "numeric";
    promedio.textContent = currencyFormatter.format(row.precioVentaPromedio);

    tr.append(desarrollo, ventas, total, promedio);
    fragment.append(tr);
  });

  els.detailTable.append(fragment);
}

function updateSnapshotLabel() {
  const selectedRange = state.rows.find((row) => row.rangeDays === state.selectedDays && row.rangeLabel);
  const rangeText = state.hasRangeData
    ? selectedRange?.rangeLabel || RANGE_LABELS.get(state.selectedDays) || `${state.selectedDays} d\u00edas`
    : "Agregado disponible";
  els.snapshotLabel.textContent = rangeText;
}

function updateNotice(rows) {
  if (rows.length === 0) {
    setNotice("empty", "No hay ventas para los filtros seleccionados.");
    return;
  }

  if (!state.hasRangeData) {
    setNotice("warning", "Regenera datos con dashboard_html/export_data.py para activar el filtro de rango.");
    return;
  }

  setNotice("", "");
}

function setResultsVisibility(isVisible) {
  els.body.classList.toggle("is-empty-state", !isVisible);

  [els.metricsSection, els.chartSection, els.detailSection].forEach((section) => {
    if (!section) {
      return;
    }

    section.hidden = !isVisible;
    section.classList.toggle("is-hidden", !isVisible);
    section.style.display = isVisible ? "" : "none";
  });
}

function render() {
  const rows = getFilteredRows();

  renderKpis(rows);
  updateSnapshotLabel();

  if (rows.length === 0) {
    setResultsVisibility(false);
    updateNotice(rows);
    return;
  }

  setResultsVisibility(true);
  renderChart(rows);
  renderTable(rows);
  updateNotice(rows);
}

function bindEvents() {
  els.rangeDays.addEventListener("change", (event) => {
    state.selectedDays = toNumber(event.target.value);
    render();
  });

  els.minVentas.addEventListener("input", (event) => {
    setMinVentas(event.target.value);
  });

  els.decrementMin.addEventListener("click", () => {
    setMinVentas(state.minVentas - 1);
  });

  els.incrementMin.addEventListener("click", () => {
    setMinVentas(state.minVentas + 1);
  });

  els.themeToggle.addEventListener("click", () => {
    setTheme(state.theme === "dark" ? "light" : "dark");
  });
}

async function loadData() {
  setDataStatus("Cargando datos...");

  try {
    const response = await fetch(DATA_URL, { cache: "no-store" });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();

    if (!Array.isArray(data)) {
      throw new Error("El archivo JSON no contiene una lista de registros.");
    }

    state.rows = data.map(normalizeRow);
    state.hasRangeData = state.rows.some((row) => Number.isFinite(row.rangeDays) && row.rangeDays > 0);

    setDataStatus(`${numberFormatter.format(state.rows.length)} registros cargados`);
    render();
  } catch (error) {
    setDataStatus("Error al cargar datos");
    setNotice("error", `Error al cargar los datos: ${error.message}`);
    setResultsVisibility(false);
    renderKpis([]);
  }
}

if (false) {
  initializeTheme();
  bindEvents();
  loadData();
}

(() => {
  const SALES_URL = "data/ventas_por_desarrollo.json";
  const DASH_CRON_URL = "data/dash_cron.json";
  const THEME_KEY = "libera-dashboard-theme";

  const RANGE_LABELS = new Map([
    [1, "\u00daltimo d\u00eda"],
    [7, "\u00daltimos 7 d\u00edas"],
    [30, "\u00daltimos 30 d\u00edas"],
    [90, "\u00daltimos 3 meses"],
    [180, "\u00daltimos 6 meses"],
    [null, "Todo el tiempo"],
  ]);

  const numberFormatter = new Intl.NumberFormat("es-MX", { maximumFractionDigits: 0 });
  const currencyFormatter = new Intl.NumberFormat("es-MX", {
    style: "currency",
    currency: "MXN",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

  const state = {
    activeTab: "sales",
    salesRows: [],
    hasSalesRangeData: false,
    dashCronRanges: [],
    selectedDays: 30,
    minVentas: 0,
    theme: "dark",
  };

  const view = {
    body: document.body,
    tabs: [...document.querySelectorAll("[data-tab]")],
    panels: [...document.querySelectorAll("[data-panel]")],
    rangeDays: document.querySelector("#rangeDays"),
    minVentas: document.querySelector("#minVentas"),
    decrementMin: document.querySelector("#decrementMin"),
    incrementMin: document.querySelector("#incrementMin"),
    minVentasField: document.querySelector("#minVentasField"),
    notice: document.querySelector("#notice"),
    snapshotLabel: document.querySelector("#snapshotLabel"),
    themeToggle: document.querySelector("#themeToggle"),
    themeToggleText: document.querySelector("#themeToggleText"),
    themeToggleIcon: document.querySelector(".theme-toggle-icon"),
    salesMetrics: document.querySelector("#salesMetrics"),
    salesChartSection: document.querySelector("#salesChartSection"),
    salesDetailSection: document.querySelector("#salesDetailSection"),
    kpiDevelopments: document.querySelector("#kpiDevelopments"),
    kpiSales: document.querySelector("#kpiSales"),
    kpiRevenue: document.querySelector("#kpiRevenue"),
    chartSummary: document.querySelector("#chartSummary"),
    chart: document.querySelector("#chart"),
    detailTable: document.querySelector("#detailTable"),
    dashMetrics: document.querySelector("#dashMetrics"),
    dashCronContent: document.querySelector("#dashCronContent"),
    dashTotalVentas: document.querySelector("#dashTotalVentas"),
    dashPrecioVentaTotal: document.querySelector("#dashPrecioVentaTotal"),
    dashTotalCobrado: document.querySelector("#dashTotalCobrado"),
    dashTotalVencido: document.querySelector("#dashTotalVencido"),
    dashSaldoTotal: document.querySelector("#dashSaldoTotal"),
    dashUnidadesVencido: document.querySelector("#dashUnidadesVencido"),
    dashStatusUnidadChart: document.querySelector("#dashStatusUnidadChart"),
    dashStatusVentaChart: document.querySelector("#dashStatusVentaChart"),
    dashGrupoChart: document.querySelector("#dashGrupoChart"),
    dashStatusUnidadTable: document.querySelector("#dashStatusUnidadTable"),
    dashStatusVentaTable: document.querySelector("#dashStatusVentaTable"),
    dashGrupoTable: document.querySelector("#dashGrupoTable"),
  };

  function toNumber(value) {
    const numeric = Number(value);
    return Number.isFinite(numeric) ? numeric : 0;
  }

  function parseRangeValue(value) {
    return value === "all" ? null : toNumber(value);
  }

  function rangeMatches(left, right) {
    return left === right || (left === null && right === null);
  }

  function rangeLabel(days) {
    return RANGE_LABELS.get(days) || `${days} d\u00edas`;
  }

  function setNotice(type, message) {
    view.notice.hidden = !message;
    view.notice.className = type ? `notice ${type}` : "notice";
    view.notice.textContent = message || "";
  }

  function setSectionVisible(section, isVisible) {
    if (!section) {
      return;
    }

    section.hidden = !isVisible;
    section.classList.toggle("is-hidden", !isVisible);
    section.style.display = isVisible ? "" : "none";
  }

  function setTheme(theme) {
    state.theme = theme === "light" ? "light" : "dark";
    view.body.dataset.theme = state.theme;
    localStorage.setItem(THEME_KEY, state.theme);

    const isDark = state.theme === "dark";
    view.themeToggleText.textContent = isDark ? "Modo claro" : "Modo oscuro";
    view.themeToggleIcon.textContent = isDark ? "\u2600" : "\u263e";
  }

  function normalizeSalesRow(row) {
    const source = row || {};
    const desarrollo = String(source.desarrollo || source.desarrollo_corto || "Sin desarrollo").trim();
    const totalVentas = toNumber(source.total_ventas);
    const precioVentaTotal = toNumber(source.precio_venta_total);
    const explicitAverage = toNumber(source.precio_venta_promedio);

    return {
      rangeDays: source.rango_dias === undefined ? null : source.rango_dias,
      rangeLabel: source.rango_label || null,
      desarrollo: desarrollo || "Sin desarrollo",
      totalVentas,
      precioVentaTotal,
      precioVentaPromedio: explicitAverage || (totalVentas > 0 ? precioVentaTotal / totalVentas : 0),
    };
  }

  function normalizeCountRow(row, labelKey) {
    const source = row || {};
    return {
      label: String(source[labelKey] || source.label || "SIN VALOR"),
      cantidad: toNumber(source.cantidad),
    };
  }

  function normalizeDashRange(range) {
    const source = range || {};
    const rangeDays = source.rango_dias === undefined ? null : source.rango_dias;

    return {
      rangeDays,
      rangeLabel: source.rango_label || rangeLabel(rangeDays),
      kpis: source.kpis || {},
      statusUnidad: (source.status_unidad || []).map((row) => normalizeCountRow(row, "status_unidad")),
      statusVenta: (source.status_venta || []).map((row) => normalizeCountRow(row, "status_venta")),
      grupo: (source.grupo || []).map((row) => normalizeCountRow(row, "grupo")),
    };
  }

  async function fetchJson(url, fallback) {
    const response = await fetch(url, { cache: "no-store" });
    return response.ok ? response.json() : fallback;
  }

  function getFilteredSalesRows() {
    const rowsForRange = state.hasSalesRangeData
      ? state.salesRows.filter((row) => rangeMatches(row.rangeDays, state.selectedDays))
      : state.salesRows;

    return rowsForRange
      .filter((row) => row.totalVentas >= state.minVentas)
      .sort((a, b) => {
        if (b.totalVentas !== a.totalVentas) {
          return b.totalVentas - a.totalVentas;
        }

        return a.desarrollo.localeCompare(b.desarrollo, "es-MX");
      });
  }

  function getSelectedDashRange() {
    return state.dashCronRanges.find((range) => rangeMatches(range.rangeDays, state.selectedDays)) || null;
  }

  function renderSalesKpis(rows) {
    const desarrollos = new Set(rows.map((row) => row.desarrollo)).size;
    const totalVentas = rows.reduce((sum, row) => sum + row.totalVentas, 0);
    const precioVentaTotal = rows.reduce((sum, row) => sum + row.precioVentaTotal, 0);

    view.kpiDevelopments.textContent = numberFormatter.format(desarrollos);
    view.kpiSales.textContent = numberFormatter.format(totalVentas);
    view.kpiRevenue.textContent = currencyFormatter.format(precioVentaTotal);
  }

  function getNiceMax(value) {
    if (value <= 0) {
      return 1;
    }

    const magnitude = 10 ** Math.floor(Math.log10(value));
    const normalized = value / magnitude;
    const rounded = normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10;
    return rounded * magnitude;
  }

  function getTicks(maxValue) {
    if (maxValue <= 5) {
      return Array.from({ length: maxValue + 1 }, (_, index) => maxValue - index);
    }

    const targetSteps = 5;
    const rawStep = maxValue / targetSteps;
    const magnitude = 10 ** Math.floor(Math.log10(rawStep));
    const normalized = rawStep / magnitude;
    const niceStep = (normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10) * magnitude;
    const top = Math.ceil(maxValue / niceStep) * niceStep;
    const ticks = [];

    for (let value = top; value >= 0; value -= niceStep) {
      ticks.push(Math.round(value));
    }

    return [...new Set(ticks)];
  }

  function renderSalesChart(rows) {
    view.chartSummary.textContent = `${numberFormatter.format(rows.length)} desarrollos`;

    const maxVentas = getNiceMax(Math.max(...rows.map((row) => row.totalVentas), 1));
    const chartWidth = Math.max(780, rows.length * 128 + 72);
    const canvas = document.createElement("div");
    const yAxis = document.createElement("div");
    const plotArea = document.createElement("div");
    const bars = document.createElement("div");

    canvas.className = "chart-canvas";
    canvas.style.setProperty("--chart-width", `${chartWidth}px`);
    yAxis.className = "y-axis";
    plotArea.className = "plot-area";
    bars.className = "bars";

    getTicks(maxVentas).forEach((tick, index, ticks) => {
      const label = document.createElement("span");
      const line = document.createElement("span");
      const top = `${(index / (ticks.length - 1)) * 100}%`;

      label.textContent = numberFormatter.format(tick);
      line.className = "grid-line";
      line.style.top = top;

      yAxis.append(label);
      plotArea.append(line);
    });

    rows.forEach((row) => {
      const item = document.createElement("div");
      const column = document.createElement("div");
      const value = document.createElement("span");
      const bar = document.createElement("div");
      const label = document.createElement("div");
      const height = row.totalVentas > 0 ? Math.max((row.totalVentas / maxVentas) * 100, 0.8) : 0;

      item.className = "bar-item";
      column.className = "bar-column";
      value.className = "bar-value";
      bar.className = "bar";
      label.className = "x-label";

      item.title = `${row.desarrollo}: ${numberFormatter.format(row.totalVentas)} ventas`;
      item.style.setProperty("--bar-height", `${height}%`);
      value.textContent = numberFormatter.format(row.totalVentas);
      label.textContent = row.desarrollo;

      column.append(value, bar);
      item.append(column, label);
      bars.append(item);
    });

    plotArea.append(bars);
    canvas.append(yAxis, plotArea);
    view.chart.replaceChildren(canvas);
  }

  function renderSalesTable(rows) {
    view.detailTable.replaceChildren();

    const fragment = document.createDocumentFragment();

    rows.forEach((row) => {
      const tr = document.createElement("tr");
      const desarrollo = document.createElement("td");
      const ventas = document.createElement("td");
      const total = document.createElement("td");
      const promedio = document.createElement("td");

      desarrollo.textContent = row.desarrollo;
      ventas.className = "numeric";
      ventas.textContent = numberFormatter.format(row.totalVentas);
      total.className = "numeric";
      total.textContent = currencyFormatter.format(row.precioVentaTotal);
      promedio.className = "numeric";
      promedio.textContent = currencyFormatter.format(row.precioVentaPromedio);

      tr.append(desarrollo, ventas, total, promedio);
      fragment.append(tr);
    });

    view.detailTable.append(fragment);
  }

  function renderMiniBars(container, rows) {
    container.replaceChildren();

    if (rows.length === 0) {
      const empty = document.createElement("p");
      empty.className = "mini-empty";
      empty.textContent = "No hay datos disponibles.";
      container.append(empty);
      return;
    }

    const maxCantidad = Math.max(...rows.map((row) => row.cantidad), 1);
    const fragment = document.createDocumentFragment();

    rows.forEach((row) => {
      const item = document.createElement("div");
      const label = document.createElement("span");
      const track = document.createElement("div");
      const bar = document.createElement("div");
      const value = document.createElement("span");
      const width = Math.max((row.cantidad / maxCantidad) * 100, 1);

      item.className = "mini-bar";
      label.className = "mini-bar-label";
      track.className = "mini-bar-track";
      bar.className = "mini-bar-fill";
      value.className = "mini-bar-value";

      label.textContent = row.label;
      bar.style.width = `${width}%`;
      value.textContent = numberFormatter.format(row.cantidad);

      track.append(bar);
      item.append(label, track, value);
      fragment.append(item);
    });

    container.append(fragment);
  }

  function renderCountTable(tbody, rows) {
    tbody.replaceChildren();

    const fragment = document.createDocumentFragment();

    rows.forEach((row) => {
      const tr = document.createElement("tr");
      const label = document.createElement("td");
      const cantidad = document.createElement("td");

      label.textContent = row.label;
      cantidad.className = "numeric";
      cantidad.textContent = numberFormatter.format(row.cantidad);

      tr.append(label, cantidad);
      fragment.append(tr);
    });

    tbody.append(fragment);
  }

  function renderDashCron(range) {
    const kpis = range.kpis || {};

    view.dashTotalVentas.textContent = numberFormatter.format(toNumber(kpis.total_ventas));
    view.dashPrecioVentaTotal.textContent = currencyFormatter.format(toNumber(kpis.precio_venta_total));
    view.dashTotalCobrado.textContent = currencyFormatter.format(toNumber(kpis.total_cobrado));
    view.dashTotalVencido.textContent = currencyFormatter.format(toNumber(kpis.total_vencido));
    view.dashSaldoTotal.textContent = currencyFormatter.format(toNumber(kpis.saldo_total));
    view.dashUnidadesVencido.textContent = numberFormatter.format(toNumber(kpis.unidades_con_vencido));

    renderMiniBars(view.dashStatusUnidadChart, range.statusUnidad);
    renderMiniBars(view.dashStatusVentaChart, range.statusVenta);
    renderMiniBars(view.dashGrupoChart, range.grupo);
    renderCountTable(view.dashStatusUnidadTable, range.statusUnidad);
    renderCountTable(view.dashStatusVentaTable, range.statusVenta);
    renderCountTable(view.dashGrupoTable, range.grupo);
  }

  function setActiveTab(tab) {
    state.activeTab = tab;

    view.tabs.forEach((button) => {
      const isActive = button.dataset.tab === tab;
      button.classList.toggle("is-active", isActive);
      button.setAttribute("aria-selected", String(isActive));
    });

    view.panels.forEach((panel) => {
      const isActive = panel.dataset.panel === tab;
      panel.hidden = !isActive;
      panel.classList.toggle("is-active", isActive);
    });

    view.minVentasField.hidden = tab !== "sales";
    view.minVentasField.classList.toggle("is-hidden", tab !== "sales");
    view.minVentasField.style.display = tab === "sales" ? "" : "none";
    render();
  }

  function setSalesVisibility(isVisible) {
    [view.salesMetrics, view.salesChartSection, view.salesDetailSection].forEach((section) => {
      setSectionVisible(section, isVisible);
    });
  }

  function setDashVisibility(isVisible) {
    [view.dashMetrics, view.dashCronContent].forEach((section) => {
      setSectionVisible(section, isVisible);
    });
  }

  function renderSalesTab() {
    const rows = getFilteredSalesRows();

    setDashVisibility(false);

    if (rows.length === 0) {
      view.body.classList.add("is-empty-state");
      setSalesVisibility(false);
      setNotice("empty", "No hay ventas para los filtros seleccionados.");
      return;
    }

    view.body.classList.remove("is-empty-state");
    setSalesVisibility(true);
    renderSalesKpis(rows);
    renderSalesChart(rows);
    renderSalesTable(rows);

    if (!state.hasSalesRangeData) {
      setNotice("warning", "Regenera datos con dashboard_html/export_data.py para activar el filtro de rango.");
      return;
    }

    setNotice("", "");
  }

  function renderDashCronTab() {
    const selectedRange = getSelectedDashRange();

    setSalesVisibility(false);

    if (!selectedRange) {
      view.body.classList.add("is-empty-state");
      setDashVisibility(false);
      setNotice("empty", "No hay datos de mart_dash_cron disponibles.");
      return;
    }

    view.body.classList.remove("is-empty-state");
    setDashVisibility(true);
    renderDashCron(selectedRange);
    setNotice("", "");
  }

  function render() {
    view.snapshotLabel.textContent = rangeLabel(state.selectedDays);

    if (state.activeTab === "sales") {
      renderSalesTab();
      return;
    }

    renderDashCronTab();
  }

  function setMinVentas(value) {
    const safeValue = Math.max(0, Math.floor(toNumber(value)));
    state.minVentas = safeValue;
    view.minVentas.value = safeValue;
    render();
  }

  function bindNewEvents() {
    view.tabs.forEach((button) => {
      button.addEventListener("click", () => setActiveTab(button.dataset.tab));
    });

    view.rangeDays.addEventListener("change", (event) => {
      state.selectedDays = parseRangeValue(event.target.value);
      render();
    });

    view.minVentas.addEventListener("input", (event) => {
      setMinVentas(event.target.value);
    });

    view.decrementMin.addEventListener("click", () => {
      setMinVentas(state.minVentas - 1);
    });

    view.incrementMin.addEventListener("click", () => {
      setMinVentas(state.minVentas + 1);
    });

    view.themeToggle.addEventListener("click", () => {
      setTheme(state.theme === "dark" ? "light" : "dark");
    });
  }

  async function loadNewData() {
    const [salesData, dashCronData] = await Promise.all([
      fetchJson(SALES_URL, []),
      fetchJson(DASH_CRON_URL, { ranges: [] }),
    ]);

    state.salesRows = Array.isArray(salesData) ? salesData.map(normalizeSalesRow) : [];
    state.hasSalesRangeData = state.salesRows.some((row) => row.rangeLabel || row.rangeDays !== null);

    const ranges = Array.isArray(dashCronData?.ranges) ? dashCronData.ranges : [];
    state.dashCronRanges = ranges.map(normalizeDashRange);

    render();
  }

  setTheme(localStorage.getItem(THEME_KEY) || "dark");
  bindNewEvents();
  loadNewData().catch((error) => {
    setNotice("error", `Error al cargar los datos: ${error.message}`);
    setSalesVisibility(false);
    setDashVisibility(false);
  });
})();
