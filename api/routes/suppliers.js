const express = require('express');
const { sql, getPool } = require('../config');
const router = express.Router();

// ============================================================
// GET /api/proveedores
// Obtiene lista de proveedores con filtros opcionales
// ============================================================
router.get('/', async (req, res) => {
  const { search, category } = req.query;

  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('search', sql.NVarChar, search?.trim() || null)
      .input('category', sql.NVarChar, category?.trim() || null)
      .execute('dbo.sp_obtenerProveedores');

    res.json(result.recordset || []);
  } catch (error) {
    console.error(` Error en sp_obtenerProveedores (${req.sucursal}):`, error.message);
    res.status(500).json({ 
      error: 'Error consultando proveedores',
      details: error.message 
    });
  }
});

// ============================================================
// GET /api/proveedores/:id
// Obtiene detalle de un proveedor específico
// ============================================================
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('supplierid', sql.Int, id)
      .execute('sp_obtenerDetalleProveedor');

    res.json({
      general: result.recordset[0] || null,
    });
  } catch (error) {
    console.error(` Error en sp_obtenerDetalleProveedor (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error consultando detalle de proveedor',
      details: error.message 
    });
  }
});

module.exports = router;
