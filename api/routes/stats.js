const express = require('express');
const { sql, getPool } = require('../config');
const router = express.Router();

// ============================================================
// GET /api/estadisticas/compras
// Estadísticas de compras por proveedor y categoría
// ============================================================
router.get('/compras', async (req, res) => {
  const { supplier, category, sucursal } = req.query;
  
  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('supplier', sql.NVarChar, supplier || null)
      .input('category', sql.NVarChar, category || null)
      .input('sucursal', sql.NVarChar, sucursal || null)
      .execute('sp_estadisticasCompras');
    
    res.json(result.recordset);
  } catch (error) {
    console.error(` Error en sp_estadisticasCompras (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error en estadísticas de compras',
      details: error.message 
    });
  }
});

// ============================================================
// GET /api/estadisticas/ventas
// Estadísticas de ventas por cliente y categoría
// ============================================================
router.get('/ventas', async (req, res) => {
  const { customer, category, sucursal } = req.query;
  
  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('customer', sql.NVarChar, customer || null)
      .input('category', sql.NVarChar, category || null)
      .input('sucursal', sql.NVarChar, sucursal || null)
      .execute('sp_estadisticasVentas');
    
    res.json(result.recordset);
  } catch (error) {
    console.error(` Error en sp_estadisticasVentas (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error en estadísticas de ventas',
      details: error.message 
    });
  }
});

// ============================================================
// GET /api/estadisticas/top-productos
// Top productos por ganancias en un año específico
// ============================================================
router.get('/top-productos', async (req, res) => {
  const year = req.query.year ? Number(req.query.year) : null;
  const sucursal = req.query.sucursal;
  
  if (req.query.year && Number.isNaN(year)) {
    return res.status(400).json({ error: 'year inválido' });
  }
  
  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('year', sql.Int, year)
      .input('sucursal', sql.NVarChar, sucursal || null)
      .execute('sp_estadisticasGananciasProductosAnio');
    
    res.json(result.recordset);
  } catch (error) {
    console.error(` Error en sp_estadisticasGananciasProductosAnio (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error en top de productos',
      details: error.message 
    });
  }
});

// ============================================================
// GET /api/estadisticas/top-clientes
// Top clientes por ganancias en rango de años
// ============================================================
router.get('/top-clientes', async (req, res) => {
  const fromyear = req.query.fromyear ? Number(req.query.fromyear) : null;
  const toyear   = req.query.toyear   ? Number(req.query.toyear)   : null;
  const sucursal = req.query.sucursal;
  
  if ((req.query.fromyear && Number.isNaN(fromyear)) ||
      (req.query.toyear   && Number.isNaN(toyear))) {
    return res.status(400).json({ error: 'fromyear/toyear inválidos' });
  }
  
  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('fromyear', sql.Int, fromyear)
      .input('toyear',   sql.Int, toyear)
      .input('sucursal', sql.NVarChar, sucursal || null)
      .execute('sp_estadisticasClientesMayorGananciaAnio'); 
    
    res.json(result.recordset);
  } catch (error) {
    console.error(` Error en sp_estadisticasClientesMayorGananciaAnio (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error en top de clientes',
      details: error.message 
    });
  }
});

// ============================================================
// GET /api/estadisticas/top-proveedores
// Top proveedores por cantidad de órdenes en rango de años
// ============================================================
router.get('/top-proveedores', async (req, res) => {
  const fromyear = req.query.fromyear ? Number(req.query.fromyear) : null;
  const toyear   = req.query.toyear   ? Number(req.query.toyear)   : null;
  const sucursal = req.query.sucursal;
  
  if ((req.query.fromyear && Number.isNaN(fromyear)) ||
      (req.query.toyear   && Number.isNaN(toyear))) {
    return res.status(400).json({ error: 'fromyear/toyear inválidos' });
  }
  
  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('fromyear', sql.Int, fromyear)
      .input('toyear',   sql.Int, toyear)
      .input('sucursal', sql.NVarChar, sucursal || null)
      .execute('sp_estadisticasProveedoresConMayoresOrdenes');
    
    res.json(result.recordset);
  } catch (error) {
    console.error(` Error en sp_estadisticasProveedoresConMayoresOrdenes (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error en top de proveedores',
      details: error.message 
    });
  }
});

module.exports = router;
