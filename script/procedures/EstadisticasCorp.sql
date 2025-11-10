-- ============================================================
-- STORED PROCEDURES DE ESTADÍSTICAS - CORPORATIVO
-- ============================================================
-- Procedimientos para análisis estadístico consolidado
-- Base de datos: WWI_Corporativo
-- Consolida datos de las sucursales San José y Limón
-- ============================================================

USE WWI_Corporativo;
GO

-- ============================================================
-- VISTAS CONSOLIDADAS
-- ============================================================

-- Vista: Compras por proveedor y categoría (consolidada)
CREATE OR ALTER VIEW dbo.vw_CompraProveedorCategoria
AS
-- San José
SELECT
  s.SupplierName,
  sc.SupplierCategoryName,
  po.PurchaseOrderID,
  SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS OrderAmount,
  'San José' AS Sucursal
FROM Purchasing.PurchaseOrders_SJ       AS po
JOIN Purchasing.Suppliers            AS s   ON s.SupplierID = po.SupplierID
JOIN Purchasing.SupplierCategories   AS sc  ON sc.SupplierCategoryID = s.SupplierCategoryID
JOIN Purchasing.PurchaseOrderLines_SJ   AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
GROUP BY s.SupplierName, sc.SupplierCategoryName, po.PurchaseOrderID

UNION ALL

-- Limón
SELECT
  s.SupplierName,
  sc.SupplierCategoryName,
  po.PurchaseOrderID,
  SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS OrderAmount,
  'Limón' AS Sucursal
FROM Purchasing.PurchaseOrders_Limon       AS po
JOIN Purchasing.Suppliers            AS s   ON s.SupplierID = po.SupplierID
JOIN Purchasing.SupplierCategories   AS sc  ON sc.SupplierCategoryID = s.SupplierCategoryID
JOIN Purchasing.PurchaseOrderLines_Limon   AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
GROUP BY s.SupplierName, sc.SupplierCategoryName, po.PurchaseOrderID;
GO

-- Vista: Ventas por cliente y categoría (consolidada)
CREATE OR ALTER VIEW dbo.vw_VentaClienteCategoria
AS
-- San José
SELECT
  c.CustomerName,
  sg.StockGroupName,
  i.InvoiceID,
  SUM(il.ExtendedPrice) AS InvoiceAmountByCategory,
  'San José' AS Sucursal
FROM Sales.Invoices_SJ                 AS i
JOIN Sales.Customers                AS c   ON c.CustomerID = i.CustomerID
JOIN Sales.InvoiceLines_SJ             AS il  ON il.InvoiceID = i.InvoiceID
LEFT JOIN Warehouse.StockItemStockGroups AS sgs ON sgs.StockItemID = il.StockItemID
LEFT JOIN Warehouse.StockGroups          AS sg  ON sg.StockGroupID = sgs.StockGroupID
GROUP BY c.CustomerName, sg.StockGroupName, i.InvoiceID

UNION ALL

-- Limón
SELECT
  c.CustomerName,
  sg.StockGroupName,
  i.InvoiceID,
  SUM(il.ExtendedPrice) AS InvoiceAmountByCategory,
  'Limón' AS Sucursal
FROM Sales.Invoices_Limon                 AS i
JOIN Sales.Customers                AS c   ON c.CustomerID = i.CustomerID
JOIN Sales.InvoiceLines_Limon             AS il  ON il.InvoiceID = i.InvoiceID
LEFT JOIN Warehouse.StockItemStockGroups AS sgs ON sgs.StockItemID = il.StockItemID
LEFT JOIN Warehouse.StockGroups          AS sg  ON sg.StockGroupID = sgs.StockGroupID
GROUP BY c.CustomerName, sg.StockGroupName, i.InvoiceID;
GO

