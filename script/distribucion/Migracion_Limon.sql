-- ============================================================
-- MIGRACIÓN DE DATOS A WWI_LIMON
-- ============================================================
-- Propósito: 
--   1. Migrar catálogo completo (Clientes sin sensibles, Proveedores, Productos)
--   2. Migrar 50% del inventario (complementario a SanJose)
--   3. Migrar 50% de las facturas (CustomerID par)
--   4. Migrar 50% de las órdenes de compra (PurchaseOrderID par)
-- ============================================================

USE WWI_Limon;
GO

PRINT 'Iniciando migración de datos a WWI_Limon...';
GO

-- ============================================================
-- 1. DATOS GEOGRÁFICOS (Application)
-- ============================================================

PRINT 'Migrando datos geográficos...';
GO

SET IDENTITY_INSERT Application.Countries ON;
INSERT INTO Application.Countries (CountryID, CountryName, FormalName, LastEditedBy)
SELECT CountryID, CountryName, FormalName, LastEditedBy
FROM WideWorldImporters.Application.Countries;
SET IDENTITY_INSERT Application.Countries OFF;

SET IDENTITY_INSERT Application.StateProvinces ON;
INSERT INTO Application.StateProvinces (StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, LastEditedBy)
SELECT StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, LastEditedBy
FROM WideWorldImporters.Application.StateProvinces;
SET IDENTITY_INSERT Application.StateProvinces OFF;

SET IDENTITY_INSERT Application.Cities ON;
INSERT INTO Application.Cities (CityID, CityName, StateProvinceID, LastEditedBy)
SELECT CityID, CityName, StateProvinceID, LastEditedBy
FROM WideWorldImporters.Application.Cities;
SET IDENTITY_INSERT Application.Cities OFF;

PRINT '  - Datos geográficos migrados';
GO

-- ============================================================
-- 2. DATOS DE REFERENCIA (Application)
-- ============================================================

PRINT 'Migrando datos de referencia...';
GO

SET IDENTITY_INSERT Application.People ON;
INSERT INTO Application.People (PersonID, FullName, LastEditedBy)
SELECT PersonID, FullName, LastEditedBy
FROM WideWorldImporters.Application.People;
SET IDENTITY_INSERT Application.People OFF;

SET IDENTITY_INSERT Application.DeliveryMethods ON;
INSERT INTO Application.DeliveryMethods (DeliveryMethodID, DeliveryMethodName, LastEditedBy)
SELECT DeliveryMethodID, DeliveryMethodName, LastEditedBy
FROM WideWorldImporters.Application.DeliveryMethods;
SET IDENTITY_INSERT Application.DeliveryMethods OFF;

PRINT '  - Datos de referencia migrados';
GO

-- ============================================================
-- 3. CATÁLOGO DE CLIENTES (Sales) - SIN DATOS SENSIBLES
-- ============================================================

PRINT 'Migrando catálogo de clientes (sin datos sensibles)...';
GO

SET IDENTITY_INSERT Sales.CustomerCategories ON;
INSERT INTO Sales.CustomerCategories (CustomerCategoryID, CustomerCategoryName, LastEditedBy)
SELECT CustomerCategoryID, CustomerCategoryName, LastEditedBy
FROM WideWorldImporters.Sales.CustomerCategories;
SET IDENTITY_INSERT Sales.CustomerCategories OFF;

SET IDENTITY_INSERT Sales.BuyingGroups ON;
INSERT INTO Sales.BuyingGroups (BuyingGroupID, BuyingGroupName, LastEditedBy)
SELECT BuyingGroupID, BuyingGroupName, LastEditedBy
FROM WideWorldImporters.Sales.BuyingGroups;
SET IDENTITY_INSERT Sales.BuyingGroups OFF;

SET IDENTITY_INSERT Sales.Customers ON;
INSERT INTO Sales.Customers 
(
    CustomerID, CustomerName, CustomerCategoryID, BuyingGroupID,
    BillToCustomerID, PrimaryContactPersonID, AlternateContactPersonID,
    DeliveryCityID, DeliveryMethodID, PaymentDays, LastEditedBy
)
SELECT 
    CustomerID, CustomerName, CustomerCategoryID, BuyingGroupID,
    BillToCustomerID, PrimaryContactPersonID, AlternateContactPersonID,
    DeliveryCityID, DeliveryMethodID, PaymentDays, LastEditedBy
FROM WideWorldImporters.Sales.Customers;
SET IDENTITY_INSERT Sales.Customers OFF;

PRINT '  - Clientes migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 4. CATÁLOGO DE PROVEEDORES (Purchasing) - CON TODOS LOS DATOS
-- ============================================================

PRINT 'Migrando catálogo de proveedores...';
GO

