USE WideWorldImporters;
GO

CREATE OR ALTER VIEW dbo.vw_CompraProveedorCategoria
AS
SELECT
  s.SupplierName,
  sc.SupplierCategoryName,
  po.PurchaseOrderID,
  SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS OrderAmount
FROM Purchasing.PurchaseOrders       AS po
JOIN Purchasing.Suppliers            AS s   ON s.SupplierID = po.SupplierID
JOIN Purchasing.SupplierCategories   AS sc  ON sc.SupplierCategoryID = s.SupplierCategoryID
JOIN Purchasing.PurchaseOrderLines   AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
GROUP BY s.SupplierName, sc.SupplierCategoryName, po.PurchaseOrderID;
GO

CREATE OR ALTER VIEW dbo.vw_VentaClienteCategoria
AS
SELECT
  c.CustomerName,
  sg.StockGroupName,
  i.InvoiceID,
  SUM(il.ExtendedPrice) AS InvoiceAmountByCategory
FROM Sales.Invoices                 AS i
JOIN Sales.Customers                AS c   ON c.CustomerID = i.CustomerID
JOIN Sales.InvoiceLines             AS il  ON il.InvoiceID = i.InvoiceID
LEFT JOIN Warehouse.StockItemStockGroups AS sgs ON sgs.StockItemID = il.StockItemID
LEFT JOIN Warehouse.StockGroups          AS sg  ON sg.StockGroupID = sgs.StockGroupID
GROUP BY c.CustomerName, sg.StockGroupName, i.InvoiceID;
GO

CREATE OR ALTER VIEW dbo.vw_ProductosGananciaAnual
AS
SELECT
  YEAR(i.InvoiceDate) AS Year,
  il.StockItemID,
  SUM(il.ExtendedPrice)                                 AS SalesAmount,
  SUM(ISNULL(sih.LastCostPrice,0.0) * il.Quantity)      AS CostAmount,
  SUM(il.ExtendedPrice - ISNULL(sih.LastCostPrice,0.0) * il.Quantity) AS ProfitAmount
FROM Sales.InvoiceLines         AS il
JOIN Sales.Invoices             AS i   ON i.InvoiceID = il.InvoiceID
LEFT JOIN Warehouse.StockItemHoldings AS sih ON sih.StockItemID = il.StockItemID
GROUP BY YEAR(i.InvoiceDate), il.StockItemID;
GO

CREATE OR ALTER VIEW dbo.vw_TopClientesAnual
AS
SELECT
  YEAR(i.InvoiceDate) AS Year,
  i.CustomerID,
  COUNT(*)            AS InvoiceCount,
  SUM(il.ExtendedPrice) AS TotalAmount
FROM Sales.Invoices     AS i
JOIN Sales.InvoiceLines AS il ON il.InvoiceID = i.InvoiceID
GROUP BY YEAR(i.InvoiceDate), i.CustomerID;
GO

CREATE OR ALTER VIEW dbo.vw_TopProveedoresAnual
AS
SELECT
  YEAR(po.OrderDate) AS Year,
  po.SupplierID,
  COUNT(DISTINCT po.PurchaseOrderID)                                AS OrderCount,
  SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter)            AS TotalAmount
FROM Purchasing.PurchaseOrders     AS po
JOIN Purchasing.PurchaseOrderLines AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
GROUP BY YEAR(po.OrderDate), po.SupplierID;
GO

--==============================Stored Procedures==================================

