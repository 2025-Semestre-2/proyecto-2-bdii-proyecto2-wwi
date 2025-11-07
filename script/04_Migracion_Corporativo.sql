-- ============================================================
-- SCRIPT 4: MIGRACIÓN DE DATOS A BD_CORPORATIVO
-- ============================================================
-- Copia datos desde WideWorldImporters a BD_Corporativo
-- Incluye: Catálogos maestros y datos sensibles de clientes
-- ============================================================

USE BD_Corporativo;
GO

PRINT 'Iniciando migración de datos a BD_Corporativo...';
GO

-- ============================================================
-- 1. TABLAS DE REFERENCIA
-- ============================================================

-- Categorías de Clientes
INSERT INTO CustomerCategories (CustomerCategoryID, CustomerCategoryName)
SELECT CustomerCategoryID, CustomerCategoryName
FROM WideWorldImporters.Sales.CustomerCategories;

PRINT 'CustomerCategories: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Grupos de Compra
INSERT INTO BuyingGroups (BuyingGroupID, BuyingGroupName)
SELECT BuyingGroupID, BuyingGroupName
FROM WideWorldImporters.Sales.BuyingGroups;

PRINT 'BuyingGroups: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Métodos de Entrega
INSERT INTO DeliveryMethods (DeliveryMethodID, DeliveryMethodName)
SELECT DeliveryMethodID, DeliveryMethodName
FROM WideWorldImporters.Application.DeliveryMethods;

PRINT 'DeliveryMethods: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Países
INSERT INTO Countries (CountryID, CountryName)
SELECT CountryID, CountryName
FROM WideWorldImporters.Application.Countries;

PRINT 'Countries: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Provincias
INSERT INTO StateProvinces (StateProvinceID, StateProvinceName, CountryID)
SELECT StateProvinceID, StateProvinceName, CountryID
FROM WideWorldImporters.Application.StateProvinces;

PRINT 'StateProvinces: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Ciudades
INSERT INTO Cities (CityID, CityName, StateProvinceID)
SELECT CityID, CityName, StateProvinceID
FROM WideWorldImporters.Application.Cities;

PRINT 'Cities: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Personas
INSERT INTO People (PersonID, FullName, PhoneNumber, FaxNumber, EmailAddress)
SELECT PersonID, FullName, PhoneNumber, FaxNumber, EmailAddress
FROM WideWorldImporters.Application.People;

PRINT 'People: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- ============================================================
-- 2. CLIENTES - Información Básica
-- ============================================================

INSERT INTO Customers (
    CustomerID, CustomerName, CustomerCategoryID, BuyingGroupID,
    BillToCustomerID, DeliveryMethodID, DeliveryCityID, PaymentDays
)
SELECT 
    CustomerID, CustomerName, CustomerCategoryID, BuyingGroupID,
    BillToCustomerID, DeliveryMethodID, DeliveryCityID, PaymentDays
FROM WideWorldImporters.Sales.Customers;

PRINT 'Customers: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- ============================================================
-- 3. CLIENTES - Información Sensible
-- ============================================================

INSERT INTO CustomersSensitiveData (
    CustomerID, PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryLatitude, DeliveryLongitude,
    PrimaryContactPersonID, AlternateContactPersonID
)
SELECT 
    CustomerID, PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryLocation.Lat, DeliveryLocation.Long,
    PrimaryContactPersonID, AlternateContactPersonID
FROM WideWorldImporters.Sales.Customers;

PRINT 'CustomersSensitiveData: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- ============================================================
-- 4. PROVEEDORES
-- ============================================================

-- Categorías de Proveedores
INSERT INTO SupplierCategories (SupplierCategoryID, SupplierCategoryName)
SELECT SupplierCategoryID, SupplierCategoryName
FROM WideWorldImporters.Purchasing.SupplierCategories;

PRINT 'SupplierCategories: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Proveedores
INSERT INTO Suppliers (
    SupplierID, SupplierName, SupplierCategoryID, SupplierReference,
    DeliveryMethodID, DeliveryCityID, PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryLatitude, DeliveryLongitude, PaymentDays,
    PrimaryContactPersonID, AlternateContactPersonID,
    BankAccountName, BankAccountBranch, BankAccountCode,
    BankAccountNumber, BankInternationalCode
)
SELECT 
    SupplierID, SupplierName, SupplierCategoryID, SupplierReference,
    DeliveryMethodID, DeliveryCityID, PhoneNumber, FaxNumber, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryLocation.Lat, DeliveryLocation.Long, ISNULL(PaymentDays, 0),
    PrimaryContactPersonID, AlternateContactPersonID,
    BankAccountName, BankAccountBranch, BankAccountCode,
    BankAccountNumber, BankInternationalCode
FROM WideWorldImporters.Purchasing.Suppliers;

PRINT 'Suppliers: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- ============================================================
-- 5. PRODUCTOS (Catálogo Maestro)
-- ============================================================

-- Colores
INSERT INTO Colors (ColorID, ColorName)
SELECT ColorID, ColorName
FROM WideWorldImporters.Warehouse.Colors;

PRINT 'Colors: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Tipos de Empaquetamiento
INSERT INTO PackageTypes (PackageTypeID, PackageTypeName)
SELECT PackageTypeID, PackageTypeName
FROM WideWorldImporters.Warehouse.PackageTypes;

PRINT 'PackageTypes: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Grupos de Productos
INSERT INTO StockGroups (StockGroupID, StockGroupName)
SELECT StockGroupID, StockGroupName
FROM WideWorldImporters.Warehouse.StockGroups;

PRINT 'StockGroups: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Productos
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

PRINT 'StockItems: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

-- Relación Productos - Grupos
SET IDENTITY_INSERT StockItemStockGroups ON;

INSERT INTO StockItemStockGroups (StockItemStockGroupID, StockItemID, StockGroupID)
SELECT StockItemStockGroupID, StockItemID, StockGroupID
FROM WideWorldImporters.Warehouse.StockItemStockGroups;

SET IDENTITY_INSERT StockItemStockGroups OFF;

PRINT 'StockItemStockGroups: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados';
GO

PRINT '=================================================';
PRINT 'MIGRACIÓN A BD_CORPORATIVO COMPLETADA EXITOSAMENTE';
PRINT '=================================================';