SET IDENTITY_INSERT Purchasing.SupplierCategories ON;
INSERT INTO Purchasing.SupplierCategories (SupplierCategoryID, SupplierCategoryName, LastEditedBy)
SELECT SupplierCategoryID, SupplierCategoryName, LastEditedBy
FROM WideWorldImporters.Purchasing.SupplierCategories;
SET IDENTITY_INSERT Purchasing.SupplierCategories OFF;

SET IDENTITY_INSERT Purchasing.Suppliers ON;
INSERT INTO Purchasing.Suppliers
(
    SupplierID, SupplierName, SupplierCategoryID, SupplierReference,
    PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
    DeliveryCityID, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryLocation, BankAccountName, BankAccountBranch, BankAccountCode,
    BankAccountNumber, BankInternationalCode, LastEditedBy
)
SELECT 
    SupplierID, SupplierName, SupplierCategoryID, SupplierReference,
    PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
    DeliveryCityID, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryLocation, BankAccountName, BankAccountBranch, BankAccountCode,
    BankAccountNumber, BankInternationalCode, LastEditedBy
FROM WideWorldImporters.Purchasing.Suppliers;
SET IDENTITY_INSERT Purchasing.Suppliers OFF;

PRINT '  - Proveedores migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 5. CATÁLOGO DE PRODUCTOS (Warehouse)
-- ============================================================

PRINT 'Migrando catálogo de productos...';
GO

SET IDENTITY_INSERT Warehouse.Colors ON;
INSERT INTO Warehouse.Colors (ColorID, ColorName, LastEditedBy)
SELECT ColorID, ColorName, LastEditedBy
FROM WideWorldImporters.Warehouse.Colors;
SET IDENTITY_INSERT Warehouse.Colors OFF;

SET IDENTITY_INSERT Warehouse.PackageTypes ON;
INSERT INTO Warehouse.PackageTypes (PackageTypeID, PackageTypeName, LastEditedBy)
SELECT PackageTypeID, PackageTypeName, LastEditedBy
FROM WideWorldImporters.Warehouse.PackageTypes;
SET IDENTITY_INSERT Warehouse.PackageTypes OFF;

SET IDENTITY_INSERT Warehouse.StockGroups ON;
INSERT INTO Warehouse.StockGroups (StockGroupID, StockGroupName, LastEditedBy)
SELECT StockGroupID, StockGroupName, LastEditedBy
FROM WideWorldImporters.Warehouse.StockGroups;
SET IDENTITY_INSERT Warehouse.StockGroups OFF;

SET IDENTITY_INSERT Warehouse.StockItems ON;
INSERT INTO Warehouse.StockItems
(
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, InternalComments, Photo,
    CustomFields, SearchDetails, LastEditedBy
)
SELECT 
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, InternalComments, Photo,
    CustomFields, SearchDetails, LastEditedBy
FROM WideWorldImporters.Warehouse.StockItems;
SET IDENTITY_INSERT Warehouse.StockItems OFF;

PRINT '  - Productos migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

SET IDENTITY_INSERT Warehouse.StockItemStockGroups ON;
INSERT INTO Warehouse.StockItemStockGroups (StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy)
SELECT StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy
FROM WideWorldImporters.Warehouse.StockItemStockGroups;
SET IDENTITY_INSERT Warehouse.StockItemStockGroups OFF;

PRINT '  - Relaciones producto-grupo migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 6. INVENTARIO PROPIO (50% - StockItemID par)
-- ============================================================

PRINT 'Migrando inventario propio de Limon (50% - IDs pares)...';
GO

INSERT INTO Warehouse.StockItemHoldings
(
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen
)
SELECT 
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen
FROM WideWorldImporters.Warehouse.StockItemHoldings
WHERE StockItemID % 2 = 0; -- Solo IDs pares (complementario a SanJose)

PRINT '  - Inventario migrado: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 7. FACTURAS PROPIAS (50% - CustomerID par)
-- ============================================================

PRINT 'Migrando facturas propias de Limon (50% - CustomerID par)...';
GO

SET IDENTITY_INSERT Sales.Invoices ON;
INSERT INTO Sales.Invoices
(
    InvoiceID, CustomerID, InvoiceDate, DeliveryMethodID,
    CustomerPurchaseOrderNumber, ContactPersonID, SalespersonPersonID,
    DeliveryInstructions, LastEditedBy
)
SELECT 
    InvoiceID, CustomerID, InvoiceDate, DeliveryMethodID,
    CustomerPurchaseOrderNumber, ContactPersonID, SalespersonPersonID,
    DeliveryInstructions, LastEditedBy
FROM WideWorldImporters.Sales.Invoices
WHERE CustomerID % 2 = 0; -- Solo clientes con ID par (complementario a SanJose)
SET IDENTITY_INSERT Sales.Invoices OFF;

DECLARE @InvoiceCount INT = @@ROWCOUNT;
PRINT '  - Facturas migradas: ' + CAST(@InvoiceCount AS NVARCHAR(10));
GO

