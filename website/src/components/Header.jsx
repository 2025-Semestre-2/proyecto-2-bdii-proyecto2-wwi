import React from "react";
import { NavLink, Link } from "react-router-dom";
import { FaUsers, FaTruck, FaBoxes, FaChartLine, FaChartBar } from "react-icons/fa";
import logo from "../assets/logoT2.png";

export default function Header() {
  return (
    <header className="cafe-header">
      <div className="cafe-header__inner">
        <Link to="/" className="brand">
          <img src={logo} alt="Wide World Importers" />
          <span className="brand__title">Wide World Importers</span>
        </Link>

        <nav className="navlinks">
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
          <NavLink to="/estadisticas" className="navlink">
            <FaChartBar /> <span>Estadísticas</span>
          </NavLink>
        </nav>
      </div>
    </header>
  );
}
