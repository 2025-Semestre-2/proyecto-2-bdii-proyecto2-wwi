import React from "react";
import { Routes, Route, Navigate, useLocation } from "react-router-dom";
import { useAuth } from "./context/AuthContext";
import Header from "./components/Header";
import Login from "./pages/Login";
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

// Componente para proteger rutas
function ProtectedRoute({ children }) {
  const { isAuthenticated, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <div className="spinner" style={{ 
          width: '40px', 
          height: '40px', 
          border: '4px solid #e5e7eb',
          borderTopColor: '#667eea',
          borderRadius: '50%',
          animation: 'spin 0.8s linear infinite'
        }}></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
}

// Componente para verificar acceso por rol
function RoleProtectedRoute({ children }) {
  const { hasAccess, user } = useAuth();
  const location = useLocation();

  if (!hasAccess(location.pathname)) {
    // Redirigir según el rol
    if (user?.rol?.toLowerCase() === 'corporativo') {
      return <Navigate to="/estadisticas" replace />;
    }
    return <Navigate to="/" replace />;
  }

  return children;
}

export default function App() {
  const { isAuthenticated } = useAuth();

  return (
    <div className="app-shell">
      {isAuthenticated && <Header />}
      
      <main className="main max">
        <Routes>
          {/* Ruta pública de login */}
          <Route path="/login" element={<Login />} />

          {/* Rutas protegidas */}
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Principal />
              </ProtectedRoute>
            }
          />

          {/* Rutas de Administrativo (Sucursales) */}
          <Route
            path="/clientes"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <Clientes />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/clientes/:id"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <ClienteDetalle />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />

          <Route
            path="/proveedores"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <Proveedores />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/proveedores/:id"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <ProveedorDetalle />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />

          <Route
            path="/inventario"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <Inventario />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/inventario/:id"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <InventarioDetalle />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />

          <Route
            path="/ventas"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <Ventas />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/ventas/:id"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <VentaDetalle />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />

          {/* Rutas de Corporativo */}
          <Route
            path="/estadisticas"
            element={
              <ProtectedRoute>
                <RoleProtectedRoute>
                  <Estadisticas />
                </RoleProtectedRoute>
              </ProtectedRoute>
            }
          />

          {/* 404 */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
}
