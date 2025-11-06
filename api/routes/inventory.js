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

// Endpoints auxiliares para obtener datos de referencia
router.get('/reference/suppliers', async (req, res) => {
  try {
    const r = await pool.request().execute('SP_GetSuppliersForProducts');
    res.json(r.recordset);
  } catch (e) {
    console.error('SP_GetSuppliersForProducts:', e);
    res.status(500).json({ error: 'Error consultando proveedores' });
  }
});

router.get('/reference/colors', async (req, res) => {
  try {
    const r = await pool.request().execute('SP_GetColorsForProducts');
    res.json(r.recordset);
  } catch (e) {
    console.error('SP_GetColorsForProducts:', e);
    res.status(500).json({ error: 'Error consultando colores' });
  }
});

router.get('/reference/packages', async (req, res) => {
  try {
    const r = await pool.request().execute('SP_GetPackageTypesForProducts');
    res.json(r.recordset);
  } catch (e) {
    console.error('SP_GetPackageTypesForProducts:', e);
    res.status(500).json({ error: 'Error consultando tipos de empaque' });
  }
});

router.get('/reference/stockgroups', async (req, res) => {
  try {
    const r = await pool.request().execute('SP_GetStockGroupsForProducts');
    res.json(r.recordset);
  } catch (e) {
    console.error('SP_GetStockGroupsForProducts:', e);
    res.status(500).json({ error: 'Error consultando grupos de productos' });
  }
});

router.get('/reference/stockgroups/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (Number.isNaN(id)) return res.status(400).json({ error: 'ID inválido' });
  
  try {
    const r = await pool.request()
      .input('StockItemID', sql.Int, id)
      .execute('SP_GetProductStockGroups');
    res.json(r.recordset);
  } catch (e) {
    console.error('SP_GetProductStockGroups:', e);
    res.status(500).json({ error: 'Error consultando grupos del producto' });
  }
});

// Verificar si un producto puede ser eliminado
router.get('/check/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (Number.isNaN(id)) return res.status(400).json({ error: 'ID inválido' });
  
  try {
    // Verificar si existe
    const existsResult = await pool.request()
      .input('StockItemID', sql.Int, id)
      .execute('SP_CheckProductExists');
    
    const exists = existsResult?.recordset?.[0]?.ProductExists;
    
    if (!exists) {
      return res.json({ 
        exists: false, 
        canDelete: false, 
        reason: 'El producto no existe' 
      });
    }

    // Verificar transacciones críticas
    const criticalResult = await pool.request()
      .input('StockItemID', sql.Int, id)
      .execute('SP_CheckProductCriticalTransactions');
    
    const critical = criticalResult?.recordset?.[0];
    const canDelete = !critical?.HasCriticalTransactions;
    
    res.json({
      exists: true,
      canDelete: canDelete,
      invoiceCount: critical?.InvoiceCount || 0,
      purchaseOrderCount: critical?.PurchaseOrderCount || 0,
      reason: canDelete 
        ? 'El producto puede ser eliminado' 
        : 'El producto tiene transacciones asociadas y no puede ser eliminado'
    });
  } catch (e) {
    console.error('Error verificando producto:', e);
    res.status(500).json({ error: 'Error verificando producto' });
  }
});

