import React from "react";
import { Routes, Route, NavLink } from "react-router-dom";
import Principal from "./pages/Principal.jsx";
import Clientes from "./pages/Clientes.jsx";
import ClienteDetalle from "./pages/ClienteDetalle.jsx";
import Proveedores from "./pages/Proveedores.jsx";
import ProveedorDetalle from "./pages/ProveedorDetalle.jsx";
import Inventario from "./pages/Inventario.jsx";
import InventarioDetalle from "./pages/InventarioDetalle.jsx";
import Ventas from "./pages/Ventas.jsx";
import VentaDetalle from "./pages/VentaDetalle.jsx";
import Estadisticas from "./pages/Estadisticas.jsx";

export default function App() {
  return (
    <div className="app-shell">
      <main className="main max">
        <Routes>
          <Route path="/" element={<Principal />} />
          <Route path="/clientes" element={<Clientes />} />
          <Route path="/clientes/:id" element={<ClienteDetalle />} />
          <Route path="/proveedores" element={<Proveedores />} />
          <Route path="/proveedores/:id" element={<ProveedorDetalle />} />
          <Route path="/inventario" element={<Inventario />} />
          <Route path="/inventario/:id" element={<InventarioDetalle />} />
          <Route path="/ventas" element={<Ventas />} />
          <Route path="/ventas/:id" element={<VentaDetalle />} />
          <Route path="/estadisticas" element={<Estadisticas />} />
          <Route path="*" element={<div className="card">No encontrado</div>} />
        </Routes>
      </main>
    </div>
  );
}