-- Vista: Productos con ganancia anual (consolidada)
CREATE OR ALTER VIEW dbo.vw_ProductosGananciaAnual
AS
-- San José
SELECT
  YEAR(i.InvoiceDate) AS Year,
  il.StockItemID,
  SUM(il.ExtendedPrice)                                 AS SalesAmount,
  SUM(ISNULL(sih.LastCostPrice,0.0) * il.Quantity)      AS CostAmount,
  SUM(il.ExtendedPrice - ISNULL(sih.LastCostPrice,0.0) * il.Quantity) AS ProfitAmount,
  'San José' AS Sucursal
FROM Sales.InvoiceLines_SJ         AS il
JOIN Sales.Invoices_SJ             AS i   ON i.InvoiceID = il.InvoiceID
LEFT JOIN Warehouse.StockItemHoldings_SJ AS sih ON sih.StockItemID = il.StockItemID
GROUP BY YEAR(i.InvoiceDate), il.StockItemID

UNION ALL

-- Limón
SELECT
  YEAR(i.InvoiceDate) AS Year,
  il.StockItemID,
  SUM(il.ExtendedPrice)                                 AS SalesAmount,
  SUM(ISNULL(sih.LastCostPrice,0.0) * il.Quantity)      AS CostAmount,
  SUM(il.ExtendedPrice - ISNULL(sih.LastCostPrice,0.0) * il.Quantity) AS ProfitAmount,
  'Limón' AS Sucursal
FROM Sales.InvoiceLines_Limon         AS il
JOIN Sales.Invoices_Limon             AS i   ON i.InvoiceID = il.InvoiceID
LEFT JOIN Warehouse.StockItemHoldings_Limon AS sih ON sih.StockItemID = il.StockItemID
GROUP BY YEAR(i.InvoiceDate), il.StockItemID;
GO

-- Vista: Top clientes anual (consolidada)
CREATE OR ALTER VIEW dbo.vw_TopClientesAnual
AS
-- San José
SELECT
  YEAR(i.InvoiceDate) AS Year,
  i.CustomerID,
  COUNT(*)            AS InvoiceCount,
  SUM(il.ExtendedPrice) AS TotalAmount,
  'San José' AS Sucursal
FROM Sales.Invoices_SJ     AS i
JOIN Sales.InvoiceLines_SJ AS il ON il.InvoiceID = i.InvoiceID
GROUP BY YEAR(i.InvoiceDate), i.CustomerID

UNION ALL

-- Limón
SELECT
  YEAR(i.InvoiceDate) AS Year,
  i.CustomerID,
  COUNT(*)            AS InvoiceCount,
  SUM(il.ExtendedPrice) AS TotalAmount,
  'Limón' AS Sucursal
FROM Sales.Invoices_Limon     AS i
JOIN Sales.InvoiceLines_Limon AS il ON il.InvoiceID = i.InvoiceID
GROUP BY YEAR(i.InvoiceDate), i.CustomerID;
GO

-- Vista: Top proveedores anual (consolidada)
CREATE OR ALTER VIEW dbo.vw_TopProveedoresAnual
AS
-- San José
SELECT
  YEAR(po.OrderDate) AS Year,
  po.SupplierID,
  COUNT(DISTINCT po.PurchaseOrderID)                                AS OrderCount,
  SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter)            AS TotalAmount,
  'San José' AS Sucursal
FROM Purchasing.PurchaseOrders_SJ     AS po
JOIN Purchasing.PurchaseOrderLines_SJ AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
GROUP BY YEAR(po.OrderDate), po.SupplierID

UNION ALL

-- Limón
SELECT
  YEAR(po.OrderDate) AS Year,
  po.SupplierID,
  COUNT(DISTINCT po.PurchaseOrderID)                                AS OrderCount,
  SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter)            AS TotalAmount,
  'Limón' AS Sucursal
FROM Purchasing.PurchaseOrders_Limon     AS po
JOIN Purchasing.PurchaseOrderLines_Limon AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
GROUP BY YEAR(po.OrderDate), po.SupplierID;
GO

