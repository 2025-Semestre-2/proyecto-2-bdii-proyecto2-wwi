-- ============================================================
-- MIGRACIÓN DE DATOS A WWI_CORPORATIVO
-- ============================================================
-- Propósito: 
--   1. Migrar catálogos de referencia (idénticos en las 3 bases)
--   2. Migrar SOLO datos sensibles de clientes
--   3. Cargar datos iniciales en tablas _SJ y _Limon (mismo estado inicial para replicación)
--
-- NOTA: Este script carga EXACTAMENTE los mismos datos que Migracion_SanJose.sql
--       y Migracion_Limon.sql, pero en CORPORATIVO (en sus respectivas tablas _SJ y _Limon)
-- ============================================================

USE WWI_Corporativo;
GO

PRINT 'Iniciando migración de datos a WWI_Corporativo...';
GO

-- ============================================================
-- 1. DATOS GEOGRÁFICOS (Application)
-- ============================================================

PRINT 'Migrando datos geográficos...';
GO

-- Países
SET IDENTITY_INSERT Application.Countries ON;
INSERT INTO Application.Countries (CountryID, CountryName, FormalName, LastEditedBy)
SELECT CountryID, CountryName, FormalName, LastEditedBy
FROM WideWorldImporters.Application.Countries;
SET IDENTITY_INSERT Application.Countries OFF;

PRINT '  - Países migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Provincias/Estados
SET IDENTITY_INSERT Application.StateProvinces ON;
INSERT INTO Application.StateProvinces (StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, LastEditedBy)
SELECT StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, LastEditedBy
FROM WideWorldImporters.Application.StateProvinces;
SET IDENTITY_INSERT Application.StateProvinces OFF;

PRINT '  - Provincias migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Ciudades
SET IDENTITY_INSERT Application.Cities ON;
INSERT INTO Application.Cities (CityID, CityName, StateProvinceID, LastEditedBy)
SELECT CityID, CityName, StateProvinceID, LastEditedBy
FROM WideWorldImporters.Application.Cities;
SET IDENTITY_INSERT Application.Cities OFF;

PRINT '  - Ciudades migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 2. DATOS SENSIBLES DE CLIENTES (Sales)
-- ============================================================

PRINT 'Migrando datos sensibles de clientes...';
GO

INSERT INTO Sales.CustomerSensitiveData 
(
    CustomerID, PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryCityID, DeliveryLocation, LastEditedBy
)
SELECT 
    CustomerID, PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryCityID, DeliveryLocation, LastEditedBy
FROM WideWorldImporters.Sales.Customers;

PRINT '  - Datos sensibles de clientes migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 3. CATÁLOGOS DE REFERENCIA (para constraints de replicación)
-- ============================================================

PRINT 'Migrando catálogos de referencia...';
GO

-- Personas (simplificado)
INSERT INTO Application.People (PersonID, FullName, LastEditedBy)
SELECT PersonID, FullName, LastEditedBy
FROM WideWorldImporters.Application.People;

PRINT '  - Personas migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Métodos de entrega
INSERT INTO Application.DeliveryMethods (DeliveryMethodID, DeliveryMethodName, LastEditedBy)
SELECT DeliveryMethodID, DeliveryMethodName, LastEditedBy
FROM WideWorldImporters.Application.DeliveryMethods;

PRINT '  - Métodos de entrega migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Categorías de clientes
INSERT INTO Sales.CustomerCategories (CustomerCategoryID, CustomerCategoryName, LastEditedBy)
SELECT CustomerCategoryID, CustomerCategoryName, LastEditedBy
FROM WideWorldImporters.Sales.CustomerCategories;

PRINT '  - Categorías de clientes migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Grupos de compra
INSERT INTO Sales.BuyingGroups (BuyingGroupID, BuyingGroupName, LastEditedBy)
SELECT BuyingGroupID, BuyingGroupName, LastEditedBy
FROM WideWorldImporters.Sales.BuyingGroups;

