const express = require('express');
const { sql, getPool } = require('../config');
const router = express.Router();

// ============================================================
// GET /api/clientes
// Obtiene lista de clientes de la sucursal especificada
// ============================================================
router.get('/', async (req, res) => {
  try {
    // Obtener pool de la sucursal (viene de middleware en api.js)
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('search', sql.NVarChar, req.query.search || null)
      .execute('sp_obtenerClientes');
    
    res.json(result.recordset);
  } catch (error) {
    console.error(`Error en sp_obtenerClientes (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error consultando clientes',
      details: error.message 
    });
  }
});

// ============================================================
// GET /api/clientes/:id
// Obtiene detalle completo de un cliente específico
// ============================================================
router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  
  if (Number.isNaN(id)) {
    return res.status(400).json({ error: 'ID inválido' });
  }

  try {
    // Obtener pool de la sucursal
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('customerid', sql.Int, id)
      .execute('sp_obtenerDetalleCliente');

    const general = result.recordsets?.[0]?.[0] || null;
    const contactos = result.recordsets?.[1] || [];
    const metodos = result.recordsets?.[2] || [];

    if (!general) {
      return res.status(404).json({ error: 'Cliente no encontrado' });
    }

    res.json({ 
      general, 
      contactos, 
      metodos 
    });
  } catch (error) {
    console.error(`Error en sp_obtenerDetalleCliente (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error consultando detalle de cliente',
      details: error.message 
    });
  }
});

module.exports = router;
