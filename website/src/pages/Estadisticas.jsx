import React, { useEffect, useState } from "react";
import "../css/Estadisticas.css";          
import CafeHeader from "../components/Header";
import { api } from "../helper/api";
import { FaChartBar, FaSyncAlt } from "react-icons/fa";

const TABS = {
  COMPRAS: "COMPRAS",
  VENTAS: "VENTAS",
  TOP_PRODUCTOS: "TOP_PRODUCTOS",
  TOP_CLIENTES: "TOP_CLIENTES",
  TOP_PROVEEDORES: "TOP_PROVEEDORES",
};

const fmt = (n) => {
  if (n == null) return "—";
  const v = Number(n);
  if (Number.isNaN(v)) return n;
  return v.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};

export default function Estadisticas() {
    useEffect(() => {
      load();
    }, []);
  const [tab, setTab] = useState(TABS.COMPRAS);

  // filtros
  const [supplier, setSupplier] = useState("");
    // Removed automatic filtering and frontend filtering
    // useEffect(() => { load(TABS.COMPRAS); }, []);
    // useEffect(() => { load(tab); }, [tab]);
  const [cusCat, setCusCat] = useState("");
  const [year, setYear] = useState("");
  const [fy, setFy] = useState("");
  const [ty, setTy] = useState("");
  const [sucursal, setSucursal] = useState("");

  // data
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState("");

  const load = async (
    which = tab,
    filtro = {
      supplier,
      supCat,
      customer,
      cusCat,
      year,
      fy,
      ty,
      sucursal,
    }
  ) => {
    setLoading(true);
    setErr("");
    try {
      let data = [];
      if (which === TABS.COMPRAS) {
        data = await api.compras(filtro.supplier.trim() || undefined, filtro.supCat.trim() || undefined, filtro.sucursal || undefined);
      } else if (which === TABS.VENTAS) {
        data = await api.ventas(filtro.customer.trim() || undefined, filtro.cusCat.trim() || undefined, filtro.sucursal || undefined);
      } else if (which === TABS.TOP_PRODUCTOS) {
        data = await api.topProductos(filtro.year ? Number(filtro.year) : undefined, filtro.sucursal || undefined);
      } else if (which === TABS.TOP_CLIENTES) {
        data = await api.topClientes(filtro.fy || undefined, filtro.ty || undefined, filtro.sucursal || undefined);
      } else if (which === TABS.TOP_PROVEEDORES) {
        data = await api.topProveedores(filtro.fy || undefined, filtro.ty || undefined, filtro.sucursal || undefined);
      }
      setRows(Array.isArray(data) ? data : []);
    } catch (e) {
      console.error(e);
      setRows([]);
      setErr("No se pudieron cargar las estaddsticas.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(TABS.COMPRAS); }, []);
  useEffect(() => { load(tab); }, [tab]);

  const clearAndReload = () => {
    setSupplier("");
    setSupCat("");
    setCustomer("");
    setCusCat("");
    setYear("");
    setFy("");
    setTy("");
    setSucursal("");
    load(tab, {
      supplier: "",
      supCat: "",
      customer: "",
      cusCat: "",
      year: "",
      fy: "",
      ty: "",
      sucursal: "",
    });
  };

  const renderTableHead = () => {
    switch (tab) {
      case TABS.COMPRAS:
        return (
          <tr>
            <th>Proveedor</th>
            <th>Categoría</th>
            <th>Sucursal</th>
            <th className="right">Mínimo</th>
            <th className="right">Máximo</th>
            <th className="right">Promedio</th>
            <th className="right">Total</th>
          </tr>
        );
      case TABS.VENTAS:
        return (
          <tr>
            <th>Cliente</th>
            <th>Categoría</th>
            <th>Sucursal</th>
            <th className="right">Mínimo</th>
            <th className="right">Máximo</th>
            <th className="right">Promedio</th>
            <th className="right">Total</th>
          </tr>
        );
      case TABS.TOP_PRODUCTOS:
        return (
          <tr>
            <th className="right">Año</th>
            <th>Producto</th>
            <th>Sucursal</th>
            <th className="right">Ventas</th>
            <th className="right">Costo</th>
            <th className="right">Ganancia</th>
            <th className="right">Rank</th>
          </tr>
        );
      case TABS.TOP_CLIENTES:
        return (
          <tr>
            <th className="right">Año</th>
            <th>Cliente</th>
            <th>Sucursal</th>
            <th className="right"># Facturas</th>
            <th className="right">Monto total</th>
            <th className="right">Rank</th>
          </tr>
        );
      case TABS.TOP_PROVEEDORES:
        return (
          <tr>
            <th className="right">Año</th>
            <th>Proveedor</th>
            <th>Sucursal</th>
            <th className="right"># Órdenes</th>
            <th className="right">Monto total</th>
            <th className="right">Rank</th>
          </tr>
        );
      default:
        return null;
    }
  };

  const renderTableRow = (r, i) => {
    switch (tab) {
      case TABS.COMPRAS:
        return (
          <tr key={i}>
            <td>{r.SupplierName ?? "—"}</td>
            <td>{r.SupplierCategoryName ?? (r.SupplierName ? "Subtotal" : "Total general")}</td>
            <td>{r.Sucursal ?? "—"}</td>
            <td className="right">{fmt(r.monto_minimo)}</td>
            <td className="right">{fmt(r.monto_maximo)}</td>
            <td className="right">{fmt(r.monto_promedio)}</td>
            <td className="right">{fmt(r.monto_total)}</td>
          </tr>
        );
      case TABS.VENTAS:
        return (
          <tr key={i}>
            <td>{r.CustomerName ?? "—"}</td>
            <td>{r.StockGroupName ?? (r.CustomerName ? "Subtotal" : "Total general")}</td>
            <td>{r.Sucursal ?? "—"}</td>
            <td className="right">{fmt(r.monto_minimo)}</td>
            <td className="right">{fmt(r.monto_maximo)}</td>
            <td className="right">{fmt(r.monto_promedio)}</td>
            <td className="right">{fmt(r.monto_total)}</td>
          </tr>
        );
      case TABS.TOP_PRODUCTOS:
        return (
          <tr key={i}>
            <td className="right">{r.Year}</td>
            <td>{r.StockItemName}</td>
            <td>{r.Sucursal ?? "—"}</td>
            <td className="right">{fmt(r.SalesAmount)}</td>
            <td className="right">{fmt(r.CostAmount)}</td>
            <td className="right strong">{fmt(r.ProfitAmount)}</td>
            <td className="right">{r.rnk}</td>
          </tr>
        );
      case TABS.TOP_CLIENTES:
        return (
          <tr key={i}>
            <td className="right">{r.Year}</td>
            <td>{r.CustomerName}</td>
            <td>{r.Sucursal ?? "—"}</td>
            <td className="right">{r.InvoiceCount}</td>
            <td className="right">{fmt(r.TotalAmount)}</td>
            <td className="right">{r.rnk}</td>
          </tr>
        );
      case TABS.TOP_PROVEEDORES:
        return (
          <tr key={i}>
            <td className="right">{r.Year}</td>
            <td>{r.SupplierName}</td>
            <td>{r.Sucursal ?? "—"}</td>
            <td className="right">{r.OrderCount}</td>
            <td className="right">{fmt(r.TotalAmount)}</td>
            <td className="right">{r.rnk}</td>
          </tr>
        );
      default:
        return null;
    }
  };

  return (
    <div className="estadisticas-page">
      {/* Solo un header */}
      <section className="est-hero">
        <div className="est-title">
          <FaChartBar />
          <h2>Estadísticas</h2>
        </div>
        {/* Tabs */}
        <div className="est-tabs">
          <button className={`est-tab ${tab===TABS.COMPRAS ? "active":""}`} onClick={()=>setTab(TABS.COMPRAS)}>Compras</button>
          <button className={`est-tab ${tab===TABS.VENTAS ? "active":""}`} onClick={()=>setTab(TABS.VENTAS)}>Ventas</button>
          <button className={`est-tab ${tab===TABS.TOP_PRODUCTOS ? "active":""}`} onClick={()=>setTab(TABS.TOP_PRODUCTOS)}>Top productos</button>
          <button className={`est-tab ${tab===TABS.TOP_CLIENTES ? "active":""}`} onClick={()=>setTab(TABS.TOP_CLIENTES)}>Top clientes</button>
          <button className={`est-tab ${tab===TABS.TOP_PROVEEDORES ? "active":""}`} onClick={()=>setTab(TABS.TOP_PROVEEDORES)}>Top proveedores</button>
        </div>
        {/* Filtros por tab */}
        <section className="est-filters">
          <div className="input-wrap">
            <select value={sucursal} onChange={e => setSucursal(e.target.value)}>
              <option value="">Consolidado</option>
              <option value="San José">San José</option>
              <option value="Limón">Limón</option>
            </select>
          </div>
          {tab===TABS.COMPRAS && (
            <>
              <div className="input-wrap">
                <input
                  placeholder="Proveedor (texto libre)"
                  value={supplier}
                  onChange={(e)=>setSupplier(e.target.value)}
                  onKeyDown={(e)=>e.key==="Enter" && load()}
                />
              </div>
              <div className="input-wrap">
                <input
                  placeholder="Categoría proveedor (texto libre)"
                  value={supCat}
                  onChange={(e)=>setSupCat(e.target.value)}
                  onKeyDown={(e)=>e.key==="Enter" && load()}
                />
              </div>
            </>
          )}
          {tab===TABS.VENTAS && (
            <>
              <div className="input-wrap">
                <input
                  placeholder="Cliente (texto libre)"
                  value={customer}
                  onChange={(e)=>setCustomer(e.target.value)}
                  onKeyDown={(e)=>e.key==="Enter" && load()}
                />
              </div>
              <div className="input-wrap">
                <input
                  placeholder="Categoría (texto libre)"
                  value={cusCat}
                  onChange={(e)=>setCusCat(e.target.value)}
                  onKeyDown={(e)=>e.key==="Enter" && load()}
                />
              </div>
            </>
          )}
          {tab===TABS.TOP_PRODUCTOS && (
            <div className="input-wrap">
              <input
                type="number"
                min="1900"
                placeholder="Año (opcional)"
                value={year}
                onChange={(e)=>setYear(e.target.value)}
                onKeyDown={(e)=>e.key==="Enter" && load()}
              />
            </div>
          )}
          {(tab===TABS.TOP_CLIENTES || tab===TABS.TOP_PROVEEDORES) && (
            <>
              <div className="input-wrap">
                <input
                  type="number"
                  min="1900"
                  placeholder="Desde (año)"
                  value={fy}
                  onChange={(e)=>setFy(e.target.value)}
                  onKeyDown={(e)=>e.key==="Enter" && load()}
                />
              </div>
              <div className="input-wrap">
                <input
                  type="number"
                  min="1900"
                  placeholder="Hasta (año)"
                  value={ty}
                  onChange={(e)=>setTy(e.target.value)}
                  onKeyDown={(e)=>e.key==="Enter" && load()}
                />
              </div>
            </>
          )}
          <button className="btn primary" onClick={load} disabled={loading}>
            {loading ? "Cargando..." : "Aplicar"}
          </button>
          <button className="btn ghost" onClick={clearAndReload}>
            <FaSyncAlt /> <span>Restaurar</span>
          </button>
        </section>
      </section>
      <section className="card est-table">
        {!!err && <div className="alert">{err}</div>}
        <div className="table-wrap">
          <table>
            <thead>{renderTableHead()}</thead>
            <tbody>
              {rows.length
                ? rows.map(renderTableRow)
                : (
                  <tr>
                    <td className="muted" colSpan={7}>{loading ? "Cargando..." : "Sin resultados"}</td>
                  </tr>
                )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