-- ============================================================
-- STORED PROCEDURES CONSOLIDADOS
-- ============================================================

-- SP: Estadísticas de compras por proveedor y categoría
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasCompras
  @supplier NVARCHAR(100) = NULL,
  @category NVARCHAR(100) = NULL,
  @sucursal NVARCHAR(50) = NULL  -- 'San José', 'Limón', o NULL para todas
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    SupplierName,
    SupplierCategoryName,
    Sucursal,
    MIN(OrderAmount) AS monto_minimo,
    MAX(OrderAmount) AS monto_maximo,
    AVG(OrderAmount) AS monto_promedio,
    SUM(OrderAmount) AS monto_total
  FROM dbo.vw_CompraProveedorCategoria
  WHERE (@supplier IS NULL OR SupplierName LIKE '%' + @supplier + '%')
    AND (@category IS NULL OR SupplierCategoryName LIKE '%' + @category + '%')
    AND (@sucursal IS NULL OR Sucursal = @sucursal)
  GROUP BY ROLLUP (SupplierName, SupplierCategoryName, Sucursal)
  ORDER BY SupplierName, SupplierCategoryName, Sucursal;
END;
GO

-- SP: Estadísticas de ventas por cliente y categoría
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasVentas
  @customer NVARCHAR(100) = NULL,
  @category NVARCHAR(100) = NULL,
  @sucursal NVARCHAR(50) = NULL  -- 'San José', 'Limón', o NULL para todas
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    CustomerName,
    StockGroupName,
    Sucursal,
    MIN(InvoiceAmountByCategory) AS monto_minimo,
    MAX(InvoiceAmountByCategory) AS monto_maximo,
    AVG(InvoiceAmountByCategory) AS monto_promedio,
    SUM(InvoiceAmountByCategory) AS monto_total
  FROM dbo.vw_VentaClienteCategoria
  WHERE (@customer IS NULL OR CustomerName  LIKE '%' + @customer + '%')
    AND (@category IS NULL OR StockGroupName LIKE '%' + @category + '%')
    AND (@sucursal IS NULL OR Sucursal = @sucursal)
  GROUP BY ROLLUP (CustomerName, StockGroupName, Sucursal)
  ORDER BY CustomerName, StockGroupName, Sucursal;
END;
GO

-- SP: Estadísticas de ganancias por producto y año
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasGananciasProductosAnio
  @year     INT = NULL,
  @sucursal NVARCHAR(50) = NULL  -- 'San José', 'Limón', o NULL para consolidado
AS
BEGIN
  SET NOCOUNT ON;

  IF @sucursal IS NULL
  BEGIN
    -- Consolidado: agrupa por año y producto sumando ambas sucursales
    WITH consolidated AS (
      SELECT
        v.Year,
        v.StockItemID,
        SUM(v.SalesAmount)  AS SalesAmount,
        SUM(v.CostAmount)   AS CostAmount,
        SUM(v.ProfitAmount) AS ProfitAmount
      FROM dbo.vw_ProductosGananciaAnual v
      WHERE (@year IS NULL OR v.Year = @year)
      GROUP BY v.Year, v.StockItemID
    ),
    ranked AS (
      SELECT
        Year,
        StockItemID,
        SalesAmount,
        CostAmount,
        ProfitAmount,
        DENSE_RANK() OVER (PARTITION BY Year ORDER BY ProfitAmount DESC) AS rnk
      FROM consolidated
    )
    SELECT 
      r.Year, 
      si.StockItemName, 
      r.SalesAmount, 
      r.CostAmount, 
      r.ProfitAmount, 
      r.rnk,
      'Consolidado' AS Sucursal
    FROM ranked r
    JOIN Warehouse.StockItems si ON si.StockItemID = r.StockItemID
    WHERE r.rnk <= 5
    ORDER BY r.Year, r.rnk;
  END
  ELSE
  BEGIN
    -- Por sucursal específica
    WITH r AS (
      SELECT
        v.Year,
        v.StockItemID,
        v.SalesAmount,
        v.CostAmount,
        v.ProfitAmount,
        v.Sucursal,
        DENSE_RANK() OVER (PARTITION BY v.Year, v.Sucursal ORDER BY v.ProfitAmount DESC) AS rnk
      FROM dbo.vw_ProductosGananciaAnual v
      WHERE (@year IS NULL OR v.Year = @year)
        AND v.Sucursal = @sucursal
    )
    SELECT 
      r.Year, 
      si.StockItemName, 
      r.SalesAmount, 
      r.CostAmount, 
      r.ProfitAmount, 
      r.rnk,
      r.Sucursal
    FROM r
    JOIN Warehouse.StockItems si ON si.StockItemID = r.StockItemID
    WHERE r.rnk <= 5
    ORDER BY r.Year, r.rnk;
  END
