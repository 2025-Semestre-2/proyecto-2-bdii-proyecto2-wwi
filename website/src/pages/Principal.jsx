import "../css/Principal.css";
import { Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import logo from "../assets/logoT2.png";
import { 
  FaChevronRight, 
  FaUsers, 
  FaTruck, 
  FaChartLine, 
  FaChartBar, 
  FaBoxes 
} from "react-icons/fa";

// Módulos para rol Administrador (Sucursales)
const modulosAdministrador = [
  { 
    id: 1, 
    titulo: "Clientes", 
    color: "#553d2a",
    icon: FaUsers,
    link: "/clientes",
    descripcion: "Consultar los clientes almacenados en la base de datos"
  },
  { 
    id: 2, 
    titulo: "Proveedores", 
    color: "#5f4633",
    icon: FaTruck,
    link: "/proveedores",
    descripcion: "Consultar los proveedores almacenados en la base de datos"
  },
  { 
    id: 5, 
    titulo: "Inventario", 
    color: "#7e634e",
    icon: FaBoxes,
    link: "/inventario",
    descripcion: "Consultar los productos almacenados en la base de datos"
  },
  { 
    id: 3, 
    titulo: "Ventas", 
    color: "#69503c",
    icon: FaChartLine,
    link: "/ventas",
    descripcion: "Consultar las ventas registradas en la base de datos"
  }
];

// Módulos para rol Corporativo
const modulosCorporativos = [
  { 
    id: 4, 
    titulo: "Estadísticas", 
    color: "#735945",
    icon: FaChartBar,
    link: "/estadisticas",
    descripcion: "Consultar estadísticas de ventas, productos, clientes y proveedores"
  }
];

export default function Principal() {
  const { user } = useAuth();

  // Determinar qué módulos mostrar según el rol
  const rol = user?.rol?.toLowerCase();
  const modulos = rol === 'corporativo' ? modulosCorporativos : modulosAdministrador;

  return (
    <section className="carreras-destacadas">
      <div className="carreras-container">
        <h2 className="carreras-title">Wide World Importers</h2>
        <p className="carreras-subtitle">
          Bienvenido, {user?.fullName || user?.username}
        </p>
        <p className="carreras-info">
          {rol === 'corporativo' 
            ? 'Oficina Corporativa - Módulo de Estadísticas'
            : `${user?.sucursal && (user.sucursal.charAt(0).toUpperCase() + user.sucursal.slice(1).toLowerCase())} - Gestión Operativa`
          }
        </p>

        <div className="carreras-grid">
          {modulos.map((c) => {
            const IconComponent = c.icon;
            return (
              <Link
                key={c.id}
                to={c.link}
                className="cflip-card"
              >
                <div className="cflip-inner">
                  {/* Cara frontal con color e icono */}
                  <div 
                    className="cflip-face cflip-front"
                    style={{ background: `linear-gradient(135deg, ${c.color} 0%, ${c.color}dd 100%)` }}
                  >
                    <div className="cflip-front-content">
                      <IconComponent className="cflip-front-icon" />
                    </div>
                    <div className="cflip-title-overlay">
                      <h3 className="cflip-title">{c.titulo}</h3>
                    </div>
                  </div>

                  {/* Cara trasera */}
                  <div 
                    className="cflip-face cflip-back"
                    style={{ 
                      background: `linear-gradient(180deg, ${c.color} 0%, rgba(30, 20, 12, 0.95) 100%)` 
                    }}
                  >
                    <IconComponent className="cflip-back-icon" />
                    <p className="cflip-back-text">{c.descripcion}</p>
                    <span className="cflip-cta">
                      Ingresar <FaChevronRight className="cflip-icon" />
                    </span>
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      </div>
    </section>
  );
}
