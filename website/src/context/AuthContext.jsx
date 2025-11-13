import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Cargar usuario desde localStorage al iniciar
  useEffect(() => {
    const storedUser = localStorage.getItem('wwi_user');
    if (storedUser) {
      try {
        setUser(JSON.parse(storedUser));
      } catch (error) {
        console.error('Error parsing stored user:', error);
        localStorage.removeItem('wwi_user');
      }
    }
    setLoading(false);
  }, []);

  const login = (userData) => {
    setUser(userData);
    localStorage.setItem('wwi_user', JSON.stringify(userData));
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('wwi_user');
  };

  // Verificar si el usuario tiene acceso a una ruta específica
  const hasAccess = (path) => {
    if (!user) return false;

    const rol = user.rol?.toLowerCase();

    // Rutas accesibles por rol "administrador" (Sucursales)
    const adminRoutes = [
      '/clientes',
      '/proveedores',
      '/inventario',
      '/ventas'
    ];

    // Rutas accesibles por rol "Corporativo"
    const corpRoutes = [
      '/estadisticas'
    ];

    // Principal accesible para todos
    if (path === '/' || path === '') return true;

    // Si es administrador (sucursales)
    if (rol === 'administrador') {
      return adminRoutes.some(route => path.startsWith(route));
    }

    // Si es corporativo
    if (rol === 'corporativo') {
      return corpRoutes.some(route => path.startsWith(route));
    }

    return false;
  };

  const value = {
    user,
    loading,
    login,
    logout,
    hasAccess,
    isAuthenticated: !!user
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth debe usarse dentro de AuthProvider');
  }
  return context;
};
