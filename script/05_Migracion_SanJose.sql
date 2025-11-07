-- ============================================================
-- SCRIPT 5: MIGRACIÓN DE DATOS A BD_SANJOSE
-- ============================================================
-- Copia catálogos y datos operacionales para Sucursal San José
-- Divide inventario y ventas entre las dos sucursales
-- ============================================================

USE BD_SanJose;
GO

PRINT 'Iniciando migración de datos a BD_SanJose...';
GO

-- ============================================================
-- 1. CATÁLOGOS DE REFERENCIA
-- ============================================================

INSERT INTO CustomerCategories (CustomerCategoryID, CustomerCategoryName)
SELECT CustomerCategoryID, CustomerCategoryName
FROM WideWorldImporters.Sales.CustomerCategories;
PRINT 'CustomerCategories: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO BuyingGroups (BuyingGroupID, BuyingGroupName)
SELECT BuyingGroupID, BuyingGroupName
FROM WideWorldImporters.Sales.BuyingGroups;
PRINT 'BuyingGroups: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO DeliveryMethods (DeliveryMethodID, DeliveryMethodName)
SELECT DeliveryMethodID, DeliveryMethodName
FROM WideWorldImporters.Application.DeliveryMethods;
PRINT 'DeliveryMethods: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO Countries (CountryID, CountryName)
SELECT CountryID, CountryName
FROM WideWorldImporters.Application.Countries;
PRINT 'Countries: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO StateProvinces (StateProvinceID, StateProvinceName, CountryID)
SELECT StateProvinceID, StateProvinceName, CountryID
FROM WideWorldImporters.Application.StateProvinces;
PRINT 'StateProvinces: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO Cities (CityID, CityName, StateProvinceID)
SELECT CityID, CityName, StateProvinceID
FROM WideWorldImporters.Application.Cities;
PRINT 'Cities: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO People (PersonID, FullName)
SELECT PersonID, FullName
FROM WideWorldImporters.Application.People;
PRINT 'People: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 2. CLIENTES (Sin datos sensibles)
-- ============================================================

INSERT INTO Customers (
    CustomerID, CustomerName, CustomerCategoryID, BuyingGroupID,
    BillToCustomerID, DeliveryMethodID, DeliveryCityID, PaymentDays
)
SELECT 
    CustomerID, CustomerName, CustomerCategoryID, BuyingGroupID,
    BillToCustomerID, DeliveryMethodID, DeliveryCityID, PaymentDays
FROM WideWorldImporters.Sales.Customers;
PRINT 'Customers: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 3. PROVEEDORES
-- ============================================================

INSERT INTO SupplierCategories (SupplierCategoryID, SupplierCategoryName)
SELECT SupplierCategoryID, SupplierCategoryName
FROM WideWorldImporters.Purchasing.SupplierCategories;
PRINT 'SupplierCategories: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO Suppliers (SupplierID, SupplierName, SupplierCategoryID, PhoneNumber)
SELECT SupplierID, SupplierName, SupplierCategoryID, PhoneNumber
FROM WideWorldImporters.Purchasing.Suppliers;
PRINT 'Suppliers: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 4. PRODUCTOS (Catálogo)
-- ============================================================

INSERT INTO Colors (ColorID, ColorName)
SELECT ColorID, ColorName
FROM WideWorldImporters.Warehouse.Colors;
PRINT 'Colors: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO PackageTypes (PackageTypeID, PackageTypeName)
SELECT PackageTypeID, PackageTypeName
FROM WideWorldImporters.Warehouse.PackageTypes;
PRINT 'PackageTypes: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO StockGroups (StockGroupID, StockGroupName)
SELECT StockGroupID, StockGroupName
FROM WideWorldImporters.Warehouse.StockGroups;
PRINT 'StockGroups: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

INSERT INTO StockItems (
    StockItemID, StockItemName, SupplierID, ColorID,
    UnitPackageID, OuterPackageID, Brand, Size,
    LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode,
    TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit
)
SELECT 
    StockItemID, StockItemName, SupplierID, ColorID,
    UnitPackageID, OuterPackageID, Brand, Size,
    LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode,
    TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit
