const express = require('express');
const { sql, config } = require('../config');
const router = express.Router();

let pool;
sql.connect(config)
  .then(p => { pool = p; console.log('Proveedores listo'); })
  .catch(err => console.error('Proveedores - conexión:', err.message));

router.get('/', async (req, res) => {
  const { search, category } = req.query;

  try {
    const poolConn = await pool;
    const result = await poolConn
      .request()
      .input('search', sql.NVarChar, search?.trim() || null)
      .input('category', sql.NVarChar, category?.trim() || null)
      .execute('dbo.sp_obtenerProveedores');

    res.json(result.recordset || []);
  } catch (e) {
    console.error('Error en sp_obtenerProveedores:', e.message);
    res.status(500).json({ error: 'Error consultando proveedores' });
  }
});

router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const r = await pool.request()
      .input('supplierid', sql.Int, id)
      .execute('sp_obtenerDetalleProveedor');

    res.json({
      general: r.recordset[0] || null,
    });
  } catch (e) {
    console.error('sp_obtenerDetalleProveedor:', e);
    res.status(500).json({ error: 'Error consultando detalle de proveedor' });
  }
});

module.exports = router;
