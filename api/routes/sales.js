const express = require('express');
const { sql, config } = require('../config');
const router = express.Router();

let pool;
sql.connect(config)
  .then(p => { pool = p; console.log('Ventas listo'); })
  .catch(err => console.error('Ventas - conexión:', err.message));

router.get('/', async (req, res) => {
  const { client, from, to } = req.query;
  const min = req.query.min ?? req.query.minamt;  
  const max = req.query.max ?? req.query.maxamt;

  const page  = Math.max(parseInt(req.query.page, 10)  || 1, 1);
  const limit = Math.max(parseInt(req.query.limit, 10) || 50, 1);

  try {
    const r = await pool.request()
      .input('client', sql.NVarChar, client || null)
      .input('from',   sql.Date,     from   || null)
      .input('to',     sql.Date,     to     || null)
      .input('minamt', sql.Decimal(18,2), min ? Number(min) : null)
      .input('maxamt', sql.Decimal(18,2), max ? Number(max) : null)
      .execute('sp_obtenerVentas');

    const all   = r.recordset || [];
    const total = all.length;
    const start = (page - 1) * limit;
    const rows  = all.slice(start, start + limit); 

    res.json({ rows, total }); 
  } catch (e) {
    console.error('sp_obtenerVentas:', e);
    res.status(500).json({ error: 'Error consultando ventas' });
  }
});

router.get('/:id', async (req, res) => {
  const id = Number.parseInt(req.params.id, 10);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ error: 'InvoiceID inválido' });
  }

  try {
    const r = await pool.request()
      .input('invoiceid', sql.Int, id)
      .execute('sp_obtenerDetalleVentas');  

    const header = r.recordsets?.[0]?.[0] || null;
    const lines  = r.recordsets?.[1] || [];

    if (!header) {
      return res.status(404).json({ error: 'Factura no encontrada' });
    }

    res.json({ header, lines });
  } catch (e) {
    console.error('sp_obtenerDetalleVentas:', e);
    res.status(500).json({ error: 'Error consultando detalle de factura' });
  }
});

module.exports = router;