router.post('/', async (req, res) => {
  const b = req.body || {};
  
  try {
    const r = await pool.request()
      .input('NombreProducto',          sql.NVarChar(255),  b.NombreProducto || b.StockItemName || null)
      .input('SupplierID',              sql.Int,            b.SupplierID != null ? Number(b.SupplierID) : null)
      .input('ColorID',                 sql.Int,            b.ColorID != null ? Number(b.ColorID) : null)
      .input('UnitPackageID',           sql.Int,            b.UnitPackageID != null ? Number(b.UnitPackageID) : null)
      .input('OuterPackageID',          sql.Int,            b.OuterPackageID != null ? Number(b.OuterPackageID) : null)
      .input('CantidadEmpaquetamiento', sql.Int,            (b.CantidadEmpaquetamiento != null ? Number(b.CantidadEmpaquetamiento) : (b.QuantityPerOuter != null ? Number(b.QuantityPerOuter) : null)))
      .input('Marca',                   sql.NVarChar(100),  b.Marca || b.Brand || null)
      .input('Talla',                   sql.NVarChar(50),   b.Talla || b.Size || null)
      .input('Impuesto',                sql.Decimal(5,2),   (b.Impuesto != null ? Number(b.Impuesto) : (b.TaxRate != null ? Number(b.TaxRate) : null)))
      .input('PrecioUnitario',          sql.Decimal(18,2),  (b.PrecioUnitario != null ? Number(b.PrecioUnitario) : (b.UnitPrice != null ? Number(b.UnitPrice) : null)))
      .input('PrecioVenta',             sql.Decimal(18,2),  (b.PrecioVenta != null ? Number(b.PrecioVenta) : (b.RecommendedRetailPrice != null ? Number(b.RecommendedRetailPrice) : null)))
      .input('Peso',                    sql.Decimal(10,2),  (b.Peso != null ? Number(b.Peso) : (b.TypicalWeightPerUnit != null ? Number(b.TypicalWeightPerUnit) : null)))
      .input('PalabrasClave',           sql.NVarChar(4000), b.PalabrasClave || null)
      .input('CantidadDisponible',      sql.Int,            (b.CantidadDisponible != null ? Number(b.CantidadDisponible) : (b.QuantityOnHand != null ? Number(b.QuantityOnHand) : 0)))
      .input('Ubicacion',               sql.NVarChar(100),  b.Ubicacion || b.BinLocation || null)
      .input('TiempoEntrega',           sql.Int,            (b.TiempoEntrega != null ? Number(b.TiempoEntrega) : (b.LeadTimeDays != null ? Number(b.LeadTimeDays) : 0)))
      .input('RequiereFrio',            sql.Bit,            b.RequiereFrio !== undefined ? Boolean(b.RequiereFrio) : (b.IsChillerStock !== undefined ? Boolean(b.IsChillerStock) : false))
      .input('CodigoBarras',            sql.NVarChar(100),  b.CodigoBarras || b.Barcode || null)
      .input('CamposPersonalizados',    sql.NVarChar(sql.MAX), b.CamposPersonalizados || b.CustomFields || null)
      .input('Etiquetas',               sql.NVarChar(sql.MAX), b.Etiquetas || b.Tags || null)
      .input('StockGroupIDs',           sql.NVarChar(sql.MAX), b.StockGroupIDs || null)
      .execute('SP_InsertProduct');

    const id = r?.recordset?.[0]?.NewStockItemID ?? r?.returnValue ?? null;
    res.json({ ok: true, id });
  } catch (e) {
    console.error('SP_InsertProduct:', e);
    res.status(400).json({ ok: false, error: e.message || 'Error insertando producto' });
  }
});

