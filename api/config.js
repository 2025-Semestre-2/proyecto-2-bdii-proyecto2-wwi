const sql = require('mssql');

// ============================================================
// CONFIGURACIÓN MULTI-SUCURSAL
// ============================================================
// Cada sucursal tiene su propia conexión a su base de datos
// El usuario selecciona la sucursal al hacer login
// ============================================================

// Obtener la IP del host WSL para acceso desde red externa
// IMPORTANTE: Cambiar 'localhost' por tu IP de WSL si necesitas acceso LAN
// Para obtener tu IP de WSL ejecuta en terminal WSL: hostname -I
const WSL_HOST = process.env.WSL_HOST || 'localhost';

// Configuraciones por sucursal
const configs = {
  'sanjose': {
    user: 'sa',
    password: 'Passw0rd!',
    server: WSL_HOST,
    port: 1437,  // Puerto del contenedor WWI_SanJose
    database: 'WWI_SanJose',
    options: {
      encrypt: false,
      trustServerCertificate: true,
      enableArithAbort: true,
      connectionTimeout: 30000,
      requestTimeout: 30000
    },
    pool: {
      max: 10,
      min: 0,
      idleTimeoutMillis: 30000
    }
  },
  'limon': {
    user: 'sa',
    password: 'Passw0rd!',
    server: WSL_HOST,
    port: 1435,  // Puerto del contenedor WWI_Limon
    database: 'WWI_Limon',
    options: {
      encrypt: false,
      trustServerCertificate: true,
      enableArithAbort: true,
      connectionTimeout: 30000,
      requestTimeout: 30000
    },
    pool: {
      max: 10,
      min: 0,
      idleTimeoutMillis: 30000
    }
  },
  'corporativo': {
    user: 'sa',
    password: 'Passw0rd!',
    server: WSL_HOST,
    port: 1436,  // Puerto del contenedor WWI_Corporativo
    database: 'WWI_Corporativo',
    options: {
      encrypt: false,
      trustServerCertificate: true,
      enableArithAbort: true,
      connectionTimeout: 30000,
      requestTimeout: 30000
    },
    pool: {
      max: 10,
      min: 0,
      idleTimeoutMillis: 30000
    }
  }
};

// Pools de conexión por sucursal (se crean bajo demanda)
const pools = {
  sanjose: null,
  limon: null,
  corporativo: null
};

/**
 * Obtiene o crea un pool de conexión para una sucursal específica
 * @param {string} sucursal - 'sanjose', 'limon', o 'corporativo'
 * @returns {Promise<sql.ConnectionPool>}
 */
async function getPool(sucursal) {
  const sucursalNormalizada = sucursal.toLowerCase().replace(/\s+/g, '');
  
  // Validar sucursal
  if (!configs[sucursalNormalizada]) {
    throw new Error(`Sucursal inválida: ${sucursal}. Opciones válidas: sanjose, limon, corporativo`);
  }
  
  // Si el pool ya existe y está conectado, devolverlo
  if (pools[sucursalNormalizada] && pools[sucursalNormalizada].connected) {
    return pools[sucursalNormalizada];
  }
  
  // Crear nuevo pool
  console.log(`🔌 Creando conexión a sucursal: ${sucursalNormalizada.toUpperCase()}`);
  const pool = new sql.ConnectionPool(configs[sucursalNormalizada]);
  
  try {
    await pool.connect();
    pools[sucursalNormalizada] = pool;
    console.log(`✅ Conectado a ${sucursalNormalizada.toUpperCase()} (${configs[sucursalNormalizada].database})`);
    return pool;
  } catch (error) {
    console.error(` Error conectando a ${sucursalNormalizada}:`, error.message);
    throw error;
  }
}

/**
 * Cierra todos los pools de conexión
 */
async function closeAllPools() {
  const closePromises = Object.keys(pools).map(async (sucursal) => {
    if (pools[sucursal]) {
      await pools[sucursal].close();
      pools[sucursal] = null;
      console.log(`🔌 Pool cerrado: ${sucursal}`);
    }
  });
  
  await Promise.all(closePromises);
}

/**
 * Obtiene la configuración de una sucursal
 * @param {string} sucursal 
 * @returns {object}
 */
function getConfig(sucursal) {
  const sucursalNormalizada = sucursal.toLowerCase().replace(/\s+/g, '');
  return configs[sucursalNormalizada];
}

/**
 * Lista de sucursales disponibles
 */
const SUCURSALES = ['sanjose', 'limon', 'corporativo'];

module.exports = { 
  sql, 
  getPool,
  closeAllPools,
  getConfig,
  SUCURSALES,
  WSL_HOST
};
