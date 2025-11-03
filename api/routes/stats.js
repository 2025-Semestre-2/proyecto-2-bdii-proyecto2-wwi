const express = require('express');
const { sql, config } = require('../config');
const router = express.Router();

let pool;
sql.connect(config)
  .then(p => { pool = p; console.log('Estadísticas listo'); })
  .catch(err => console.error('Estadísticas - conexión:', err.message));

router.get('/compras', async (req, res) => {
  const { supplier, category } = req.query;
  try {
    const r = await pool.request()
      .input('supplier', sql.NVarChar, supplier || null)
      .input('category', sql.NVarChar, category || null)
      .execute('sp_estadisticasCompras');
    res.json(r.recordset);
  } catch (e) {
    console.error('sp_estadisticasCompras:', e);
    res.status(500).json({ error: 'Error en estadísticas de compras' });
  }
});

router.get('/ventas', async (req, res) => {
  const { customer, category } = req.query;
  try {
    const r = await pool.request()
      .input('customer', sql.NVarChar, customer || null)
      .input('category', sql.NVarChar, category || null)
      .execute('sp_estadisticasVentas');
    res.json(r.recordset);
  } catch (e) {
    console.error('sp_estadisticasVentas:', e);
    res.status(500).json({ error: 'Error en estadísticas de ventas' });
  }
});

router.get('/top-productos', async (req, res) => {
  const year = req.query.year ? Number(req.query.year) : null;
  if (req.query.year && Number.isNaN(year)) {
    return res.status(400).json({ error: 'year inválido' });
  }
  try {
    const r = await pool.request()
      .input('year', sql.Int, year)
      .execute('sp_estadisticasGananciasProductosAnio');
    res.json(r.recordset);
  } catch (e) {
    console.error('sp_estadisticasGananciasProductosAnio:', e);
    res.status(500).json({ error: 'Error en top de productos' });
  }
});

router.get('/top-clientes', async (req, res) => {
  const fromyear = req.query.fromyear ? Number(req.query.fromyear) : null;
  const toyear   = req.query.toyear   ? Number(req.query.toyear)   : null;
  if ((req.query.fromyear && Number.isNaN(fromyear)) ||
      (req.query.toyear   && Number.isNaN(toyear))) {
    return res.status(400).json({ error: 'fromyear/toyear inválidos' });
  }
  try {
    const r = await pool.request()
      .input('fromyear', sql.Int, fromyear)
      .input('toyear',   sql.Int, toyear)
      .execute('sp_estadisticasClientesMayorGananciaAnio'); 
    res.json(r.recordset);
  } catch (e) {
    console.error('sp_estadisticasClientesMayorGananciaAnio:', e);
    res.status(500).json({ error: 'Error en top de clientes' });
  }
});

router.get('/top-proveedores', async (req, res) => {
  const fromyear = req.query.fromyear ? Number(req.query.fromyear) : null;
  const toyear   = req.query.toyear   ? Number(req.query.toyear)   : null;
  if ((req.query.fromyear && Number.isNaN(fromyear)) ||
      (req.query.toyear   && Number.isNaN(toyear))) {
    return res.status(400).json({ error: 'fromyear/toyear inválidos' });
  }
  try {
    const r = await pool.request()
      .input('fromyear', sql.Int, fromyear)
      .input('toyear',   sql.Int, toyear)
      .execute('sp_estadisticasProveedoresConMayoresOrdenes');
    res.json(r.recordset);
  } catch (e) {
    console.error('sp_estadisticasProveedoresConMayoresOrdenes:', e);
    res.status(500).json({ error: 'Error en top de proveedores' });
  }
});

module.exports = router;
