import React, { useEffect, useMemo, useState } from "react";
import "../css/Clientes.css";
import { api } from "../helper/api";
import { FaSearch, FaSyncAlt, FaTimesCircle } from "react-icons/fa";
import { useNavigate } from "react-router-dom";

function normalizarDetalleCliente(d) {
  if (!d) return null;

  if (d.general) return d.general;
  if (d.generales) return d.generales;
  if (d.cliente) return d.cliente;

  if (Array.isArray(d) && d.length > 0 && typeof d[0] === "object") return d[0];

  if (d.recordsets && Array.isArray(d.recordsets) && d.recordsets[0]?.[0]) {
    return d.recordsets[0][0];
  }
  if (d.recordset && Array.isArray(d.recordset) && d.recordset[0]) {
    return d.recordset[0];
  }

 
  if (typeof d === "object") return d;

  return null;
}

export default function Clientes() {
    useEffect(() => {
      load("");
    }, []);
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [rawRows, setRawRows] = useState([]);
  const [selectedId, setSelectedId] = useState(null);
  const [detail, setDetail] = useState(null);     
  const [loading, setLoading] = useState(false);
  const [errMsg, setErrMsg] = useState("");

  const load = async (filtro) => {
    const value = typeof filtro === "string" ? filtro : search;
    setLoading(true);
    setErrMsg("");
    try {
      const data = await api.getClientes(value.trim() || undefined);
      setRawRows(Array.isArray(data) ? data : (data?.rows || []));
    } catch (e) {
      console.error(e);
      setErrMsg("No se pudieron cargar los clientes.");
    } finally {
      setLoading(false);
    }
  };

  // Eliminar búsqueda automática al escribir. Solo el botón 'Aplicar' dispara la búsqueda.

  // Mostrar los datos tal como vienen del backend
  const rows = rawRows;

  const openDetail = async (row) => {
    setSelectedId(row.customerid);
    
    setDetail({ loading: true });
    try {
      const d = await api.getCliente(row.customerid);
      const g = normalizarDetalleCliente(d);
      if (!g) {
        console.warn("Detalle de cliente en formato inesperado:", d);
        setDetail({ error: "No se encontró detalle para este cliente." });
      } else {
        setDetail(g);
      }
    } catch (e) {
      console.error(e);
      setDetail({ error: "Error al cargar el detalle." });
    }
  };

  const closeDetail = () => {
    setDetail(null);
    setSelectedId(null);
  };

  const onRestore = () => {
    setSearch("");
    setSelectedId(null);
    setDetail(null);
    load("");
  };

  return (
    <div className="clientes-page">
      <section className="clientes-hero">
        <div className="hero__copy">
          <h2>Clientes</h2>
          <p>Consulte y filtre los clientes registrados. Click en una fila para ver el detalle.</p>
        </div>

        <div className="hero__filters">
          <div className="input-wrap">
            <FaSearch />
            <input
              placeholder="Buscar por nombre (texto libre, multi-palabra)"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && load()}
            />
            {search && (
              <button className="icon-clear" onClick={() => setSearch("")} title="Limpiar">
                <FaTimesCircle />
              </button>
            )}
          </div>

          <button className="btn primary" onClick={load} disabled={loading}>
            {loading ? "Cargando..." : "Aplicar"}
          </button>

          <button className="btn ghost" onClick={onRestore} title="Restaurar">
            <FaSyncAlt /><span>Restaurar</span>
          </button>
        </div>
      </section>

      <section className="card clientes-table">
        {!!errMsg && <div className="alert">{errMsg}</div>}

        <div className="chips" aria-hidden>
          {search.trim().split(/\s+/).filter(Boolean).map((t, i) => (
            <span key={i} className="chip">{t}</span>
          ))}
        </div>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Cliente</th>
                <th>Categoría</th>
                <th>Método de entrega</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr
                key={r.CustomerID || r.customerid}
                className="row"
                onClick={() => navigate(`/clientes/${r.CustomerID || r.customerid}`)}
                >

                  <td className="strong">{r.NombreCliente || r.nombrecliente}</td>
                  <td>{(r.Categoria || r.categoria) ? <span className="pill">{r.Categoria || r.categoria}</span> : "—"}</td>
                  <td>{(r.MetodoEntrega || r.metodoentrega) || "—"}</td>
                </tr>
              ))}
              {!rows.length && (
                <tr><td colSpan="3" className="muted">{loading ? "Cargando..." : "Sin resultados"}</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