router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  const b  = req.body || {};
  
  try {
    const r = await pool.request()
      .input('StockItemID',             sql.Int,            id)
      .input('NombreProducto',          sql.NVarChar(255),  b.NombreProducto || b.StockItemName || null)
      .input('SupplierID',              sql.Int,            b.SupplierID != null ? Number(b.SupplierID) : null)
      .input('ColorID',                 sql.Int,            b.ColorID != null ? Number(b.ColorID) : null)
      .input('UnitPackageID',           sql.Int,            b.UnitPackageID != null ? Number(b.UnitPackageID) : null)
      .input('OuterPackageID',          sql.Int,            b.OuterPackageID != null ? Number(b.OuterPackageID) : null)
      .input('CantidadEmpaquetamiento', sql.Int,            (b.CantidadEmpaquetamiento != null ? Number(b.CantidadEmpaquetamiento) : (b.QuantityPerOuter != null ? Number(b.QuantityPerOuter) : null)))
      .input('Marca',                   sql.NVarChar(100),  b.Marca || b.Brand || null)
      .input('Talla',                   sql.NVarChar(50),   b.Talla || b.Size || null)
      .input('Impuesto',                sql.Decimal(5,2),   (b.Impuesto != null ? Number(b.Impuesto) : (b.TaxRate != null ? Number(b.TaxRate) : null)))
      .input('PrecioUnitario',          sql.Decimal(18,2),  (b.PrecioUnitario != null ? Number(b.PrecioUnitario) : (b.UnitPrice != null ? Number(b.UnitPrice) : null)))
      .input('PrecioVenta',             sql.Decimal(18,2),  (b.PrecioVenta != null ? Number(b.PrecioVenta) : (b.RecommendedRetailPrice != null ? Number(b.RecommendedRetailPrice) : null)))
      .input('Peso',                    sql.Decimal(10,2),  (b.Peso != null ? Number(b.Peso) : (b.TypicalWeightPerUnit != null ? Number(b.TypicalWeightPerUnit) : null)))
      .input('PalabrasClave',           sql.NVarChar(4000), b.PalabrasClave || null)
      .input('CantidadDisponible',      sql.Int,            (b.CantidadDisponible !== undefined ? Number(b.CantidadDisponible) : (b.QuantityOnHand !== undefined ? Number(b.QuantityOnHand) : null)))
      .input('Ubicacion',               sql.NVarChar(100),  b.Ubicacion || b.BinLocation || null)
      .input('TiempoEntrega',           sql.Int,            (b.TiempoEntrega != null ? Number(b.TiempoEntrega) : (b.LeadTimeDays != null ? Number(b.LeadTimeDays) : 0)))
      .input('RequiereFrio',            sql.Bit,            b.RequiereFrio !== undefined ? Boolean(b.RequiereFrio) : (b.IsChillerStock !== undefined ? Boolean(b.IsChillerStock) : false))
      .input('CodigoBarras',            sql.NVarChar(100),  b.CodigoBarras || b.Barcode || null)
      .input('CamposPersonalizados',    sql.NVarChar(sql.MAX), b.CamposPersonalizados || b.CustomFields || null)
      .input('Etiquetas',               sql.NVarChar(sql.MAX), b.Etiquetas || b.Tags || null)
      .input('StockGroupIDs',           sql.NVarChar(sql.MAX), b.StockGroupIDs !== undefined ? b.StockGroupIDs : null)
      .execute('SP_UpdateProduct');

    const updated = r?.recordset?.[0]?.UpdatedStockItemID ?? id;
    res.json({ ok: true, id: updated });
  } catch (e) {
    console.error('SP_UpdateProduct:', e);
    res.status(400).json({ ok: false, error: e.message || 'Error actualizando producto' });
  }
});

router.delete('/:id', async (req, res) => {
  const id = Number(req.params.id);
  try {
    // 1. Verificar si el producto existe
    const existsResult = await pool.request()
      .input('StockItemID', sql.Int, id)
      .execute('SP_CheckProductExists');
    
    const exists = existsResult?.recordset?.[0]?.ProductExists;
    if (!exists) {
      return res.status(404).json({ 
        ok: false, 
        error: 'El producto no existe' 
      });
    }

    // 2. Verificar transacciones críticas
    const criticalResult = await pool.request()
      .input('StockItemID', sql.Int, id)
      .execute('SP_CheckProductCriticalTransactions');
    
    const critical = criticalResult?.recordset?.[0];
    if (critical?.HasCriticalTransactions) {
      return res.status(400).json({ 
        ok: false, 
        error: `No se puede eliminar el producto porque tiene transacciones asociadas:\n` +
               `- Facturas de venta: ${critical.InvoiceCount}\n` +
               `- Órdenes de compra: ${critical.PurchaseOrderCount}\n\n` +
               `Estas transacciones dependen del producto y su eliminación podría afectar registros históricos.`,
        details: {
          invoiceCount: critical.InvoiceCount,
          purchaseOrderCount: critical.PurchaseOrderCount
        }
      });
    }

    // 3. Si todo está bien, proceder con la eliminación
    const r = await pool.request()
      .input('StockItemID', sql.Int, id)
      .execute('SP_DeleteProduct');

    const deleted = r?.recordset?.[0]?.DeletedStockItemID ?? id;
    res.json({ ok: true, id: deleted });
  } catch (e) {
    console.error('SP_DeleteProduct:', e);
    res.status(400).json({ ok: false, error: e.message || 'Error eliminando producto' });
  }
});

module.exports = router;
