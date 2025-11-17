import React, { useEffect, useMemo, useState } from "react";
import "../css/Clientes.css";
import { api } from "../helper/api";
import { FaSearch, FaSyncAlt, FaPlus, FaEdit, FaTrash, FaEye } from "react-icons/fa";
import { useNavigate } from "react-router-dom";

export default function Inventario() {
    useEffect(() => {
      load("");
    }, []);
  const navigate = useNavigate();

  const [search, setSearch] = useState("");
  const [rawRows, setRawRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errMsg, setErrMsg] = useState("");

  // Datos de referencia para los dropdowns
  const [suppliers, setSuppliers] = useState([]);
  const [colors, setColors] = useState([]);
  const [packageTypes, setPackageTypes] = useState([]);
  const [stockGroups, setStockGroups] = useState([]);

  const emptyForm = {
    NombreProducto: "",
    SupplierID: "",
    ColorID: "",
    UnitPackageID: "",
    OuterPackageID: "",
    CantidadEmpaquetamiento: "",
    Marca: "",
    Talla: "",
    Impuesto: "",
    PrecioUnitario: "",
    PrecioVenta: "",
    Peso: "",
    CantidadDisponible: "",
    Ubicacion: "",
    TiempoEntrega: "0",
    RequiereFrio: false,
    CodigoBarras: "",
    StockGroupIDs: [],
  };

  const [showModal, setShowModal] = useState(false);
  const [mode, setMode] = useState("new");
  const [form, setForm] = useState(emptyForm);
  const [editId, setEditId] = useState(null);
  const [saving, setSaving] = useState(false);

  const load = async (filtro) => {
    const value = typeof filtro === "string" ? filtro : search;
    setLoading(true);
    setErrMsg("");
    try {
      const data = await api.getInventario(value.trim() || undefined, undefined);
      setRawRows(Array.isArray(data) ? data : (data?.rows || []));
    } catch (e) {
      console.error(e);
      setErrMsg("No se pudo cargar el inventario.");
      setRawRows([]);
    } finally {
      setLoading(false);
    }
  };

  // Cargar datos de referencia
  const loadReferenceData = async () => {
    try {
      const [suppliersData, colorsData, packagesData, groupsData] = await Promise.all([
        api.getSuppliers(),
        api.getColors(),
        api.getPackageTypes(),
        api.getStockGroups(),
      ]);
      setSuppliers(suppliersData || []);
      setColors(colorsData || []);
      setPackageTypes(packagesData || []);
      setStockGroups(groupsData || []);
    } catch (e) {
      console.error("Error cargando datos de referencia:", e);
    }
  };

  useEffect(() => {
    load();
    loadReferenceData();
  }, []);

  // Mostrar los datos tal como vienen del backend
  const rows = rawRows;

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
    
    try {
      // Cargar los detalles completos del producto
      const details = await api.getItem(row.stockitemid);
      const general = details?.general || {};
      const holdings = details?.holdings || {};
      const proveedor = details?.proveedor || {};
      
      // Cargar los grupos asociados al producto
      const productGroups = await api.getProductStockGroups(row.stockitemid);
      const groupIDs = productGroups.map(g => g.StockGroupID);
      
      // Usar SupplierID del general (tabla StockItems) o del proveedor como fallback
      const supplierId = general.SupplierID || proveedor.SupplierID || "";
      
      setForm({
        NombreProducto: general.StockItemName || "",
        SupplierID: supplierId,
        ColorID: general.ColorID || "",
        UnitPackageID: general.UnitPackageID || "",
        OuterPackageID: general.OuterPackageID || "",
        CantidadEmpaquetamiento: general.QuantityPerOuter || "",
        Marca: general.Brand || "",
        Talla: general.Size || "",
        Impuesto: general.TaxRate !== null && general.TaxRate !== undefined ? general.TaxRate : "",
        PrecioUnitario: general.UnitPrice !== null && general.UnitPrice !== undefined ? general.UnitPrice : "",
        PrecioVenta: general.RecommendedRetailPrice !== null && general.RecommendedRetailPrice !== undefined ? general.RecommendedRetailPrice : "",
        Peso: general.TypicalWeightPerUnit || "",
        CantidadDisponible: holdings.QuantityOnHand !== null && holdings.QuantityOnHand !== undefined ? holdings.QuantityOnHand : "",
        Ubicacion: holdings.BinLocation || "",
        TiempoEntrega: general.LeadTimeDays !== null && general.LeadTimeDays !== undefined ? general.LeadTimeDays : "0",
        RequiereFrio: general.IsChillerStock || false,
        CodigoBarras: general.Barcode || "",
        StockGroupIDs: groupIDs,
      });
    } catch (e) {
      console.error("Error cargando detalles del producto:", e);
      alert("Error cargando los detalles del producto");
      return;
    }
    
    setShowModal(true);
  };

  const closeModal = () => {
    if (saving) return;
    setShowModal(false);
    setForm(emptyForm);
    setEditId(null);
  };

  const onSave = async () => {
    // Validaciones básicas
    if (!form.NombreProducto.trim()) return alert("El nombre del producto es obligatorio.");
    if (!form.SupplierID) return alert("Debe seleccionar un proveedor.");
    if (!form.UnitPackageID) return alert("Debe seleccionar un tipo de empaque unitario.");
    if (!form.OuterPackageID) return alert("Debe seleccionar un tipo de empaque externo.");
    if (!form.CantidadEmpaquetamiento) return alert("La cantidad por empaquetamiento es obligatoria.");
    if (form.Impuesto === "" || form.Impuesto == null) return alert("El impuesto es obligatorio.");
    if (form.PrecioUnitario === "" || form.PrecioUnitario == null) return alert("El precio unitario es obligatorio.");
    if (form.PrecioVenta === "" || form.PrecioVenta == null) return alert("El precio de venta es obligatorio.");
    
    // Preparar el payload
    const payload = {
      NombreProducto: form.NombreProducto.trim(),
      SupplierID: Number(form.SupplierID),
      ColorID: form.ColorID ? Number(form.ColorID) : null,
      UnitPackageID: Number(form.UnitPackageID),
      OuterPackageID: Number(form.OuterPackageID),
      CantidadEmpaquetamiento: Number(form.CantidadEmpaquetamiento),
      Marca: form.Marca.trim() || null,
      Talla: form.Talla.trim() || null,
      Impuesto: Number(form.Impuesto),
      PrecioUnitario: Number(form.PrecioUnitario),
      PrecioVenta: Number(form.PrecioVenta),
      Peso: form.Peso ? Number(form.Peso) : null,
      CantidadDisponible: form.CantidadDisponible ? Number(form.CantidadDisponible) : 0,
      Ubicacion: form.Ubicacion.trim() || null,
      TiempoEntrega: Number(form.TiempoEntrega) || 0,
      RequiereFrio: form.RequiereFrio,
      CodigoBarras: form.CodigoBarras.trim() || null,
      StockGroupIDs: form.StockGroupIDs.length > 0 ? form.StockGroupIDs.join(',') : null,
    };

    setSaving(true);
    try {
      if (mode === "new") {
        await api.createItem(payload);
        alert("Producto creado exitosamente");
      } else {
        await api.updateItem(editId, payload);
        alert("Producto actualizado exitosamente");
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
    if (!window.confirm(`¿Está seguro de eliminar "${row.nombreproducto}"?\n\nEsta acción eliminará el producto y todo su inventario.`)) return;
    try {
      const response = await api.deleteItem(row.stockitemid);
      if (response.ok) {
        alert("Producto eliminado exitosamente");
        load();
      } else {
        alert(response.error || "No se pudo eliminar el producto.");
      }
    } catch (e) {
      console.error(e);
      
      // Mostrar mensaje de error detallado
      let errorMsg = "No se pudo eliminar el producto.";
      
      if (e.message) {
        errorMsg = e.message;
      }
      
      // Si hay detalles adicionales (facturas y órdenes de compra)
      if (e.details) {
        errorMsg += `\n\nDetalles:\n`;
        if (e.details.invoiceCount > 0) {
          errorMsg += `- Facturas de venta: ${e.details.invoiceCount}\n`;
        }
        if (e.details.purchaseOrderCount > 0) {
          errorMsg += `- Órdenes de compra: ${e.details.purchaseOrderCount}`;
        }
      }
      
      alert(errorMsg);
    }
  };

  const handleStockGroupChange = (groupId) => {
    setForm((f) => {
      const newGroups = f.StockGroupIDs.includes(groupId)
        ? f.StockGroupIDs.filter(id => id !== groupId)
        : [...f.StockGroupIDs, groupId];
      return { ...f, StockGroupIDs: newGroups };
    });
  };

  return (
    <div className="clientes-page">
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
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 900 }}>
            <div className="modal-head">
              <h3 style={{ margin: 0 }}>
                {mode === "new" ? "Nuevo producto" : `Editar producto #${editId}`}
              </h3>
              <button className="btn close" onClick={closeModal}>Cerrar</button>
            </div>

            <div className="modal-body" style={{ maxHeight: '70vh', overflowY: 'auto' }}>
              <div className="grid2">
                {/* Información básica */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <h4 style={{ marginTop: 0 }}>Información Básica</h4>
                </div>

                <div>
                  <label>Nombre del Producto *</label>
                  <input
                    value={form.NombreProducto}
                    onChange={(e) => setForm((f) => ({ ...f, NombreProducto: e.target.value }))}
                  />
                </div>

                <div>
                  <label>Proveedor *</label>
                  <select
                    value={form.SupplierID}
                    onChange={(e) => setForm((f) => ({ ...f, SupplierID: e.target.value }))}
                  >
                    <option value="">Seleccione un proveedor</option>
                    {suppliers.map((s) => (
                      <option key={s.SupplierID} value={s.SupplierID}>
                        {s.SupplierName}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label>Marca</label>
                  <input
                    value={form.Marca}
                    onChange={(e) => setForm((f) => ({ ...f, Marca: e.target.value }))}
                  />
                </div>

                <div>
                  <label>Talla/Tamaño</label>
                  <input
                    value={form.Talla}
                    onChange={(e) => setForm((f) => ({ ...f, Talla: e.target.value }))}
                  />
                </div>

                <div>
                  <label>Color</label>
                  <select
                    value={form.ColorID}
                    onChange={(e) => setForm((f) => ({ ...f, ColorID: e.target.value }))}
                  >
                    <option value="">Seleccione un color (opcional)</option>
                    {colors.map((c) => (
                      <option key={c.ColorID} value={c.ColorID}>
                        {c.ColorName}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label>Código de Barras</label>
                  <input
                    value={form.CodigoBarras}
                    onChange={(e) => setForm((f) => ({ ...f, CodigoBarras: e.target.value }))}
                  />
                </div>

                {/* Empaquetamiento */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <h4>Empaquetamiento</h4>
                </div>

                <div>
                  <label>Empaque Unitario *</label>
                  <select
                    value={form.UnitPackageID}
                    onChange={(e) => setForm((f) => ({ ...f, UnitPackageID: e.target.value }))}
                  >
                    <option value="">Seleccione un tipo</option>
                    {packageTypes.map((p) => (
                      <option key={p.PackageTypeID} value={p.PackageTypeID}>
                        {p.PackageTypeName}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label>Empaque Externo *</label>
                  <select
                    value={form.OuterPackageID}
                    onChange={(e) => setForm((f) => ({ ...f, OuterPackageID: e.target.value }))}
                  >
                    <option value="">Seleccione un tipo</option>
                    {packageTypes.map((p) => (
                      <option key={p.PackageTypeID} value={p.PackageTypeID}>
                        {p.PackageTypeName}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label>Cantidad por Empaque *</label>
                  <input
                    type="number"
                    value={form.CantidadEmpaquetamiento}
                    onChange={(e) => setForm((f) => ({ ...f, CantidadEmpaquetamiento: e.target.value }))}
                  />
                </div>

                <div>
                  <label>Peso (kg)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={form.Peso}
                    onChange={(e) => setForm((f) => ({ ...f, Peso: e.target.value }))}
                  />
                </div>

                {/* Precios */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <h4>Precios e Impuestos</h4>
                </div>

                <div>
                  <label>Precio Unitario *</label>
                  <input
                    type="number"
                    step="0.01"
                    value={form.PrecioUnitario}
                    onChange={(e) => setForm((f) => ({ ...f, PrecioUnitario: e.target.value }))}
                  />
                </div>

                <div>
                  <label>Precio de Venta *</label>
                  <input
                    type="number"
                    step="0.01"
                    value={form.PrecioVenta}
                    onChange={(e) => setForm((f) => ({ ...f, PrecioVenta: e.target.value }))}
                  />
                </div>

                <div>
                  <label>Impuesto (%) *</label>
                  <input
                    type="number"
                    step="0.01"
                    value={form.Impuesto}
                    onChange={(e) => setForm((f) => ({ ...f, Impuesto: e.target.value }))}
                  />
                </div>

                {/* Inventario */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <h4>Inventario</h4>
                </div>

                <div>
                  <label>Cantidad Disponible</label>
                  <input
                    type="number"
                    value={form.CantidadDisponible}
                    onChange={(e) => setForm((f) => ({ ...f, CantidadDisponible: e.target.value }))}
                  />
                </div>

                <div>
                  <label>Ubicación</label>
                  <input
                    value={form.Ubicacion}
                    onChange={(e) => setForm((f) => ({ ...f, Ubicacion: e.target.value }))}
                    placeholder="Ej: A-01-B"
                  />
                </div>

                <div>
                  <label>Tiempo de Entrega (días)</label>
                  <input
                    type="number"
                    value={form.TiempoEntrega}
                    onChange={(e) => setForm((f) => ({ ...f, TiempoEntrega: e.target.value }))}
                  />
                </div>

                <div>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <input
                      type="checkbox"
                      checked={form.RequiereFrio}
                      onChange={(e) => setForm((f) => ({ ...f, RequiereFrio: e.target.checked }))}
                    />
                    Requiere Refrigeración
                  </label>
                </div>

                {/* Grupos de Stock */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <h4>Grupos de Productos</h4>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10 }}>
                    {stockGroups.map((group) => (
                      <label key={group.StockGroupID} style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                        <input
                          type="checkbox"
                          checked={form.StockGroupIDs.includes(group.StockGroupID)}
                          onChange={() => handleStockGroupChange(group.StockGroupID)}
                        />
                        {group.StockGroupName}
                      </label>
                    ))}
                  </div>
                </div>
              </div>

              <div style={{ display: "flex", gap: 10, marginTop: 20, paddingTop: 20, borderTop: '1px solid #ddd' }}>
                <button className="btn primary" onClick={onSave} disabled={saving}>
                  {saving ? "Guardando..." : mode === "new" ? "Crear Producto" : "Actualizar Producto"}
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
