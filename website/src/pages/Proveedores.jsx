import React, { useEffect, useMemo, useState } from "react";
import "../css/Clientes.css";
import { api } from "../helper/api";
import { FaSearch, FaSyncAlt, FaTimesCircle } from "react-icons/fa";
import { useNavigate } from "react-router-dom";

export default function Proveedores() {
    useEffect(() => {
      load("");
    }, []);
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [rawRows, setRawRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errMsg, setErrMsg] = useState("");

  const load = async (filtro) => {
    const value = typeof filtro === "string" ? filtro : search;
    setLoading(true);
    setErrMsg("");
    try {
      const data = await api.getProveedores(value.trim() || undefined);
      const rows = Array.isArray(data) ? data : (data?.rows || data?.recordset || []);
      setRawRows(Array.isArray(rows) ? rows : []);
    } catch (e) {
      console.error(e);
      setErrMsg("No se pudieron cargar los proveedores.");
      setRawRows([]);
    } finally {
      setLoading(false);
    }
  };

  // Eliminar búsqueda automática al escribir. Solo el botón 'Aplicar' dispara la búsqueda.

  // Mostrar los datos tal como vienen del backend
  const rows = rawRows;

  const onRestore = () => {
    setSearch("");
    load("");
  };

  return (
    <div className="clientes-page">
      <section className="clientes-hero">
        <div className="hero__copy">
          <h2>Proveedores</h2>
          <p>Consulte y filtre los proveedores registrados. Click en una fila para ver el detalle.</p>
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
                <th>Proveedor</th>
                <th>Categoría</th>
                <th>Método de entrega</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr
                  key={r.SupplierID || r.supplierid}
                  className="row"
                  onClick={() => navigate(`/proveedores/${r.SupplierID || r.supplierid}`)}
                >
                  <td className="strong">{(r.NombreProveedor || r.nombreproveedor) || "—"}</td>
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
