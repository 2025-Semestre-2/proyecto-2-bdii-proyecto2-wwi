import React, { useEffect, useState } from "react";
import "../css/Clientes.css";
import "../css/ClienteDetalle.css";
import { useParams, useNavigate, Link } from "react-router-dom";
import { api } from "../helper/api";
import { FaArrowLeft, FaReceipt, FaListUl, FaTruck } from "react-icons/fa";

const fmtMoney = (n) => {
  const v = Number(n);
  if (Number.isNaN(v)) return "—";
  return v.toLocaleString(undefined, { style: "currency", currency: "USD" });
};
const fmtDate = (d) => {
  try { return new Date(d).toLocaleDateString(); } catch { return d ?? "—"; }
};
const calcTotals = (lines = []) => {
  let subtotal = 0, impuesto = 0, total = 0;
  for (const l of lines) {
    const ext = Number(l.ExtendedPrice || 0);
    const tax = Number(l.TaxAmount || 0);
    subtotal += ext;
    impuesto += tax;
    total    += Number(l.TotalPorLinea ?? (ext + tax));
  }
  return { subtotal, impuesto, total };
};

export default function VentaDetalle() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const d = await api.getFactura(id); 
        const fixed = d?.recordsets
          ? { header: d.recordsets[0]?.[0] || null, lines: d.recordsets[1] || [] }
          : d;
        if (alive) setData(fixed);
      } catch {
        if (alive) setData(null);
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => { alive = false; };
  }, [id]);

  if (loading) {
    return (
      <div className="clientes-page">
        <p className="loading">Cargando...</p>
      </div>
    );
  }

  if (!data || !data.header) {
    return (
      <div className="clientes-page">
        <section className="detail-wrap">
          <div className="detail-head">
            <button className="btn ghost" onClick={() => navigate("/ventas")}>
              <FaArrowLeft /> Volver
            </button>
            <h2 className="detail-title">Detalle de factura</h2>
          </div>
          <div className="alert">Factura no encontrada</div>
        </section>
      </div>
    );
  }

  const h = data.header;
  const lines = data.lines || [];
  const totales = calcTotals(lines);

  return (
    <div className="clientes-page">

      <section className="detail-wrap">
        <div className="detail-head">
          <button className="btn ghost" onClick={() => navigate("/ventas")}>
            <FaArrowLeft /> Volver
          </button>
          <h2 className="detail-title">Factura {h.InvoiceNumber}</h2>
          <span />
        </div>

        <div className="detail-layout" style={{ gridTemplateColumns: "1fr 1fr", gap: 16 }}>
          {/* Encabezado */}
          <article className="card card-block">
            <div className="card-header"><FaReceipt /> Encabezado</div>
            <div className="kv"><span className="k">Número de factura:</span><span className="v">{h.InvoiceID}</span></div>
            <div className="kv alt">
              <span className="k">Cliente:</span>
              <span className="v">
                {h.CustomerID
                  ? <Link to={`/clientes/${h.CustomerID}`}>{h.CustomerName}</Link>
                  : (h.CustomerName || "—")}
              </span>
            </div>
            <div className="kv"><span className="k">Método de entrega:</span><span className="v">{h.DeliveryMethodName ?? "—"}</span></div>
            <div className="kv alt"><span className="k">Orden del cliente (PO):</span><span className="v">{h.CustomerPurchaseOrderNumber || "—"}</span></div>
            <div className="kv"><span className="k">Persona de contacto:</span><span className="v">{h.ContactPersonName || "—"}</span></div>
            <div className="kv alt"><span className="k">Vendedor:</span><span className="v">{h.SalespersonName || "—"}</span></div>
            <div className="kv"><span className="k">Fecha:</span><span className="v">{fmtDate(h.InvoiceDate)}</span></div>
            <div className="kv alt"><span className="k">Instrucciones de entrega:</span><span className="v">{h.DeliveryInstructions || "—"}</span></div>
          </article>

          {/* Totales */}
          <article className="card card-block">
            <div className="card-header"><FaListUl /> Totales</div>
            <div className="kv"><span className="k">Subtotal:</span><span className="v">{fmtMoney(totales.subtotal)}</span></div>
            <div className="kv alt"><span className="k">Impuesto:</span><span className="v">{fmtMoney(totales.impuesto)}</span></div>
            <div className="kv"><span className="k">Total:</span><span className="v strong">{fmtMoney(totales.total)}</span></div>
          </article>

          {/* Líneas */}
          <article className="card card-block" style={{ gridColumn: "1 / span 2" }}>
            <div className="card-header"><FaTruck /> Detalle de la factura</div>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Producto</th>
                    <th className="right">Cantidad</th>
                    <th className="right">Precio unitario</th>
                    <th className="right">Impuesto aplicado</th>
                    <th className="right">Monto del impuesto</th>
                    <th className="right">Total por línea</th>
                  </tr>
                </thead>
                <tbody>
                  {lines.map(l => (
                    <tr key={l.InvoiceLineID}>
                      <td>{l.InvoiceLineID}</td>
                      <td>
                        {l.StockItemID
                          ? <Link to={`/inventario/${l.StockItemID}`}>{l.StockItemName}</Link>
                          : l.StockItemName}
                      </td>
                      <td className="right">{l.Quantity}</td>
                      <td className="right">{fmtMoney(l.UnitPrice)}</td>
                      <td className="right">{(l.TaxRate ?? 0).toFixed(2)}%</td>
                      <td className="right">{fmtMoney(l.TaxAmount)}</td>
                      <td className="right">{fmtMoney(l.TotalPorLinea)}</td>
                    </tr>
                  ))}
                  {!lines.length && (
                    <tr><td colSpan="7" className="muted">Sin líneas</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </article>
        </div>
      </section>
    </div>
  );
}