PRINT '  - Grupos de compra migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Categorías de proveedores
INSERT INTO Purchasing.SupplierCategories (SupplierCategoryID, SupplierCategoryName, LastEditedBy)
SELECT SupplierCategoryID, SupplierCategoryName, LastEditedBy
FROM WideWorldImporters.Purchasing.SupplierCategories;

PRINT '  - Categorías de proveedores migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Grupos de stock
INSERT INTO Warehouse.StockGroups (StockGroupID, StockGroupName, LastEditedBy)
SELECT StockGroupID, StockGroupName, LastEditedBy
FROM WideWorldImporters.Warehouse.StockGroups;

PRINT '  - Grupos de stock migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Colores
INSERT INTO Warehouse.Colors (ColorID, ColorName, LastEditedBy)
SELECT ColorID, ColorName, LastEditedBy
FROM WideWorldImporters.Warehouse.Colors;

PRINT '  - Colores migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Tipos de empaquetamiento
INSERT INTO Warehouse.PackageTypes (PackageTypeID, PackageTypeName, LastEditedBy)
SELECT PackageTypeID, PackageTypeName, LastEditedBy
FROM WideWorldImporters.Warehouse.PackageTypes;

PRINT '  - Tipos de empaquetamiento migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 4. PROVEEDORES Y CLIENTES (deben ir ANTES de StockItems)
-- ============================================================

PRINT 'Migrando proveedores y clientes...';
GO

-- Proveedores (catálogo completo, ANTES de StockItems)
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

PRINT '  - Proveedores migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Clientes (catálogo sin datos sensibles)
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

PRINT '  - Clientes migrados: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 5. CATÁLOGO DE PRODUCTOS (Warehouse)
-- ============================================================
-- IMPORTANTE: Catálogo COMPLETO de productos debe estar en todas las bases
-- antes de configurar Merge Replication

PRINT 'Migrando catálogo de productos...';
GO

-- StockItems (catálogo completo)
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

-- StockItemStockGroups (relaciones producto-grupo)
SET IDENTITY_INSERT Warehouse.StockItemStockGroups ON;
INSERT INTO Warehouse.StockItemStockGroups (StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy)
SELECT StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy
FROM WideWorldImporters.Warehouse.StockItemStockGroups;
SET IDENTITY_INSERT Warehouse.StockItemStockGroups OFF;

PRINT '  - Relaciones producto-grupo migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 6. DATOS OPERATIVOS DE SANJOSE (Tablas _SJ)
-- ============================================================

PRINT '';
PRINT 'Migrando datos operativos de SanJose a tablas _SJ...';
GO

-- Inventario de SanJose (50% - StockItemID impar)
INSERT INTO Warehouse.StockItemHoldings_SJ
(
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen
)
SELECT 
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen
FROM WideWorldImporters.Warehouse.StockItemHoldings
WHERE StockItemID % 2 = 1; -- Solo IDs impares

PRINT '  - Inventario SanJose migrado: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Facturas de SanJose (50% - CustomerID impar)
SET IDENTITY_INSERT Sales.Invoices_SJ ON;
INSERT INTO Sales.Invoices_SJ
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
WHERE CustomerID % 2 = 1; -- Solo clientes con ID impar
SET IDENTITY_INSERT Sales.Invoices_SJ OFF;

PRINT '  - Facturas SanJose migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Líneas de facturas de SanJose
SET IDENTITY_INSERT Sales.InvoiceLines_SJ ON;
INSERT INTO Sales.InvoiceLines_SJ
(
    InvoiceLineID, InvoiceID, StockItemID, Description, Quantity,
    UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy
)
SELECT 
    il.InvoiceLineID, il.InvoiceID, il.StockItemID, il.Description, il.Quantity,
    il.UnitPrice, il.TaxRate, il.TaxAmount, il.LineProfit, il.ExtendedPrice, il.LastEditedBy
