const BASE = import.meta?.env?.VITE_API_BASE ?? "/api";

async function http(path) {
  const r = await fetch(`${BASE}${path}`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

function qs(obj = {}) {
  const p = new URLSearchParams();
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined && v !== null && v !== "") p.append(k, v);
  }
  const s = p.toString();
  return s ? `?${s}` : "";
}

export const api = {
  // Clientes
  getClientes: (search) => http(`/clientes${qs({ search })}`),
  getCliente:  (id)     => http(`/clientes/${id}`),

  // Proveedores
  getProveedores: (search, category) => http(`/proveedores${qs({ search, category })}`),
  getProveedor:   (id)               => http(`/proveedores/${id}`), 

  // Inventario
  getInventario: (search, group) => http(`/inventario${qs({ search, group })}`),
  getItem:       (id)            => http(`/inventario/${id}`),
  
  // Inventario - Referencias para formularios
  getSuppliers:     ()   => http(`/inventario/reference/suppliers`),
  getColors:        ()   => http(`/inventario/reference/colors`),
  getPackageTypes:  ()   => http(`/inventario/reference/packages`),
  getStockGroups:   ()   => http(`/inventario/reference/stockgroups`),
  getProductStockGroups: (id) => http(`/inventario/reference/stockgroups/${id}`),
  
  // Verificar si un producto puede ser eliminado
  checkProductCanDelete: (id) => http(`/inventario/check/${id}`),
  
  createItem: (payload) =>
    fetch(`${BASE}/inventario`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    }).then(r => { if(!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); }),

  updateItem: (id, payload) =>
    fetch(`${BASE}/inventario/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    }).then(r => { if(!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); }),

  deleteItem: (id) =>
    fetch(`${BASE}/inventario/${id}`, {
      method: 'DELETE'
    }).then(async r => { 
      const data = await r.json();
      if(!r.ok) {
        const error = new Error(data.error || `HTTP ${r.status}`);
        error.details = data.details;
        throw error;
      }
      return data;
    }),

  getVentas: ({ client, from, to, min, max, page = 1, limit = 50 } = {}) => {
    const p = new URLSearchParams();
    if (client) p.set("client", client);
    if (from)   p.set("from", from);
    if (to)     p.set("to", to);
    if (min !== "" && min != null) p.set("min", min);   
    if (max !== "" && max != null) p.set("max", max);   
    p.set("page", page);
    p.set("limit", limit);
    return http(`/ventas?${p.toString()}`); 
  },
  getFactura: (id) => http(`/ventas/${id}`),

  // Estadísticas
  compras:        (supplier, category) => http(`/estadisticas/compras${qs({ supplier, category })}`),
  ventas:         (customer, category) => http(`/estadisticas/ventas${qs({ customer, category })}`),
  topProductos:   (year)               => http(`/estadisticas/top-productos${qs({ year })}`),
  topClientes:    (fy, ty)             => http(`/estadisticas/top-clientes${qs({ fromyear: fy, toyear: ty })}`),
  topProveedores: (fy, ty)             => http(`/estadisticas/top-proveedores${qs({ fromyear: fy, toyear: ty })}`),
};
