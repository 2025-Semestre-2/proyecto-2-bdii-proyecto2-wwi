import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { api } from "../helper/api";
import "../css/Clientes.css";       
import "../css/ClienteDetalle.css"; 
import { FaArrowLeft, FaPhoneAlt, FaGlobe, FaMapMarkerAlt, FaTruck, FaIdCard, FaUniversity } from "react-icons/fa";

export default function ProveedorDetalle() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const d = await api.getProveedor(id); 
        if (alive) setData(d);
      } catch (e) {
        console.error("Error cargando proveedor:", e);
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

  if (!data || !data.general) {
    return (
      <div className="clientes-page">
        <p className="loading">Proveedor no encontrado</p>
      </div>
    );
  }

  const s = data.general;
  const mapUrl =
    s.Lat != null && s.Lng != null
      ? `https://maps.google.com/maps?q=${s.Lat},${s.Lng}&z=14&output=embed`
      : null;

  return (
    <div className="clientes-page">

      <section className="detail-wrap">
        <div className="detail-head">
          <button className="btn ghost" onClick={() => navigate("/proveedores")}>
            <FaArrowLeft /> Volver
          </button>
          <h2 className="detail-title">Detalle del Proveedor</h2>
          <span />
        </div>

        <div className="detail-layout proveedores">
            {/* MAPA */}
            <article className="card card-map area-map">
                <div className="card-header">
                <FaMapMarkerAlt /> Ubicación
                </div>
                {mapUrl ? (
                <iframe title="mapa" src={mapUrl} loading="lazy" />
                ) : (
                <div className="map-placeholder">Sin ubicación</div>
                )}
            </article>

            {/* INFO GENERAL */}
            <article className="card card-block area-info">
                <div className="card-header"><FaIdCard /> Información General</div>
                <div className="kv"><span className="k">ID:</span><span className="v">{s.SupplierID ?? "-"}</span></div>
                <div className="kv alt"><span className="k">Código:</span><span className="v">{s.SupplierReference ?? "-"}</span></div>
                <div className="kv"><span className="k">Nombre:</span><span className="v strong">{s.SupplierName ?? "-"}</span></div>
                <div className="kv alt"><span className="k">Categoría:</span><span className="v">{s.Categoria ?? "-"}</span></div>
                <div className="kv"><span className="k">Días de pago:</span><span className="v">{s.PaymentDays ?? "-"}</span></div>
            </article>

            {/* DATOS BANCARIOS (al lado de Info General) */}
            <article className="card card-block area-bank">
                <div className="card-header"><FaUniversity /> Datos Bancarios</div>
                <div className="kv"><span className="k">Nombre en cuenta:</span><span className="v">{s.BankName ?? "-"}</span></div>
                <div className="kv alt"><span className="k">Sucursal:</span><span className="v">{s.BankBranch ?? "-"}</span></div>
                <div className="kv"><span className="k">Código de Cuenta:</span><span className="v">{s.BankCode ?? "-"}</span></div>
                <div className="kv alt"><span className="k">Número de Cuenta:</span><span className="v">{s.AccountNumber ?? "-"}</span></div>
                <div className="kv"><span className="k">Código internacional:</span><span className="v">{s.BankInternationalCode ?? "-"}</span></div>
            </article>

            {/* DIRECCIÓN Y ENTREGA */}
            <article className="card card-block area-addr">
                <div className="card-header"><FaTruck /> Dirección y Entrega</div>
                <div className="kv">
                <span className="k">Método:</span>
                <span className="v"><span className="pill">{s.DeliveryMethodName ?? "-"}</span></span>
                </div>
                <div className="kv alt">
                <span className="k">Dirección:</span>
                <span className="v">
                    {[(s.DeliveryAddressLine1 || ""), (s.DeliveryAddressLine2 || "")]
                    .filter(Boolean).join(", ") || "-"}
                </span>
                </div>
                <div className="kv"><span className="k">Ciudad:</span><span className="v">{s.DeliveryCityName ?? "-"}</span></div>
                <div className="kv alt"><span className="k">Provincia/Estado:</span><span className="v">{s.DeliveryStateProvinceName ?? "-"}</span></div>
                <div className="kv"><span className="k">País:</span><span className="v">{s.DeliveryCountryName ?? "-"}</span></div>
                <div className="kv alt"><span className="k">Código Postal:</span><span className="v">{s.CodigoPostal ?? "-"}</span></div>
            </article>

            {/* CONTACTOS & WEB */}
            <article className="card card-block area-contacts">
                <div className="card-header"><FaIdCard /> Contactos</div>
                <div className="kv"><span className="k">Primario:</span><span className="v">{s.PrimaryContactName ?? "-"}</span></div>
                <div className="kv alt"><span className="k">Alternativo:</span><span className="v">{s.AlternateContactName ?? "-"}</span></div>
                <div className="kv"><span className="k">Teléfono:</span><span className="v"><FaPhoneAlt /> {s.PhoneNumber ?? "-"}</span></div>
                <div className="kv alt"><span className="k">Fax:</span><span className="v">{s.FaxNumber ?? "-"}</span></div>
                <div className="kv">
                <span className="k">Sitio Web:</span>
                <span className="v">
                    {s.WebsiteURL ? (
                    <a href={s.WebsiteURL} target="_blank" rel="noreferrer">
                        <FaGlobe /> {s.WebsiteURL}
                    </a>
                    ) : "-"}
                </span>
                </div>
            </article>
            </div>
      </section>
    </div>
  );
}