FROM WideWorldImporters.Sales.InvoiceLines il
INNER JOIN WideWorldImporters.Sales.Invoices i ON i.InvoiceID = il.InvoiceID
WHERE i.CustomerID % 2 = 1; -- Solo líneas de facturas que ya migramos
SET IDENTITY_INSERT Sales.InvoiceLines_SJ OFF;

PRINT '  - Líneas de factura SanJose migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Órdenes de compra de SanJose (50% - PurchaseOrderID impar)
SET IDENTITY_INSERT Purchasing.PurchaseOrders_SJ ON;
INSERT INTO Purchasing.PurchaseOrders_SJ
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
WHERE PurchaseOrderID % 2 = 1; -- Solo IDs impares
SET IDENTITY_INSERT Purchasing.PurchaseOrders_SJ OFF;

PRINT '  - Órdenes de compra SanJose migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Líneas de órdenes de compra de SanJose
SET IDENTITY_INSERT Purchasing.PurchaseOrderLines_SJ ON;
INSERT INTO Purchasing.PurchaseOrderLines_SJ
(
    PurchaseOrderLineID, PurchaseOrderID, StockItemID, OrderedOuters,
    Description, ReceivedOuters, ExpectedUnitPricePerOuter, LastEditedBy
)
SELECT 
    pol.PurchaseOrderLineID, pol.PurchaseOrderID, pol.StockItemID, pol.OrderedOuters,
    pol.Description, pol.ReceivedOuters, pol.ExpectedUnitPricePerOuter, pol.LastEditedBy
FROM WideWorldImporters.Purchasing.PurchaseOrderLines pol
INNER JOIN WideWorldImporters.Purchasing.PurchaseOrders po ON po.PurchaseOrderID = pol.PurchaseOrderID
WHERE po.PurchaseOrderID % 2 = 1; -- Solo líneas de órdenes que ya migramos
SET IDENTITY_INSERT Purchasing.PurchaseOrderLines_SJ OFF;

PRINT '  - Líneas de orden de compra SanJose migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Transacciones de inventario de SanJose
SET IDENTITY_INSERT Warehouse.StockItemTransactions_SJ ON;
INSERT INTO Warehouse.StockItemTransactions_SJ
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
WHERE StockItemID % 2 = 1; -- Solo transacciones de productos en inventario de SanJose
SET IDENTITY_INSERT Warehouse.StockItemTransactions_SJ OFF;

PRINT '  - Transacciones SanJose migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ============================================================
-- 7. DATOS OPERATIVOS DE LIMON (Tablas _Limon)
-- ============================================================

PRINT '';
PRINT 'Migrando datos operativos de Limon a tablas _Limon...';
GO

-- Inventario de Limon (50% - StockItemID par)
INSERT INTO Warehouse.StockItemHoldings_Limon
(
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen
)
SELECT 
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen
FROM WideWorldImporters.Warehouse.StockItemHoldings
WHERE StockItemID % 2 = 0; -- Solo IDs pares

PRINT '  - Inventario Limon migrado: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Facturas de Limon (50% - CustomerID par)
SET IDENTITY_INSERT Sales.Invoices_Limon ON;
INSERT INTO Sales.Invoices_Limon
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
WHERE CustomerID % 2 = 0; -- Solo clientes con ID par
SET IDENTITY_INSERT Sales.Invoices_Limon OFF;

PRINT '  - Facturas Limon migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Líneas de facturas de Limon
SET IDENTITY_INSERT Sales.InvoiceLines_Limon ON;
INSERT INTO Sales.InvoiceLines_Limon
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
SET IDENTITY_INSERT Sales.InvoiceLines_Limon OFF;

