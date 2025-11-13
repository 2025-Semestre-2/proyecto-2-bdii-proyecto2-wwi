const express = require('express');
const { sql, getPool, closeAllPools, SUCURSALES, WSL_HOST } = require('./config');

const clientesRoute = require('./routes/clients');
const proveedoresRoute = require('./routes/suppliers');
const inventarioRoute = require('./routes/inventory');
const ventasRoute = require('./routes/sales');
const estadisticasRoute = require('./routes/stats');

const app = express();
app.use(express.json());

// ============================================================
// Configuración CORS para acceso LAN
// ============================================================
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*'); // Permitir desde cualquier origen
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Sucursal');
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// ============================================================
//Extraer sucursal del header o token
// ============================================================
// Este middleware agrega req.sucursal para que las rutas sepan a qué BD conectar
app.use((req, res, next) => {
  // La sucursal puede venir de:
  // 1. Header personalizado X-Sucursal
  // 2. Token JWT (cuando implementes autenticación completa)
  // 3. Query parameter ?sucursal=xxx (solo para desarrollo)
  
  const sucursal = req.headers['x-sucursal'] || req.query.sucursal;
  
  if (sucursal) {
    req.sucursal = sucursal.toLowerCase().replace(/\s+/g, '');
  }
  
  next();
});

// ============================================================
// RUTAS DE AUTENTICACIÓN
// ============================================================

/**
 * POST /api/auth/login
 * Body: { username, password, sucursal }
 * Valida credenciales contra la BD de la sucursal seleccionada
 */
app.post('/api/auth/login', async (req, res) => {
  const { username, password, sucursal } = req.body;
  
  // Validación de campos
  if (!username || !password || !sucursal) {
    return res.status(400).json({
      error: 'Campos requeridos: username, password, sucursal'
    });
  }
  
  // Normalizar nombre de sucursal
  const sucursalNormalizada = sucursal.toLowerCase().replace(/\s+/g, '');
  
  // Validar que la sucursal existe
  if (!SUCURSALES.includes(sucursalNormalizada)) {
    return res.status(400).json({
      error: `Sucursal inválida. Opciones: ${SUCURSALES.join(', ')}`
    });
  }
  
  try {
    // Obtener conexión a la BD de la sucursal
    const pool = await getPool(sucursalNormalizada);
    
    // Ejecutar sp_Login de esa sucursal
    const result = await pool.request()
      .input('username', sql.NVarChar(50), username)
      .input('password', sql.NVarChar(50), password)
      .execute('Application.sp_Login');
    
    const userData = result.recordset[0];
    
    // Si no hay datos, las credenciales son inválidas (el SP lanza error)
    if (!userData) {
      return res.status(401).json({
        error: 'Credenciales inválidas',
        success: false
      });
    }
    
    // Login exitoso
    return res.json({
      success: true,
      message: 'Login exitoso',
      user: {
        userId: userData.UserID,
        username: userData.Username,
        fullName: userData.FullName,
        rol: userData.Rol,
        sucursal: sucursalNormalizada,
        active: true
      }
      // En producción, aquí generarías un JWT token
      // token: generateJWT({ userId: userData.UserID, sucursal: sucursalNormalizada })
    });
    
  } catch (error) {
    console.error('❌ Error en login:', error);
    return res.status(500).json({
      error: 'Error en el servidor al procesar login',
      details: error.message
    });
  }
});

/**
 * GET /api/auth/sucursales
 * Devuelve lista de sucursales disponibles para el login
 */
app.get('/api/auth/sucursales', (req, res) => {
  res.json({
    sucursales: [
      { id: 'sanjose', nombre: 'San José', descripcion: 'Sucursal San José' },
      { id: 'limon', nombre: 'Limón', descripcion: 'Sucursal Limón' },
      { id: 'corporativo', nombre: 'Corporativo', descripcion: 'Oficina Corporativa' }
    ]
  });
});

// ============================================================
// RUTAS DE RECURSOS (requieren sucursal)
// ============================================================

// Middleware para validar que existe sucursal en las rutas protegidas
const requireSucursal = (req, res, next) => {
  if (!req.sucursal) {
    return res.status(400).json({
      error: 'Debe especificar la sucursal en el header X-Sucursal'
    });
  }
  
  if (!SUCURSALES.includes(req.sucursal)) {
    return res.status(400).json({
      error: `Sucursal inválida. Opciones: ${SUCURSALES.join(', ')}`
    });
  }
  
  next();
};

// Aplicar middleware a las rutas de recursos
app.use('/api/clientes', requireSucursal, clientesRoute);
app.use('/api/proveedores', requireSucursal, proveedoresRoute);
app.use('/api/inventario', requireSucursal, inventarioRoute);
app.use('/api/ventas', requireSucursal, ventasRoute);
app.use('/api/estadisticas', requireSucursal, estadisticasRoute);

// ============================================================
// RUTAS GENERALES
// ============================================================

app.get('/', (req, res) => {
  res.json({
    message: 'API WideWorldImporters - Sistema Multi-Sucursal',
    version: '2.0',
    sucursales: SUCURSALES,
    endpoints: {
      auth: {
        login: 'POST /api/auth/login',
        sucursales: 'GET /api/auth/sucursales'
      },
      recursos: {
        clientes: 'GET /api/clientes (requiere header X-Sucursal)',
        proveedores: 'GET /api/proveedores (requiere header X-Sucursal)',
        inventario: 'GET /api/inventario (requiere header X-Sucursal)',
        ventas: 'GET /api/ventas (requiere header X-Sucursal)',
        estadisticas: 'GET /api/estadisticas (requiere header X-Sucursal)'
      }
    }
  });
});

app.get('/health', async (req, res) => {
  const status = {
    api: 'OK',
    timestamp: new Date().toISOString(),
    host: WSL_HOST,
    sucursales: {}
  };
  
  // Probar conexión a cada sucursal
  for (const sucursal of SUCURSALES) {
    try {
      const pool = await getPool(sucursal);
      status.sucursales[sucursal] = {
        status: 'connected',
        database: pool.config.database
      };
    } catch (error) {
      status.sucursales[sucursal] = {
        status: 'error',
        message: error.message
      };
    }
  }
  
  res.json(status);
});

// ============================================================
// INICIALIZACIÓN Y CIERRE GRACEFUL
// ============================================================

const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log('');
  console.log('🚀 ============================================');
  console.log(`   API WideWorldImporters Multi-Sucursal`);
  console.log('🚀 ============================================');
  console.log(`   📡 Servidor: http://localhost:${PORT}`);
  console.log(`   🌐 Red LAN:  http://${WSL_HOST}:${PORT}`);
  console.log('');
  console.log('   Sucursales disponibles:');
  console.log('   • San José (puerto 1437)');
  console.log('   • Limón (puerto 1435)');
  console.log('   • Corporativo (puerto 1436)');
  console.log('');
  console.log('   Endpoints:');
  console.log(`   • POST ${PORT}/api/auth/login`);
  console.log(`   • GET  ${PORT}/api/auth/sucursales`);
  console.log(`   • GET  ${PORT}/health`);
  console.log('============================================');
  console.log('');
});

// Cerrar conexiones al terminar
process.on('SIGTERM', async () => {
  console.log('⚠️  SIGTERM recibido, cerrando conexiones...');
  await closeAllPools();
  server.close(() => {
    console.log('✅ Servidor cerrado');
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  console.log('\n⚠️  SIGINT recibido, cerrando conexiones...');
  await closeAllPools();
  server.close(() => {
    console.log('✅ Servidor cerrado');
    process.exit(0);
  });
});

