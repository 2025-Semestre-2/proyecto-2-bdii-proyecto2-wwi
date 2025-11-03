const express = require('express');
const { sql, config } = require('../config');
const router = express.Router();

let pool;
sql.connect(config)
  .then(p => { pool = p; console.log('Clientes listo'); })
  .catch(err => console.error('Clientes - conexión:', err.message));

router.get('/', async (req, res) => {
  try {
    const r = await pool.request()
      .input('search', sql.NVarChar, req.query.search || null)
      .execute('sp_obtenerClientes');
    res.json(r.recordset);
  } catch (e) {
    console.error('sp_obtenerClientes:', e);
    res.status(500).json({ error: 'Error consultando clientes' });
  }
});

router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (Number.isNaN(id)) return res.status(400).json({ error: 'id inválido' });

  try {
    const r = await pool.request()
      .input('customerid', sql.Int, id)
      .execute('sp_obtenerDetalleCliente');

    const general  = r.recordsets?.[0]?.[0] || null;
    const contactos = r.recordsets?.[1] || [];
    const metodos   = r.recordsets?.[2] || [];

    if (!general) return res.status(404).json({ error: 'Cliente no encontrado' });

    res.json({ general, contactos, metodos });
  } catch (e) {
    console.error('sp_obtenerDetalleCliente:', e);
    res.status(500).json({ error: 'Error consultando detalle de cliente' });
  }
});

module.exports = router;
