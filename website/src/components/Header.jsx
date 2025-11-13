import React, { useState, useRef, useEffect } from "react";
import { createPortal } from "react-dom";
import { NavLink, Link, useNavigate } from "react-router-dom";
import { FaUsers, FaTruck, FaBoxes, FaChartLine, FaChartBar, FaSignOutAlt, FaUserCircle } from "react-icons/fa";
import { useAuth } from "../context/AuthContext";
import logo from "../assets/logoT2.png";

export default function Header() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [showDropdown, setShowDropdown] = useState(false);
  const dropdownRef = useRef(null);
  const buttonRef = useRef(null);
  const [dropdownPosition, setDropdownPosition] = useState({ top: 0, right: 0 });

  // Calcular posición del dropdown cuando se abre
  useEffect(() => {
    if (showDropdown && buttonRef.current) {
      const rect = buttonRef.current.getBoundingClientRect();
      const headerRect = buttonRef.current.closest('.cafe-header').getBoundingClientRect();
      setDropdownPosition({
        top: headerRect.bottom, // Pegado justo debajo del header
        right: window.innerWidth - rect.right
      });
    }
  }, [showDropdown]);

  // Cerrar dropdown al hacer click fuera
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target) && 
          buttonRef.current && !buttonRef.current.contains(event.target)) {
        setShowDropdown(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  const toggleDropdown = () => {
    setShowDropdown(!showDropdown);
  };

  // Determinar si es rol administrador (sucursales) o corporativo
  const isAdministrador = user?.rol?.toLowerCase() === 'administrador';
  const isCorporativo = user?.rol?.toLowerCase() === 'corporativo';

  return (
    <>
      <header className="cafe-header">
        <div className="cafe-header__inner">
          <Link to="/" className="brand">
            <img src={logo} alt="Wide World Importers" />
            <span className="brand__title">Wide World Importers</span>
          </Link>

          <nav className="navlinks">
            {/* Links para rol Administrador (Sucursales) */}
            {isAdministrador && (
              <>
                <NavLink to="/clientes" className="navlink">
                  <FaUsers /> <span>Clientes</span>
                </NavLink>
                <NavLink to="/proveedores" className="navlink">
                  <FaTruck /> <span>Proveedores</span>
                </NavLink>
                <NavLink to="/inventario" className="navlink">
                  <FaBoxes /> <span>Inventario</span>
                </NavLink>
                <NavLink to="/ventas" className="navlink">
                  <FaChartLine /> <span>Ventas</span>
                </NavLink>
              </>
            )}

            {/* Links para rol Corporativo */}
            {isCorporativo && (
              <NavLink to="/estadisticas" className="navlink">
                <FaChartBar /> <span>Estadísticas</span>
              </NavLink>
            )}
          </nav>

          {/* User Icon with Dropdown */}
          <div className="user-section">
            <button 
              ref={buttonRef}
              className="user-icon-btn" 
              onClick={toggleDropdown}
              title="Mi cuenta"
            >
              <FaUserCircle className="user-icon" />
            </button>
          </div>
        </div>
      </header>

      {/* Dropdown renderizado usando Portal (fuera del DOM del header) */}
      {showDropdown && createPortal(
        <div 
          ref={dropdownRef}
          className="user-dropdown"
          style={{
            position: 'fixed',
            top: `${dropdownPosition.top}px`,
            right: `${dropdownPosition.right}px`,
            background: 'linear-gradient(165deg, #7e634e 0%, #5a4736 100%)',
            borderRadius: '0 0 18px 18px',
            boxShadow: '0 12px 40px rgba(0,0,0,.5), 0 0 0 1px rgba(255,255,255,.08)',
            minWidth: '300px',
            overflow: 'hidden',
            zIndex: 9999,
            borderTop: 'none'
          }}
        >
          <div className="user-dropdown-info" style={{
            padding: '24px 24px 20px',
            background: 'linear-gradient(135deg, rgba(255,255,255,.08) 0%, rgba(255,255,255,.02) 100%)',
            borderBottom: '1px solid rgba(255,255,255,.12)',
            position: 'relative'
          }}>
            <div style={{
              width: '48px',
              height: '48px',
              borderRadius: '50%',
              background: 'linear-gradient(135deg, rgba(255,255,255,.2) 0%, rgba(255,255,255,.1) 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '12px',
              border: '2px solid rgba(255,255,255,.15)',
              boxShadow: '0 4px 12px rgba(0,0,0,.2)'
            }}>
              <FaUserCircle style={{ fontSize: '28px', color: '#fff', opacity: 0.9 }} />
            </div>
            <span className="user-dropdown-name" style={{
              color: '#fff',
              fontWeight: 700,
              fontSize: '17px',
              lineHeight: 1.3,
              textShadow: '0 2px 4px rgba(0,0,0,.3)',
              display: 'block',
              marginBottom: '6px'
            }}>
              {user?.fullName || user?.username}
            </span>
            <span className="user-dropdown-role" style={{
              color: 'rgba(255,255,255,.7)',
              fontSize: '13px',
              fontWeight: 500,
              letterSpacing: '0.3px',
              display: 'block'
            }}>
              {user?.sucursal && (user.sucursal.charAt(0).toUpperCase() + user.sucursal.slice(1).toLowerCase())} • {user?.rol && (user.rol.charAt(0).toUpperCase() + user.rol.slice(1).toLowerCase())}
            </span>
          </div>
          <button onClick={handleLogout} className="user-dropdown-logout" style={{
            width: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '10px',
            padding: '18px 24px',
            border: 'none',
            background: 'transparent',
            color: '#fff',
            fontWeight: 600,
            fontSize: '15px',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
            textAlign: 'center'
          }}>
            <FaSignOutAlt style={{ fontSize: '16px' }} />
            <span>Cerrar sesión</span>
          </button>
        </div>,
        document.body
      )}
    </>
  );
}