SET IDENTITY_INSERT Sales.InvoiceLines ON;
INSERT INTO Sales.InvoiceLines
(
    InvoiceLineID, InvoiceID, StockItemID, Description, Quantity,
    UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy
)
SELECT 
    il.InvoiceLineID, il.InvoiceID, il.StockItemID, il.Description, il.Quantity,
    il.UnitPrice, il.TaxRate, il.TaxAmount, il.LineProfit, il.ExtendedPrice, il.LastEditedBy
FROM WideWorldImporters.Sales.InvoiceLines il
INNER JOIN WideWorldImporters.Sales.Invoices i ON i.InvoiceID = il.InvoiceID
WHERE i.CustomerID % 2 = 0; -- Solo líneas de facturas que ya migramos
SET IDENTITY_INSERT Sales.InvoiceLines OFF;

PRINT '  - Líneas de factura migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 8. ÓRDENES DE COMPRA PROPIAS (50% - PurchaseOrderID par)
-- ============================================================

PRINT 'Migrando órdenes de compra propias de Limon (50% - PurchaseOrderID par)...';
GO

SET IDENTITY_INSERT Purchasing.PurchaseOrders ON;
INSERT INTO Purchasing.PurchaseOrders
(
    PurchaseOrderID, SupplierID, OrderDate, ExpectedDeliveryDate,
    DeliveryMethodID, ContactPersonID, SupplierReference,
    IsOrderFinalized, LastEditedBy
)
SELECT 
    PurchaseOrderID, SupplierID, OrderDate, ExpectedDeliveryDate,
    DeliveryMethodID, ContactPersonID, SupplierReference,
    IsOrderFinalized, LastEditedBy
FROM WideWorldImporters.Purchasing.PurchaseOrders
WHERE PurchaseOrderID % 2 = 0; -- Solo IDs pares (complementario a SanJose)
SET IDENTITY_INSERT Purchasing.PurchaseOrders OFF;

PRINT '  - Órdenes de compra migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

SET IDENTITY_INSERT Purchasing.PurchaseOrderLines ON;
INSERT INTO Purchasing.PurchaseOrderLines
(
    PurchaseOrderLineID, PurchaseOrderID, StockItemID, OrderedOuters,
    Description, ReceivedOuters, ExpectedUnitPricePerOuter, LastEditedBy
)
SELECT 
    pol.PurchaseOrderLineID, pol.PurchaseOrderID, pol.StockItemID, pol.OrderedOuters,
    pol.Description, pol.ReceivedOuters, pol.ExpectedUnitPricePerOuter, pol.LastEditedBy
FROM WideWorldImporters.Purchasing.PurchaseOrderLines pol
INNER JOIN WideWorldImporters.Purchasing.PurchaseOrders po ON po.PurchaseOrderID = pol.PurchaseOrderID
WHERE po.PurchaseOrderID % 2 = 0; -- Solo líneas de órdenes que ya migramos
SET IDENTITY_INSERT Purchasing.PurchaseOrderLines OFF;

PRINT '  - Líneas de orden de compra migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 9. TRANSACCIONES DE INVENTARIO
-- ============================================================

PRINT 'Migrando transacciones de inventario...';
GO

SET IDENTITY_INSERT Warehouse.StockItemTransactions ON;
INSERT INTO Warehouse.StockItemTransactions
(
    StockItemTransactionID, StockItemID, TransactionTypeID, CustomerID,
    InvoiceID, SupplierID, PurchaseOrderID, TransactionOccurredWhen,
    Quantity, LastEditedBy, LastEditedWhen
)
SELECT 
    StockItemTransactionID, StockItemID, TransactionTypeID, CustomerID,
    InvoiceID, SupplierID, PurchaseOrderID, TransactionOccurredWhen,
    Quantity, LastEditedBy, LastEditedWhen
FROM WideWorldImporters.Warehouse.StockItemTransactions
WHERE StockItemID % 2 = 0; -- Solo transacciones de productos en nuestro inventario (IDs pares)
SET IDENTITY_INSERT Warehouse.StockItemTransactions OFF;

PRINT '  - Transacciones migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- RESUMEN DE MIGRACIÓN
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT 'MIGRACIÓN A WWI_LIMON COMPLETADA';
PRINT '========================================';
PRINT '';
PRINT 'Datos migrados:';
PRINT '  ✓ Catálogo completo de clientes (sin datos sensibles)';
PRINT '  ✓ Catálogo completo de proveedores';
PRINT '  ✓ Catálogo completo de productos';
PRINT '  ✓ 50% del inventario (StockItemID par)';
PRINT '  ✓ 50% de las facturas (CustomerID par)';
PRINT '  ✓ 50% de las órdenes de compra (PurchaseOrderID par)';
PRINT '';
PRINT 'PRÓXIMOS PASOS:';
PRINT '  1. Configurar REPLICACIÓN TRANSACCIONAL a Corporativo';
PRINT '  2. Instalar procedures operativos (Clientes, Inventario, Ventas, etc.)';
PRINT '';
GO
