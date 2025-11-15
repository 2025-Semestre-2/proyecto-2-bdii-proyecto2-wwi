import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { api } from '../helper/api';
import logo from '../assets/logoT2.png';
import '../css/Login.css';

export default function Login() {
  const navigate = useNavigate();
  const { login, isAuthenticated } = useAuth();

  const [formData, setFormData] = useState({
    username: '',
    password: '',
    sucursal: ''
  });

  const [sucursales, setSucursales] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // Redirigir si ya está autenticado
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  // Cargar lista de sucursales
  useEffect(() => {
    const loadSucursales = async () => {
      try {
        const data = await api.getSucursales();
        setSucursales(data.sucursales || []);
      } catch (err) {
        console.error('Error cargando sucursales:', err);
        // Fallback a sucursales hardcoded si falla la API
        setSucursales([
          { id: 'sanjose', nombre: 'San José', descripcion: 'Sucursal San José' },
          { id: 'limon', nombre: 'Limón', descripcion: 'Sucursal Limón' },
          { id: 'corporativo', nombre: 'Corporativo', descripcion: 'Oficina Corporativa' }
        ]);
      }
    };

    loadSucursales();
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    setError(''); // Limpiar error al escribir
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    // Validaciones
    if (!formData.username.trim()) {
      setError('Por favor ingrese su usuario');
      return;
    }

    if (!formData.password.trim()) {
      setError('Por favor ingrese su contraseña');
      return;
    }

    if (!formData.sucursal) {
      setError('Por favor seleccione una sucursal');
      return;
    }

    setLoading(true);

    try {
      const response = await api.login(
        formData.username,
        formData.password,
        formData.sucursal
      );

      if (response.success && response.user) {
        // Guardar usuario en contexto
        login(response.user);
        
        // Redirigir según el rol
        if (response.user.rol?.toLowerCase() === 'corporativo') {
          navigate('/estadisticas', { replace: true });
        } else {
          navigate('/', { replace: true });
        }
      } else {
        setError(response.error || 'Error al iniciar sesión');
      }
    } catch (err) {
      console.error('Error en login:', err);
      setError(err.message || 'Error al conectar con el servidor. Verifique su conexión.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <img src={logo} alt="Wide World Importers" className="login-logo" />
          <h1 className="login-title">Wide World Importers</h1>
          <p className="login-subtitle">Sistema de Gestión Empresarial</p>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          {error && (
            <div className="login-error">
              <svg 
                width="20" 
                height="20" 
                viewBox="0 0 20 20" 
                fill="none"
              >
                <path 
                  d="M10 0C4.48 0 0 4.48 0 10C0 15.52 4.48 20 10 20C15.52 20 20 15.52 20 10C20 4.48 15.52 0 10 0ZM11 15H9V13H11V15ZM11 11H9V5H11V11Z" 
                  fill="currentColor"
                />
              </svg>
              <span>{error}</span>
            </div>
          )}

          <div className="form-group">
            <label htmlFor="username" className="form-label">
              Usuario
            </label>
            <input
              type="text"
              id="username"
              name="username"
              value={formData.username}
              onChange={handleChange}
              className="form-input"
              placeholder="Ingrese su usuario"
              autoComplete="username"
              disabled={loading}
              autoFocus
            />
          </div>

          <div className="form-group">
            <label htmlFor="password" className="form-label">
              Contraseña
            </label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              className="form-input"
              placeholder="Ingrese su contraseña"
              autoComplete="current-password"
              disabled={loading}
            />
          </div>

          <div className="form-group">
            <label htmlFor="sucursal" className="form-label">
              Sucursal
            </label>
            <select
              id="sucursal"
              name="sucursal"
              value={formData.sucursal}
              onChange={handleChange}
              className="form-select"
              disabled={loading}
            >
              <option value="">Seleccione una sucursal</option>
              {sucursales.map(suc => (
                <option key={suc.id} value={suc.id}>
                  {suc.nombre} - {suc.descripcion}
                </option>
              ))}
            </select>
          </div>

          <button
            type="submit"
            className="login-button"
            disabled={loading}
          >
            {loading ? (
              <>
                <span className="spinner">
                  <img src={logo} alt="Logo" style={{ width: 18, height: 18, borderRadius: '50%' }} />
                </span>
                Iniciando sesión...
              </>
            ) : (
              'Iniciar Sesión'
            )}
          </button>
        </form>

        <div className="login-footer">
          <p>© 2025 Wide World Importers</p>
          <p className="text-muted">Sistema Multi-Sucursal</p>
        </div>
      </div>
    </div>
  );
}
