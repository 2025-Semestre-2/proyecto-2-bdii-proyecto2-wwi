import React, { useEffect, useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { api } from "../helper/api";
import "../css/Clientes.css";
import "../css/ClienteDetalle.css";
import {
  FaArrowLeft,
  FaBoxOpen,
  FaBoxes,
  FaWeightHanging,
  FaDollarSign,
  FaTruck,
  FaTag,
} from "react-icons/fa";

export default function InventarioDetalle() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const d = await api.getItem(id);
        const fixed = d?.recordsets
          ? {
              general: d.recordsets[0]?.[0] || null,
              holdings: d.recordsets[1]?.[0] || null,
              proveedor: d.recordsets[2]?.[0] || null,
            }
          : d;
        setData(fixed);
      } catch (err) {
        console.error("Error cargando producto:", err);
      } finally {
        setLoading(false);
      }
    })();
  }, [id]);

  if (loading)
    return (
      <div className="clientes-page">
        <p className="loading">Cargando...</p>
      </div>
    );

  if (!data || !data.general)
    return (
      <div className="clientes-page">
        <section className="detail-wrap">
          <div className="detail-head">
            <button className="btn ghost" onClick={() => navigate("/inventario")}>
              <FaArrowLeft /> Volver
            </button>
            <h2 className="detail-title">Detalle de Producto</h2>
          </div>
          <div className="alert">Producto no encontrado</div>
        </section>
      </div>
    );

  const g = data.general;
  const h = data.holdings || {};
  const p = data.proveedor || {};

  return (
    <div className="clientes-page">

      <section className="detail-wrap">
        <div className="detail-head">
          <button className="btn ghost" onClick={() => navigate("/inventario")}>
            <FaArrowLeft /> Volver
          </button>
          <h2 className="detail-title">{g.StockItemName}</h2>
        </div>

        {/* --- BLOQUE 1: ENCABEZADO --- */}
        <article className="card card-block" style={{ gridColumn: "1 / span 2" }}>
          <div className="card-header">
            <FaBoxOpen /> Resumen del Producto
          </div>
          <div className="kv-grid">
            <div className="kv"><span className="k">Marca:</span><span className="v">{g.Brand || "—"}</span></div>
            <div className="kv"><span className="k">Talla / Tamaño:</span><span className="v">{g.Size || "—"}</span></div>
            <div className="kv"><span className="k">Color:</span><span className="v">{g.ColorName || "—"}</span></div>
            <div className="kv"><span className="k">Proveedor:</span>
              <span className="v">
                {p.SupplierName ? (
                  p.SupplierID ? (
                    <Link to={`/proveedores/${p.SupplierID}`}>{p.SupplierName}</Link>
                  ) : (
                    p.SupplierName
                  )
                ) : "—"}
              </span>
            </div>
          </div>
        </article>

        {/* --- BLOQUE 2: FICHA TÉCNICA --- */}
        <article className="card card-block">
          <div className="card-header">
            <FaDollarSign /> Ficha técnica
          </div>
          <div className="kv-grid">
            <div className="kv"><span className="k">Unidad de empaquetamiento:</span><span className="v">{g.UnitPackage || "—"}</span></div>
            <div className="kv"><span className="k">Empaque externo:</span><span className="v">{g.OuterPackage || "—"}</span></div>
            <div className="kv"><span className="k">Cantidad por empaque:</span><span className="v">{g.QuantityPerOuter ?? "—"}</span></div>
            <div className="kv"><span className="k">Impuesto (%):</span><span className="v">{g.TaxRate != null ? g.TaxRate.toFixed(2) : "—"}</span></div>
            <div className="kv"><span className="k">Precio unitario:</span><span className="v">{g.RecommendedRetailPrice ? `$${g.RecommendedRetailPrice.toFixed(2)}` : "—"}</span></div>
            <div className="kv"><span className="k">Peso típico (kg):</span><span className="v">{g.TypicalWeightPerUnit ?? "—"}</span></div>
          </div>
        </article>

        {/* --- BLOQUE 3: INVENTARIO Y PALABRAS CLAVE --- */}
        <article className="card card-block">
          <div className="card-header">
            <FaBoxes /> Inventario
          </div>
          <div className="kv-grid">
            <div className="kv"><span className="k">Cantidad disponible:</span><span className="v">{h.QuantityOnHand ?? "—"}</span></div>
            <div className="kv"><span className="k">Ubicación (Bin):</span><span className="v">{h.BinLocation || "—"}</span></div>
          </div>
        </article>

        <article className="card card-block" style={{ gridColumn: "1 / span 2" }}>
          <div className="card-header">
            <FaTag /> Palabras clave
          </div>
          <div className="kv">
            <span className="v">{g.SearchDetails || "—"}</span>
          </div>
        </article>
      </section>
    </div>
  );
}