END;
GO

-- SP: Estadísticas de clientes con mayor ganancia por año
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasClientesMayorGananciaAnio
  @fromyear INT = NULL, 
  @toyear   INT = NULL,
  @sucursal NVARCHAR(50) = NULL  -- 'San José', 'Limón', o NULL para consolidado
AS
BEGIN
  SET NOCOUNT ON;

  IF @sucursal IS NULL
  BEGIN
    -- Consolidado: agrupa por año y cliente sumando ambas sucursales
    WITH consolidated AS (
      SELECT
        v.Year,
        v.CustomerID,
        SUM(v.InvoiceCount) AS InvoiceCount,
        SUM(v.TotalAmount)  AS TotalAmount
      FROM dbo.vw_TopClientesAnual v
      WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
        AND (@toyear   IS NULL OR v.Year <= @toyear)
      GROUP BY v.Year, v.CustomerID
    ),
    ranked AS (
      SELECT
        Year,
        CustomerID,
        InvoiceCount,
        TotalAmount,
        DENSE_RANK() OVER (PARTITION BY Year ORDER BY InvoiceCount DESC) AS rnk
      FROM consolidated
    )
    SELECT 
      r.Year, 
      c.CustomerName, 
      r.InvoiceCount, 
      r.TotalAmount, 
      r.rnk,
      'Consolidado' AS Sucursal
    FROM ranked r
    JOIN Sales.Customers c ON c.CustomerID = r.CustomerID
    WHERE r.rnk <= 5
    ORDER BY r.Year, r.rnk;
  END
  ELSE
  BEGIN
    -- Por sucursal específica
    WITH r AS (
      SELECT
        v.Year,
        v.CustomerID,
        v.InvoiceCount,
        v.TotalAmount,
        v.Sucursal,
        DENSE_RANK() OVER (PARTITION BY v.Year, v.Sucursal ORDER BY v.InvoiceCount DESC) AS rnk
      FROM dbo.vw_TopClientesAnual v
      WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
        AND (@toyear   IS NULL OR v.Year <= @toyear)
        AND v.Sucursal = @sucursal
    )
    SELECT 
      r.Year, 
      c.CustomerName, 
      r.InvoiceCount, 
      r.TotalAmount, 
      r.rnk,
      r.Sucursal
    FROM r
    JOIN Sales.Customers c ON c.CustomerID = r.CustomerID
    WHERE r.rnk <= 5
    ORDER BY r.Year, r.rnk;
  END
END;
GO

-- SP: Estadísticas de proveedores con mayores órdenes
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasProveedoresConMayoresOrdenes
  @fromyear INT = NULL, 
  @toyear   INT = NULL,
  @sucursal NVARCHAR(50) = NULL  -- 'San José', 'Limón', o NULL para consolidado
