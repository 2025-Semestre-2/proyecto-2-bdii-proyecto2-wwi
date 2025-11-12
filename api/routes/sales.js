const express = require('express');
const { sql, getPool } = require('../config');
const router = express.Router();

// ============================================================
// GET /api/ventas
// Obtiene lista de ventas con filtros y paginación
// ============================================================
router.get('/', async (req, res) => {
  const { client, from, to } = req.query;
  const min = req.query.min ?? req.query.minamt;  
  const max = req.query.max ?? req.query.maxamt;

  const page  = Math.max(parseInt(req.query.page, 10)  || 1, 1);
  const limit = Math.max(parseInt(req.query.limit, 10) || 50, 1);

  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('client', sql.NVarChar, client || null)
      .input('from',   sql.Date,     from   || null)
      .input('to',     sql.Date,     to     || null)
      .input('minamt', sql.Decimal(18,2), min ? Number(min) : null)
      .input('maxamt', sql.Decimal(18,2), max ? Number(max) : null)
      .execute('sp_obtenerVentas');

    const all   = result.recordset || [];
    const total = all.length;
    const start = (page - 1) * limit;
    const rows  = all.slice(start, start + limit); 

    res.json({ rows, total }); 
  } catch (error) {
    console.error(` Error en sp_obtenerVentas (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error consultando ventas',
      details: error.message 
    });
  }
});

// ============================================================
// GET /api/ventas/:id
// Obtiene detalle completo de una factura de venta
// ============================================================
router.get('/:id', async (req, res) => {
  const id = Number.parseInt(req.params.id, 10);
  
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ error: 'InvoiceID inválido' });
  }

  try {
    const pool = await getPool(req.sucursal);
    
    const result = await pool.request()
      .input('invoiceid', sql.Int, id)
      .execute('sp_obtenerDetalleVentas');  

    const header = result.recordsets?.[0]?.[0] || null;
    const lines  = result.recordsets?.[1] || [];

    if (!header) {
      return res.status(404).json({ error: 'Factura no encontrada' });
    }

    res.json({ header, lines });
  } catch (error) {
    console.error(` Error en sp_obtenerDetalleVentas (${req.sucursal}):`, error);
    res.status(500).json({ 
      error: 'Error consultando detalle de factura',
      details: error.message 
    });
  }
});

module.exports = router;