FROM WideWorldImporters.Warehouse.StockItems;
PRINT 'StockItems: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

SET IDENTITY_INSERT StockItemStockGroups ON;
INSERT INTO StockItemStockGroups (StockItemStockGroupID, StockItemID, StockGroupID)
SELECT StockItemStockGroupID, StockItemID, StockGroupID
FROM WideWorldImporters.Warehouse.StockItemStockGroups;
SET IDENTITY_INSERT StockItemStockGroups OFF;
PRINT 'StockItemStockGroups: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 5. INVENTARIO - SUCURSAL SAN JOSÉ (60% del inventario)
-- ============================================================

-- Dividir inventario: 60% San José, 40% Limón
INSERT INTO StockItemHoldings (
    StockItemID, QuantityOnHand, BinLocation,
    LastStocktakeQuantity, LastCostPrice,
    ReorderLevel, TargetStockLevel
)
SELECT 
    StockItemID,
    CAST(QuantityOnHand * 0.6 AS INT) AS QuantityOnHand,
    BinLocation,
    CAST(LastStocktakeQuantity * 0.6 AS INT) AS LastStocktakeQuantity,
    LastCostPrice,
    CAST(ReorderLevel * 0.6 AS INT) AS ReorderLevel,
    CAST(TargetStockLevel * 0.6 AS INT) AS TargetStockLevel
FROM WideWorldImporters.Warehouse.StockItemHoldings;
PRINT 'StockItemHoldings: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros (60% inventario)';
GO

-- Tipos de Transacciones
INSERT INTO TransactionTypes (TransactionTypeID, TransactionTypeName)
SELECT TransactionTypeID, TransactionTypeName
FROM WideWorldImporters.Application.TransactionTypes;
PRINT 'TransactionTypes: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- Transacciones de Stock (60% de las transacciones)
SET IDENTITY_INSERT StockItemTransactions ON;

INSERT INTO StockItemTransactions (
    StockItemTransactionID, StockItemID, TransactionTypeID,
    CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
    TransactionOccurredWhen, Quantity
)
SELECT TOP 60 PERCENT
    StockItemTransactionID, StockItemID, TransactionTypeID,
    CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
    TransactionOccurredWhen, Quantity
FROM WideWorldImporters.Warehouse.StockItemTransactions
ORDER BY StockItemTransactionID;

SET IDENTITY_INSERT StockItemTransactions OFF;
PRINT 'StockItemTransactions: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros (60% transacciones)';
GO

-- ============================================================
-- 6. VENTAS - SUCURSAL SAN JOSÉ (60% de las ventas)
-- ============================================================

-- Facturas (60% de las ventas)
INSERT INTO Invoices (
    InvoiceID, CustomerID, BillToCustomerID, InvoiceDate,
    DeliveryMethodID, ContactPersonID, SalespersonPersonID,
    CustomerPurchaseOrderNumber, DeliveryInstructions
)
SELECT TOP 60 PERCENT
    InvoiceID, CustomerID, BillToCustomerID, InvoiceDate,
    DeliveryMethodID, ContactPersonID, SalespersonPersonID,
    CustomerPurchaseOrderNumber, DeliveryInstructions
FROM WideWorldImporters.Sales.Invoices
ORDER BY InvoiceID;
PRINT 'Invoices: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros (60% ventas)';
GO

-- Líneas de Factura
SET IDENTITY_INSERT InvoiceLines ON;

INSERT INTO InvoiceLines (
    InvoiceLineID, InvoiceID, StockItemID,
    Quantity, UnitPrice, TaxRate, TaxAmount, ExtendedPrice
)
SELECT 
    il.InvoiceLineID, il.InvoiceID, il.StockItemID,
    il.Quantity, il.UnitPrice, il.TaxRate, il.TaxAmount, il.ExtendedPrice
FROM WideWorldImporters.Sales.InvoiceLines il
INNER JOIN Invoices i ON i.InvoiceID = il.InvoiceID;

SET IDENTITY_INSERT InvoiceLines OFF;
PRINT 'InvoiceLines: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

PRINT '=================================================';
PRINT 'MIGRACIÓN A BD_SANJOSE COMPLETADA EXITOSAMENTE';
PRINT '=================================================';