AS
BEGIN
  SET NOCOUNT ON;

  IF @sucursal IS NULL
  BEGIN
    -- Consolidado: agrupa por año y proveedor sumando ambas sucursales
    WITH consolidated AS (
      SELECT
        v.Year,
        v.SupplierID,
        SUM(v.OrderCount)  AS OrderCount,
        SUM(v.TotalAmount) AS TotalAmount
      FROM dbo.vw_TopProveedoresAnual v
      WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
        AND (@toyear   IS NULL OR v.Year <= @toyear)
      GROUP BY v.Year, v.SupplierID
    ),
    ranked AS (
      SELECT
        Year,
        SupplierID,
        OrderCount,
        TotalAmount,
        DENSE_RANK() OVER (PARTITION BY Year ORDER BY OrderCount DESC) AS rnk
      FROM consolidated
    )
    SELECT 
      r.Year, 
      s.SupplierName, 
      r.OrderCount, 
      r.TotalAmount, 
      r.rnk,
      'Consolidado' AS Sucursal
    FROM ranked r
    JOIN Purchasing.Suppliers s ON s.SupplierID = r.SupplierID
    WHERE r.rnk <= 5
    ORDER BY r.Year, r.rnk;
  END
  ELSE
  BEGIN
    -- Por sucursal específica
    WITH r AS (
      SELECT
        v.Year,
        v.SupplierID,
        v.OrderCount,
        v.TotalAmount,
        v.Sucursal,
        DENSE_RANK() OVER (PARTITION BY v.Year, v.Sucursal ORDER BY v.OrderCount DESC) AS rnk
      FROM dbo.vw_TopProveedoresAnual v
      WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
        AND (@toyear   IS NULL OR v.Year <= @toyear)
        AND v.Sucursal = @sucursal
    )
    SELECT 
      r.Year, 
      s.SupplierName, 
      r.OrderCount, 
      r.TotalAmount, 
      r.rnk,
      r.Sucursal
    FROM r
    JOIN Purchasing.Suppliers s ON s.SupplierID = r.SupplierID
    WHERE r.rnk <= 5
    ORDER BY r.Year, r.rnk;
  END
END;
GO

PRINT '✅ Stored Procedures y Vistas de Estadísticas creados para CORPORATIVO';
PRINT '';
PRINT 'VISTAS consolidadas:';
PRINT '  • vw_CompraProveedorCategoria - Compras consolidadas de ambas sucursales';
PRINT '  • vw_VentaClienteCategoria - Ventas consolidadas de ambas sucursales';
PRINT '  • vw_ProductosGananciaAnual - Ganancias por producto consolidadas';
PRINT '  • vw_TopClientesAnual - Top clientes consolidados';
PRINT '  • vw_TopProveedoresAnual - Top proveedores consolidados';
PRINT '';
PRINT 'STORED PROCEDURES:';
PRINT '  • sp_estadisticasCompras - Estadísticas de compras (con filtro por sucursal)';
PRINT '  • sp_estadisticasVentas - Estadísticas de ventas (con filtro por sucursal)';
PRINT '  • sp_estadisticasGananciasProductosAnio - Top 5 productos por ganancia';
PRINT '  • sp_estadisticasClientesMayorGananciaAnio - Top 5 clientes por facturación';
PRINT '  • sp_estadisticasProveedoresConMayoresOrdenes - Top 5 proveedores por órdenes';
PRINT '';
PRINT '⚠️  NOTA: Todos los procedures aceptan parámetro @sucursal:';
PRINT '    - NULL: Datos consolidados de ambas sucursales';
PRINT '    - ''San José'': Solo datos de San José';
PRINT '    - ''Limón'': Solo datos de Limón';
PRINT '';
PRINT '📊 Las vistas utilizan UNION ALL para combinar datos de:';
PRINT '    - Invoices_SJ + Invoices_Limon';
PRINT '    - PurchaseOrders_SJ + PurchaseOrders_Limon';
PRINT '    - StockItemHoldings_SJ + StockItemHoldings_Limon';
GO
