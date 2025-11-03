USE WideWorldImporters;
GO
SET NOCOUNT ON;

-- IDs y valores de apoyo
DECLARE 
  @AnyCustomerID  INT  = (SELECT TOP 1 CustomerID  FROM Sales.Customers ORDER BY CustomerID),
  @AnySupplierID  INT  = (SELECT TOP 1 SupplierID  FROM Purchasing.Suppliers ORDER BY SupplierID),
  @AnyItemID      INT  = (SELECT TOP 1 StockItemID FROM Warehouse.StockItems ORDER BY StockItemID),
  @AnyInvoiceID   INT  = (SELECT TOP 1 InvoiceID   FROM Sales.Invoices ORDER BY InvoiceID DESC),
  @AnyUnitPackID  INT  = (SELECT TOP 1 PackageTypeID FROM Warehouse.PackageTypes ORDER BY PackageTypeID),
  @AnyOuterPackID INT  = (SELECT TOP 1 PackageTypeID FROM Warehouse.PackageTypes ORDER BY PackageTypeID DESC),
  @FromDate       DATE = '2013-01-01',
  @ToDate         DATE = '2016-12-31',
  @YearSample     INT  = 2015;

------------------------------------------------------------
-- CLIENTES
------------------------------------------------------------
EXEC dbo.sp_obtenerClientes @search = NULL;
EXEC dbo.sp_obtenerClientes @search = N'Tail';

EXEC dbo.sp_obtenerDetalleCliente @customerid = @AnyCustomerID;

------------------------------------------------------------
-- PROVEEDORES
------------------------------------------------------------
EXEC dbo.sp_obtenerProveedores @search = NULL, @category = NULL;
EXEC dbo.sp_obtenerProveedores @search = N'Clothing', @category = NULL;

EXEC dbo.sp_obtenerDetalleProveedor @supplierid = @AnySupplierID;

------------------------------------------------------------
-- INVENTARIO: LISTADO Y DETALLE
------------------------------------------------------------
EXEC dbo.sp_obtenerInventario @search = NULL,        @group = NULL;
EXEC dbo.sp_obtenerInventario @search = N'Chocolate', @group = NULL;

EXEC dbo.sp_obtenerDetalleInventario @stockitemid = @AnyItemID;

------------------------------------------------------------
-- INVENTARIO: CRUD (insertar, actualizar, eliminar)
-- Captura de ID nuevo usando tabla temporal
------------------------------------------------------------
DECLARE @tmpNew TABLE (NewStockItemID INT);
INSERT INTO @tmpNew
EXEC dbo.sp_inventario_insertar
  @StockItemName           = N'ITEM PRUEBA API',
  @SupplierID              = @AnySupplierID,
  @UnitPackageID           = @AnyUnitPackID,
  @OuterPackageID          = @AnyOuterPackID,
  @QuantityPerOuter        = 10,
  @UnitPrice               = 9.99,
  @RecommendedRetailPrice  = 12.99,
  @TaxRate                 = 0.000,
  @TypicalWeightPerUnit    = 0.100;

DECLARE @NewStockItemID INT = (SELECT TOP 1 NewStockItemID FROM @tmpNew);

EXEC dbo.sp_inventario_actualizar
  @StockItemID             = @NewStockItemID,
  @StockItemName           = N'ITEM PRUEBA API (EDITADO)',
  @SupplierID              = @AnySupplierID,
  @UnitPackageID           = @AnyUnitPackID,
  @OuterPackageID          = @AnyOuterPackID,
  @QuantityPerOuter        = 20,
  @UnitPrice               = 11.50,
  @RecommendedRetailPrice  = 15.00,
  @TaxRate                 = 0.000,
  @TypicalWeightPerUnit    = 0.120;

EXEC dbo.sp_inventario_eliminar @StockItemID = @NewStockItemID;

------------------------------------------------------------
-- VENTAS
------------------------------------------------------------
EXEC dbo.sp_obtenerVentas 
  @client = NULL, 
  @from   = @FromDate, 
  @to     = @ToDate, 
  @minamt = NULL, 
  @maxamt = NULL;

EXEC dbo.sp_obtenerVentas 
  @client = N'Tail', 
  @from   = NULL, 
  @to     = NULL, 
  @minamt = NULL, 
  @maxamt = NULL;

EXEC dbo.sp_obtenerDetalleVentas @invoiceid = @AnyInvoiceID;

------------------------------------------------------------
-- ESTADÍSTICAS
------------------------------------------------------------
EXEC dbo.sp_estadisticasCompras @supplier = NULL,  @category = NULL;
EXEC dbo.sp_estadisticasCompras @supplier = N'Clothes', @category = NULL;

EXEC dbo.sp_estadisticasVentas  @customer = NULL,  @category = NULL;
EXEC dbo.sp_estadisticasVentas  @customer = NULL,  @category = N'Novelty';

EXEC dbo.sp_estadisticasGananciasProductosAnio @year = @YearSample;

EXEC dbo.sp_estadisticasClientesMayorGananciaAnio 
  @fromyear = 2013, 
  @toyear   = 2016;

EXEC dbo.sp_estadisticasProveedoresConMayoresOrdenes 
  @fromyear = 2013, 
  @toyear   = 2016;
