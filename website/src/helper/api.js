const BASE = import.meta?.env?.VITE_API_BASE ?? "/api";

// Obtener el usuario autenticado desde localStorage
function getUser() {
  try {
    const user = localStorage.getItem('wwi_user');
    return user ? JSON.parse(user) : null;
  } catch {
    return null;
  }
}

// HTTP helper con header de sucursal automático
async function http(path, options = {}) {
  const user = getUser();
  const headers = {
    ...options.headers
  };

  // Agregar header de sucursal si el usuario está autenticado
  if (user && user.sucursal) {
    headers['X-Sucursal'] = user.sucursal;
  }

  console.log(`[API] Request to: ${BASE}${path}`, {
    sucursal: user?.sucursal,
    headers: headers
  });

  const r = await fetch(`${BASE}${path}`, {
    ...options,
    headers
  });

  if (!r.ok) {
    const error = await r.json().catch(() => ({ error: `HTTP ${r.status}` }));
    console.error(`[API] Error response from ${path}:`, error);
    throw new Error(error.error || error.message || `HTTP ${r.status}`);
  }

  const responseData = await r.json();
  console.log(`[API] Success response from ${path}:`, responseData);
  return responseData;
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
  // ============================================================
  // AUTENTICACIÓN
  // ============================================================
  login: async (username, password, sucursal) => {
    const response = await fetch(`${BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password, sucursal })
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Error al iniciar sesión');
    }

    return data;
  },

  getSucursales: () => http('/auth/sucursales'),

  // ============================================================
  // RECURSOS (requieren autenticación y sucursal)
  // ============================================================
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
  
  createItem: async (payload) => {
    const user = getUser();
    const headers = { 'Content-Type': 'application/json' };
    if (user?.sucursal) headers['X-Sucursal'] = user.sucursal;

    const r = await fetch(`${BASE}/inventario`, {
      method: 'POST',
      headers,
      body: JSON.stringify(payload)
    });

    if (!r.ok) {
      const error = await r.json().catch(() => ({ error: `HTTP ${r.status}` }));
      throw new Error(error.error || `HTTP ${r.status}`);
    }

    return r.json();
  },

  updateItem: async (id, payload) => {
    const user = getUser();
    const headers = { 'Content-Type': 'application/json' };
    if (user?.sucursal) headers['X-Sucursal'] = user.sucursal;

    const r = await fetch(`${BASE}/inventario/${id}`, {
      method: 'PUT',
      headers,
      body: JSON.stringify(payload)
    });

    if (!r.ok) {
      const error = await r.json().catch(() => ({ error: `HTTP ${r.status}` }));
      throw new Error(error.error || `HTTP ${r.status}`);
    }

    return r.json();
  },

  deleteItem: async (id) => {
    const user = getUser();
    const headers = {};
    if (user?.sucursal) headers['X-Sucursal'] = user.sucursal;

    const r = await fetch(`${BASE}/inventario/${id}`, {
      method: 'DELETE',
      headers
    });

    const data = await r.json();

    if (!r.ok) {
      const error = new Error(data.error || `HTTP ${r.status}`);
      error.details = data.details;
      throw error;
    }

    return data;
  },

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
  compras:        (supplier, category, sucursal) => http(`/estadisticas/compras${qs({ supplier, category, sucursal })}`),
  ventas:         (customer, category, sucursal) => http(`/estadisticas/ventas${qs({ customer, category, sucursal })}`),
  topProductos:   (year, sucursal)               => http(`/estadisticas/top-productos${qs({ year, sucursal })}`),
  topClientes:    (fy, ty, sucursal)             => http(`/estadisticas/top-clientes${qs({ fromyear: fy, toyear: ty, sucursal })}`),
  topProveedores: (fy, ty, sucursal)             => http(`/estadisticas/top-proveedores${qs({ fromyear: fy, toyear: ty, sucursal })}`),
};
