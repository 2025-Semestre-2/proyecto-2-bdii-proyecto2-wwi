import React, { useEffect, useState } from "react";
import "../css/Clientes.css";
import { api } from "../helper/api";
import { FaSearch, FaSyncAlt } from "react-icons/fa";
import { useNavigate } from "react-router-dom";

const fmtMoney = (n) =>
  Number(n ?? 0).toLocaleString(undefined, { style: "currency", currency: "USD" });
const fmtDate = (d) => (d ? new Date(d).toLocaleDateString() : "—");

export default function Ventas() {
  const navigate = useNavigate();

  const [client, setClient] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [min, setMin] = useState("");
  const [max, setMax] = useState("");
  const [limit, setLimit] = useState(50);
  const [total, setTotal] = useState(0);
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState("");
  const [page, setPage] = useState(1);

  const load = async (_page = 1, _limit = limit) => {
    setLoading(true);
    setErr("");
    try {
      const data = await api.getVentas({
        client: client.trim() || undefined,
        from: from || undefined,
        to: to || undefined,
        min: min !== "" ? min : undefined,
        max: max !== "" ? max : undefined,
        page: _page,
        limit: _limit,
      });
      setRows(Array.isArray(data?.rows) ? data.rows : []);
      setTotal(Number(data?.total ?? 0));
    } catch (e) {
      console.error(e);
      setRows([]);
      setTotal(0);
      setErr("No se pudieron cargar las ventas.");
    } finally {
      setLoading(false);
    }
  };

  // Carga inicial solo al montar
  useEffect(() => {
    load(1, limit);
  }, []);

  // Cambiar página solo al hacer clic en paginador
  const goToPage = (newPage) => {
    setPage(newPage);
    load(newPage, limit);
  };

  // Cambiar límite solo al seleccionar en el select
  const changeLimit = (newLimit) => {
    setLimit(newLimit);
    setPage(1);
    load(1, newLimit);
  };

  // Aplicar filtros solo al dar clic en 'Aplicar' o Enter
  const applyFilters = () => {
    setPage(1);
    load(1, limit);
  };

  // Restaurar filtros y recargar todo
  const restore = () => {
    setClient("");
    setFrom("");
    setTo("");
    setMin("");
    setMax("");
    setPage(1);
    load(1, limit);
  };

  const totalPages = Math.max(1, Math.ceil(total / limit));
  const canPrev = page > 1;
  const canNext = page < totalPages;
  const fromIdx = total === 0 ? 0 : (page - 1) * limit + 1;
  const toIdx = Math.min(page * limit, total);

  return (
    <div className="clientes-page">
      <section className="clientes-hero">
        <div className="hero__copy">
          <h2>Ventas</h2>
        </div>

        <div className="hero__filters filters-bar">
          {/* Izquierda: búsqueda */}
          <div className="filters-left">
            <div className="input-wrap">
              <FaSearch />
              <input
                placeholder="Cliente"
                value={client}
                onChange={(e) => setClient(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && applyFilters()}
              />
            </div>
          </div>

          {/* Derecha: fechas, montos, page size y acciones */}
          <div className="filters-right">
            <input
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && applyFilters()}
            />
            <input
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && applyFilters()}
            />

            <input
              type="number"
              step="0.01"
              placeholder="Mín"
              value={min}
              onChange={(e) => setMin(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && applyFilters()}
              style={{ width: 120 }}
            />
            <input
              type="number"
              step="0.01"
              placeholder="Máx"
              value={max}
              onChange={(e) => setMax(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && applyFilters()}
              style={{ width: 120 }}
            />

            <select
              value={limit}
              onChange={(e) => setLimit(parseInt(e.target.value, 10))}
              title="Resultados por página"
            >
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>

            <button className="btn primary" onClick={applyFilters} disabled={loading}>
              {loading ? "Cargando..." : "Aplicar"}
            </button>

            <button className="btn ghost" onClick={restore} title="Restaurar">
              <FaSyncAlt />
              <span>Restaurar</span>
            </button>
          </div>
        </div>


      </section>

      <section className="card clientes-table">
        {!!err && <div className="alert">{err}</div>}

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>N°</th>
                <th>Fecha</th>
                <th>Cliente</th>
                <th>Método entrega</th>
                <th className="right">Monto</th>
              </tr>
            </thead>
            <tbody>
              {rows.length ? (
                rows.map((r) => (
                  <tr
                    key={r.InvoiceID}
                    className="row"
                    onClick={() => navigate(`/ventas/${r.InvoiceID}`)}
                  >
                    <td className="strong">{r.InvoiceID}</td>
                    <td>{fmtDate(r.InvoiceDate)}</td>
                    <td>{r.CustomerName}</td>
                    <td>{r.DeliveryMethodName ?? "—"}</td>
                    <td className="right">{fmtMoney(r.Monto)}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="5" className="muted">
                    {loading ? "Cargando..." : "Sin resultados"}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="pager-modern">
          <span className="range">
            {fromIdx}-{toIdx} de {total}
          </span>

          <div className="pager-buttons">
            <button
              className="chip"
              onClick={() => setPage(1)}
              disabled={!canPrev}
              aria-label="Primera página"
            >
              ⏮
            </button>

            <button
              className="chip"
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={!canPrev}
              aria-label="Anterior"
            >
              ◀
            </button>

            <span className="page-indicator">
              Página <b>{page}</b> / {totalPages}
            </span>

            <button
              className="chip"
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={!canNext}
              aria-label="Siguiente"
            >
              ▶
            </button>

            <button
              className="chip"
              onClick={() => setPage(totalPages)}
              disabled={!canNext}
              aria-label="Última página"
            >
              ⏭
            </button>
          </div>
        </div>
      </section>
    </div>
  );
}
