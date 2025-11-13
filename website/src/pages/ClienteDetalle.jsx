import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { api } from "../helper/api";
import "../css/Clientes.css";
import "../css/ClienteDetalle.css";
import { FaArrowLeft, FaPhoneAlt, FaGlobe, FaMapMarkerAlt, FaTruck, FaIdCard } from "react-icons/fa";

export default function ClienteDetalle() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const d = await api.getCliente(id); 
        if (alive) setData(d);
      } catch (e) {
        console.error("Error cargando detalle:", e);
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
        <p className="loading">Cliente no encontrado</p>
      </div>
    );
  }

  const c = data.general || {};
  const mapUrl = (c.Lat != null && c.Lng != null)
    ? `https://maps.google.com/maps?q=${c.Lat},${c.Lng}&z=14&output=embed`
    : null;

  return (
    <div className="clientes-page">

      <section className="detail-wrap">
        <div className="detail-head">
          <button className="btn ghost" onClick={() => navigate("/clientes")}>
            <FaArrowLeft /> Volver
          </button>
          <h2 className="detail-title">Detalle del Cliente</h2>
          <span />
        </div>

        <div className="detail-layout">
          {/* MAPA */}
          <article className="card card-map">
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
          <article className="card card-block">
            <div className="card-header"><FaIdCard /> Información General</div>
            <div className="kv">
              <span className="k">ID:</span><span className="v">{c.CustomerID ?? "-"}</span>
            </div>
            <div className="kv alt">
              <span className="k">Nombre:</span><span className="v strong">{c.CustomerName ?? "-"}</span>
            </div>
            <div className="kv">
              <span className="k">Categoría:</span><span className="v">{c.Categoria ?? "-"}</span>
            </div>
            <div className="kv alt">
              <span className="k">Grupo de Compra:</span><span className="v">{c.BuyingGroup ?? "-"}</span>
            </div>
            <div className="kv">
              <span className="k">Cliente para facturar:</span><span className="v">{c.BillToCustomerID ?? "-"}</span>
            </div>
            <div className="kv alt">
              <span className="k">Días de pago:</span><span className="v">{c.PaymentDays ?? "-"}</span>
            </div>
          </article>

          {/* DIRECCIÓN Y ENTREGA */}
          <article className="card card-block">
            <div className="card-header"><FaTruck /> Dirección y Entrega</div>
            <div className="kv">
              <span className="k">Método:</span>
              <span className="v"><span className="pill">{c.DeliveryMethodName ?? "-"}</span></span>
            </div>
            <div className="kv alt">
              <span className="k">Dirección:</span>
              <span className="v">
                {[(c.DeliveryAddressLine1 || ""), (c.DeliveryAddressLine2 || "")]
                  .filter(Boolean).join(", ") || "-"}
              </span>
            </div>
            <div className="kv">
              <span className="k">Ciudad:</span><span className="v">{c.DeliveryCityName ?? "-"}</span>
            </div>
            <div className="kv alt">
              <span className="k">Provincia/Estado:</span><span className="v">{c.DeliveryStateProvinceName ?? "-"}</span>
            </div>
            <div className="kv">
              <span className="k">País:</span><span className="v">{c.DeliveryCountryName ?? "-"}</span>
            </div>
            <div className="kv alt">
              <span className="k">Código Postal:</span><span className="v">{c.CodigoPostal ?? "-"}</span>
            </div>
          </article>

          {/* CONTACTOS */}
          <article className="card card-block">
            <div className="card-header"><FaIdCard /> Contactos</div>
            <div className="kv">
              <span className="k">Contacto Primario:</span>
              <span className="v">{c.PrimaryContactName ?? "-"}</span>
            </div>
            <div className="kv alt">
              <span className="k">Contacto Alternativo:</span>
              <span className="v">{c.AlternateContactName ?? "-"}</span>
            </div>
            <div className="kv">
              <span className="k">Teléfono:</span>
              <span className="v"><FaPhoneAlt /> {c.PhoneNumber ?? "-"}</span>
            </div>
            <div className="kv alt">
              <span className="k">Fax:</span><span className="v">{c.FaxNumber ?? "-"}</span>
            </div>
            <div className="kv">
              <span className="k">Sitio Web:</span>
              <span className="v">
                {c.WebsiteURL ? (
                  <a href={c.WebsiteURL} target="_blank" rel="noreferrer">
                    <FaGlobe /> {c.WebsiteURL}
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
