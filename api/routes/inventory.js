const express = require('express');
const { sql, config } = require('../config');
const router = express.Router();

let pool;
sql.connect(config)
  .then(p => { pool = p; console.log('Inventario listo'); })
  .catch(err => console.error('Inventario - conexión:', err.message));

router.get('/', async (req, res) => {
  const { search, group } = req.query;
  try {
    const r = await pool.request()
      .input('search', sql.NVarChar, search || null)
      .input('group',  sql.NVarChar, group  || null)
      .execute('sp_obtenerInventario');
    res.json(r.recordset);
  } catch (e) {
    console.error('sp_obtenerInventario:', e);
    res.status(500).json({ error: 'Error consultando inventario' });
  }
});

router.get('/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (Number.isNaN(id)) return res.status(400).json({ error: 'ID inválido' });

  try {
    const r = await pool.request()
      .input('stockitemid', sql.Int, id)
      .execute('dbo.sp_obtenerDetalleInventario');

    const [gen = [], hold = [], prov = []] = r.recordsets || [];
    res.json({
      general:   gen[0]   || null,
      holdings:  hold[0]  || null,
      proveedor: prov[0]  || null,
    });
  } catch (e) {
    console.error('sp_obtenerDetalleInventario:', e);
    res.status(500).json({ error: 'Error consultando detalle de inventario' });
  }
});

router.post('/', async (req, res) => {
  const b = req.body || {};
  try {
    const r = await pool.request()
      .input('StockItemName',          sql.NVarChar,  b.StockItemName)
      .input('SupplierID',             sql.Int,       Number(b.SupplierID))
      .input('UnitPackageID',          sql.Int,       Number(b.UnitPackageID))
      .input('OuterPackageID',         sql.Int,       Number(b.OuterPackageID))
      .input('QuantityPerOuter',       sql.Int,       Number(b.QuantityPerOuter))
      .input('UnitPrice',              sql.Decimal(18,2), Number(b.UnitPrice))
      .input('RecommendedRetailPrice', sql.Decimal(18,2), Number(b.RecommendedRetailPrice))
      .input('TaxRate',                sql.Decimal(18,3), Number(b.TaxRate))
      .input('TypicalWeightPerUnit',   sql.Decimal(18,3), Number(b.TypicalWeightPerUnit))
      .execute('sp_inventario_insertar');

    const id = r?.recordset?.[0]?.NewStockItemID ?? r?.returnValue ?? null;
    res.json({ ok: true, id });
  } catch (e) {
    console.error('sp_inventario_insertar:', e);
    res.status(400).json({ ok: false, error: e.message || 'Error insertando item' });
  }
});

router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  const b  = req.body || {};
  try {
    const r = await pool.request()
      .input('StockItemID',            sql.Int,       id)
      .input('StockItemName',          sql.NVarChar,  b.StockItemName)
      .input('SupplierID',             sql.Int,       Number(b.SupplierID))
      .input('UnitPackageID',          sql.Int,       Number(b.UnitPackageID))
      .input('OuterPackageID',         sql.Int,       Number(b.OuterPackageID))
      .input('QuantityPerOuter',       sql.Int,       Number(b.QuantityPerOuter))
      .input('UnitPrice',              sql.Decimal(18,2), Number(b.UnitPrice))
      .input('RecommendedRetailPrice', sql.Decimal(18,2), Number(b.RecommendedRetailPrice))
      .input('TaxRate',                sql.Decimal(18,3), Number(b.TaxRate))
      .input('TypicalWeightPerUnit',   sql.Decimal(18,3), Number(b.TypicalWeightPerUnit))
      .execute('sp_inventario_actualizar');

    const updated = r?.recordset?.[0]?.UpdatedStockItemID ?? id;
    res.json({ ok: true, id: updated });
  } catch (e) {
    console.error('sp_inventario_actualizar:', e);
    res.status(400).json({ ok: false, error: e.message || 'Error actualizando item' });
  }
});


router.delete('/:id', async (req, res) => {
  const id = Number(req.params.id);
  try {
    const r = await pool.request()
      .input('StockItemID', sql.Int, id)
      .execute('sp_inventario_eliminar');

    const deleted = r?.recordset?.[0]?.DeletedStockItemID ?? id;
    res.json({ ok: true, id: deleted });
  } catch (e) {
    console.error('sp_inventario_eliminar:', e);
    res.status(400).json({ ok: false, error: e.message || 'Error eliminando item' });
  }
});

module.exports = router;