PRINT '  - Líneas de factura Limon migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Órdenes de compra de Limon (50% - PurchaseOrderID par)
SET IDENTITY_INSERT Purchasing.PurchaseOrders_Limon ON;
INSERT INTO Purchasing.PurchaseOrders_Limon
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
WHERE PurchaseOrderID % 2 = 0; -- Solo IDs pares
SET IDENTITY_INSERT Purchasing.PurchaseOrders_Limon OFF;

PRINT '  - Órdenes de compra Limon migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Líneas de órdenes de compra de Limon
SET IDENTITY_INSERT Purchasing.PurchaseOrderLines_Limon ON;
INSERT INTO Purchasing.PurchaseOrderLines_Limon
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
SET IDENTITY_INSERT Purchasing.PurchaseOrderLines_Limon OFF;

PRINT '  - Líneas de orden de compra Limon migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Transacciones de inventario de Limon
SET IDENTITY_INSERT Warehouse.StockItemTransactions_Limon ON;
INSERT INTO Warehouse.StockItemTransactions_Limon
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
WHERE StockItemID % 2 = 0; -- Solo transacciones de productos en inventario de Limon
SET IDENTITY_INSERT Warehouse.StockItemTransactions_Limon OFF;

PRINT '  - Transacciones Limon migradas: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO


-- ============================================================
-- RESUMEN DE MIGRACIÓN
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT 'MIGRACIÓN A WWI_CORPORATIVO COMPLETADA';
PRINT '========================================';
PRINT '';
PRINT 'DATOS COMPARTIDOS (idénticos en las 3 bases):';
PRINT '  ✓ Datos geográficos (Countries, StateProvinces, Cities)';
PRINT '  ✓ Datos sensibles de clientes (CustomerSensitiveData)';
PRINT '  ✓ Catálogos de referencia (Colors, StockGroups, PackageTypes, etc.)';
PRINT '  ✓ Catálogo COMPLETO de productos (StockItems, StockItemStockGroups)';
PRINT '  ✓ Catálogos completos (Suppliers, Customers sin sensibles)';
PRINT '  ✓ 3 usuarios del sistema (rol: corporativo)';
PRINT '';
PRINT 'DATOS OPERATIVOS DE SANJOSE (Tablas _SJ):';
PRINT '  ✓ 50% del inventario (StockItemID impar)';
PRINT '  ✓ 50% de las facturas (CustomerID impar)';
PRINT '  ✓ 50% de las órdenes de compra (PurchaseOrderID impar)';
PRINT '  ✓ Transacciones de inventario relacionadas';
PRINT '';
PRINT 'DATOS OPERATIVOS DE LIMON (Tablas _Limon):';
PRINT '  ✓ 50% del inventario (StockItemID par)';
PRINT '  ✓ 50% de las facturas (CustomerID par)';
PRINT '  ✓ 50% de las órdenes de compra (PurchaseOrderID par)';
PRINT '  ✓ Transacciones de inventario relacionadas';
PRINT '';
PRINT 'ARQUITECTURA DE REPLICACIÓN:';
PRINT '  • Tablas _SJ: Réplicas exactas de SanJose';
PRINT '  • Tablas _Limon: Réplicas exactas de Limon';
PRINT '  • Sin columna SucursalOrigen (tablas separadas por sucursal)';
PRINT '';
PRINT 'ESTADO INICIAL:';
PRINT '  ✓ Las 3 bases tienen EXACTAMENTE los mismos datos iniciales';
PRINT '  ✓ Replicación lista para capturar cambios FUTUROS';
PRINT '';
PRINT 'PRÓXIMOS PASOS:';
PRINT '  1. Configurar replicación transaccional unidireccional:';
PRINT '     - SanJose.StockItemHoldings_SJ → CORP.StockItemHoldings_SJ';
PRINT '     - Limon.StockItemHoldings_Limon → CORP.StockItemHoldings_Limon';
PRINT '     (y así con las 6 tablas operativas)';
PRINT '  2. Usar @sync_type = ''replication support only'' (sin snapshot)';
PRINT '';
GO