CREATE OR ALTER PROCEDURE dbo.sp_estadisticasCompras
  @supplier NVARCHAR(100) = NULL,
  @category NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    SupplierName,
    SupplierCategoryName,
    MIN(OrderAmount) AS monto_minimo,
    MAX(OrderAmount) AS monto_maximo,
    AVG(OrderAmount) AS monto_promedio,
    SUM(OrderAmount) AS monto_total
  FROM dbo.vw_CompraProveedorCategoria
  GROUP BY ROLLUP (SupplierName, SupplierCategoryName)
  HAVING
    (@supplier IS NULL OR SupplierName LIKE '%' + @supplier + '%')
    AND (@category IS NULL OR SupplierCategoryName LIKE '%' + @category + '%')
  ORDER BY SupplierName, SupplierCategoryName;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasCompras
  @supplier NVARCHAR(100) = NULL,
  @category NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    SupplierName,
    SupplierCategoryName,
    MIN(OrderAmount) AS monto_minimo,
    MAX(OrderAmount) AS monto_maximo,
    AVG(OrderAmount) AS monto_promedio,
    SUM(OrderAmount) AS monto_total
  FROM dbo.vw_CompraProveedorCategoria
  GROUP BY ROLLUP (SupplierName, SupplierCategoryName)
  HAVING
    (@supplier IS NULL OR SupplierName LIKE '%' + @supplier + '%')
    AND (@category IS NULL OR SupplierCategoryName LIKE '%' + @category + '%')
  ORDER BY SupplierName, SupplierCategoryName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_estadisticasVentas
  @customer NVARCHAR(100) = NULL,
  @category NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    CustomerName,
    StockGroupName,
    MIN(InvoiceAmountByCategory) AS monto_minimo,
    MAX(InvoiceAmountByCategory) AS monto_maximo,
    AVG(InvoiceAmountByCategory) AS monto_promedio,
    SUM(InvoiceAmountByCategory) AS monto_total
  FROM dbo.vw_VentaClienteCategoria
  GROUP BY ROLLUP (CustomerName, StockGroupName)
  HAVING
    (@customer IS NULL OR CustomerName  LIKE '%' + @customer + '%')
    AND (@category IS NULL OR StockGroupName LIKE '%' + @category + '%')
  ORDER BY CustomerName, StockGroupName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_estadisticasGananciasProductosAnio
  @year INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  WITH r AS (
    SELECT
      v.Year,
      v.StockItemID,
      v.SalesAmount,
      v.CostAmount,
      v.ProfitAmount,
      DENSE_RANK() OVER (PARTITION BY v.Year ORDER BY v.ProfitAmount DESC) AS rnk
    FROM dbo.vw_ProductosGananciaAnual v
  )
  SELECT r.Year, si.StockItemName, r.SalesAmount, r.CostAmount, r.ProfitAmount, r.rnk
  FROM r
  JOIN Warehouse.StockItems si ON si.StockItemID = r.StockItemID
  WHERE (@year IS NULL OR r.Year = @year)
    AND r.rnk <= 5
  ORDER BY r.Year, r.rnk;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_estadisticasClientesMayorGananciaAnio
  @fromyear INT = NULL, @toyear INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  WITH r AS (
    SELECT
      v.Year,
      v.CustomerID,
      v.InvoiceCount,
      v.TotalAmount,
      DENSE_RANK() OVER (PARTITION BY v.Year ORDER BY v.InvoiceCount DESC) AS rnk
    FROM dbo.vw_TopClientesAnual v
    WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
      AND (@toyear   IS NULL OR v.Year <= @toyear)
  )
  SELECT r.Year, c.CustomerName, r.InvoiceCount, r.TotalAmount, r.rnk
  FROM r
  JOIN Sales.Customers c ON c.CustomerID = r.CustomerID
  WHERE r.rnk <= 5
  ORDER BY r.Year, r.rnk;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_estadisticasProveedoresConMayoresOrdenes
  @fromyear INT = NULL, @toyear INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  WITH r AS (
    SELECT
      v.Year,
      v.SupplierID,
      v.OrderCount,
      v.TotalAmount,
      DENSE_RANK() OVER (PARTITION BY v.Year ORDER BY v.OrderCount DESC) AS rnk
    FROM dbo.vw_TopProveedoresAnual v
    WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
      AND (@toyear   IS NULL OR v.Year <= @toyear)
  )
  SELECT r.Year, s.SupplierName, r.OrderCount, r.TotalAmount, r.rnk
  FROM r
  JOIN Purchasing.Suppliers s ON s.SupplierID = r.SupplierID
  WHERE r.rnk <= 5
  ORDER BY r.Year, r.rnk;
END;
GO
