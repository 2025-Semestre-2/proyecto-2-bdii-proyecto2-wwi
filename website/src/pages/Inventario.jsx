import React, { useEffect, useMemo, useState } from "react";
import "../css/Clientes.css";
import CafeHeader from "../components/Header";
import { api } from "../helper/api";
import { FaSearch, FaSyncAlt, FaPlus, FaEdit, FaTrash, FaEye } from "react-icons/fa";
import { useNavigate } from "react-router-dom";

export default function Inventario() {
  const navigate = useNavigate();

  
  const [search, setSearch] = useState("");

  const [rawRows, setRawRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errMsg, setErrMsg] = useState("");

 
  const emptyForm = {
    StockItemName: "",
    SupplierID: "",
    UnitPackageID: "",
    OuterPackageID: "",
    QuantityPerOuter: "",
    UnitPrice: "",
    RecommendedRetailPrice: "",
    TaxRate: "",
    TypicalWeightPerUnit: "",
  };
  const [showModal, setShowModal] = useState(false);
  const [mode, setMode] = useState("new"); 
  const [form, setForm] = useState(emptyForm);
  const [editId, setEditId] = useState(null);
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    setErrMsg("");
    try {
      const data = await api.getInventario(search.trim() || undefined, undefined);
      setRawRows(Array.isArray(data) ? data : (data?.rows || []));
    } catch (e) {
      console.error(e);
      setErrMsg("No se pudo cargar el inventario.");
      setRawRows([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const rows = useMemo(() => {
    const tokens = search.trim().toLowerCase().split(/\s+/).filter(Boolean);
    if (!tokens.length) return rawRows;
    return rawRows.filter((r) => {
      const hay = `${r.nombreproducto ?? ""} ${r.grupo ?? ""}`.toLowerCase();
      return tokens.every((t) => hay.includes(t));
    });
  }, [rawRows, search]);

  const onRestore = () => {
    setSearch("");
    load();
  };

  const openNew = () => {
    setMode("new");
    setForm(emptyForm);
    setEditId(null);
    setShowModal(true);
  };

  const openEdit = async (row, ev) => {
    ev?.stopPropagation?.();
    setMode("edit");
    setEditId(row.stockitemid);
    setForm((f) => ({
      ...f,
      StockItemName: row.nombreproducto || "",
      SupplierID: "",
      UnitPackageID: "",
      OuterPackageID: "",
      QuantityPerOuter: "",
      UnitPrice: "",
      RecommendedRetailPrice: "",
      TaxRate: "",
      TypicalWeightPerUnit: "",
    }));
    setShowModal(true);
  };

  const closeModal = () => {
    if (saving) return;
    setShowModal(false);
    setForm(emptyForm);
    setEditId(null);
  };

  const onSave = async () => {
    const name = (form.StockItemName || "").trim();
    if (!name) return alert("El nombre es obligatorio.");
    if (!form.SupplierID) return alert("SupplierID es obligatorio.");
    if (!form.UnitPackageID) return alert("UnitPackageID es obligatorio.");
    if (!form.OuterPackageID) return alert("OuterPackageID es obligatorio.");
    if (!form.QuantityPerOuter) return alert("QuantityPerOuter es obligatorio.");
    if (form.UnitPrice === "" || form.UnitPrice == null) return alert("UnitPrice es obligatorio.");
    if (form.RecommendedRetailPrice === "" || form.RecommendedRetailPrice == null) return alert("RecommendedRetailPrice es obligatorio.");
    if (form.TaxRate === "" || form.TaxRate == null) return alert("TaxRate es obligatorio.");
    if (form.TypicalWeightPerUnit === "" || form.TypicalWeightPerUnit == null) return alert("TypicalWeightPerUnit es obligatorio.");

    const payload = {
      StockItemName: name,
      SupplierID: Number(form.SupplierID),
      UnitPackageID: Number(form.UnitPackageID),
      OuterPackageID: Number(form.OuterPackageID),
      QuantityPerOuter: Number(form.QuantityPerOuter),
      UnitPrice: Number(form.UnitPrice),
      RecommendedRetailPrice: Number(form.RecommendedRetailPrice),
      TaxRate: Number(form.TaxRate),
      TypicalWeightPerUnit: Number(form.TypicalWeightPerUnit),
    };

    setSaving(true);
    try {
      if (mode === "new") {
        await api.createItem(payload);
      } else {
        await api.updateItem(editId, payload);
      }
      closeModal();
      load();
    } catch (e) {
      console.error(e);
      alert(e.message || "No se pudo guardar el producto.");
    } finally {
      setSaving(false);
    }
  };

  const onDelete = async (row, ev) => {
    ev?.stopPropagation?.();
    if (!window.confirm(`¿Eliminar "${row.nombreproducto}"?`)) return;
    try {
      await api.deleteItem(row.stockitemid);
      load();
    } catch (e) {
      console.error(e);
      alert(e.message || "No se pudo eliminar (verifique si tiene ventas/compras o stock).");
    }
  };

  return (
    <div className="clientes-page">
      <CafeHeader />

      <section className="clientes-hero">
        <div className="hero__copy">
          <h2>Inventario</h2>
          <p>Consulte y mantenga los productos. Click en una fila para ver el detalle.</p>
        </div>

        <div className="hero__filters">
          <div className="input-wrap">
            <FaSearch />
            <input
              placeholder="Buscar por producto o grupo"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && load()}
            />
          </div>

          <button className="btn primary" onClick={load} disabled={loading}>
            {loading ? "Cargando..." : "Aplicar"}
          </button>

          <button className="btn ghost" onClick={onRestore} title="Restaurar">
            <FaSyncAlt />
            <span>Restaurar</span>
          </button>

          <button className="btn" onClick={openNew} title="Nuevo producto">
            <FaPlus />
            <span>Nuevo</span>
          </button>
        </div>
      </section>

      {/* Tabla */}
      <section className="card clientes-table">
        {!!errMsg && <div className="alert">{errMsg}</div>}

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Producto</th>
                <th>Grupo</th>
                <th className="right">Cantidad</th>
                <th style={{ width: 150 }}>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {rows.length ? (
                rows.map((r) => (
                  <tr
                    key={r.stockitemid}
                    className="row"
                    onClick={() => navigate(`/inventario/${r.stockitemid}`)}
                    title="Ver detalle"
                  >
                    <td className="strong">{r.nombreproducto}</td>
                    <td>{r.grupo ?? "—"}</td>
                    <td className="right">{r.cantidad ?? 0}</td>
                    <td>
                      <div style={{ display: "flex", gap: 8 }}>
                        <button
                          className="btn"
                          title="Ver"
                          onClick={(e) => {
                            e.stopPropagation();
                            navigate(`/inventario/${r.stockitemid}`);
                          }}
                        >
                          <FaEye />
                        </button>
                        <button className="btn" title="Editar" onClick={(e) => openEdit(r, e)}>
                          <FaEdit />
                        </button>
                        <button className="btn" title="Eliminar" onClick={(e) => onDelete(r, e)}>
                          <FaTrash />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="4" className="muted">
                    {loading ? "Cargando..." : "Sin resultados"}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* Modal Crear/Editar */}
      {showModal && (
        <div className="modal-mask" onClick={closeModal}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-head">
              <h3 style={{ margin: 0 }}>
                {mode === "new" ? "Nuevo producto" : `Editar producto #${editId}`}
              </h3>
              <button className="btn close" onClick={closeModal}>Cerrar</button>
            </div>

            <div className="modal-body">
              <div className="grid2">
                <div>
                  <label>Nombre</label>
                  <input
                    value={form.StockItemName}
                    onChange={(e) => setForm((f) => ({ ...f, StockItemName: e.target.value }))}
                  />
                </div>

                <div>
                  <label>SupplierID</label>
                  <input
                    type="number"
                    value={form.SupplierID}
                    onChange={(e) => setForm((f) => ({ ...f, SupplierID: e.target.value }))}
                  />
                </div>

                <div>
                  <label>UnitPackageID</label>
                  <input
                    type="number"
                    value={form.UnitPackageID}
                    onChange={(e) => setForm((f) => ({ ...f, UnitPackageID: e.target.value }))}
                  />
                </div>

                <div>
                  <label>OuterPackageID</label>
                  <input
                    type="number"
                    value={form.OuterPackageID}
                    onChange={(e) => setForm((f) => ({ ...f, OuterPackageID: e.target.value }))}
                  />
                </div>

                <div>
                  <label>QuantityPerOuter</label>
                  <input
                    type="number"
                    value={form.QuantityPerOuter}
                    onChange={(e) => setForm((f) => ({ ...f, QuantityPerOuter: e.target.value }))}
                  />
                </div>

                <div>
                  <label>UnitPrice</label>
                  <input
                    type="number"
                    step="0.01"
                    value={form.UnitPrice}
                    onChange={(e) => setForm((f) => ({ ...f, UnitPrice: e.target.value }))}
                  />
                </div>

                <div>
                  <label>RecommendedRetailPrice</label>
                  <input
                    type="number"
                    step="0.01"
                    value={form.RecommendedRetailPrice}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, RecommendedRetailPrice: e.target.value }))
                    }
                  />
                </div>

                <div>
                  <label>TaxRate</label>
                  <input
                    type="number"
                    step="0.001"
                    value={form.TaxRate}
                    onChange={(e) => setForm((f) => ({ ...f, TaxRate: e.target.value }))}
                  />
                </div>

                <div>
                  <label>TypicalWeightPerUnit</label>
                  <input
                    type="number"
                    step="0.001"
                    value={form.TypicalWeightPerUnit}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, TypicalWeightPerUnit: e.target.value }))
                    }
                  />
                </div>
              </div>

              <div style={{ display: "flex", gap: 10, marginTop: 12 }}>
                <button className="btn primary" onClick={onSave} disabled={saving}>
                  {saving ? "Guardando..." : mode === "new" ? "Crear" : "Actualizar"}
                </button>
                <button className="btn ghost" onClick={closeModal} disabled={saving}>
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
