-- ============================================================
-- MIGRACIÓN DE DATOS A WWI_CORPORATIVO
-- ============================================================
-- Propósito: 
--   1. Migrar SOLO datos sensibles de clientes
--   2. Migrar catálogos de referencia (para constraints)
--   3. NO migrar datos operativos (llegarán por replicación)
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
-- RESUMEN DE MIGRACIÓN
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT 'MIGRACIÓN A WWI_CORPORATIVO COMPLETADA';
PRINT '========================================';
PRINT '';
PRINT 'Datos migrados:';
PRINT '  ✓ Datos geográficos (Countries, StateProvinces, Cities)';
PRINT '  ✓ Datos sensibles de clientes (CustomerSensitiveData)';
PRINT '  ✓ Catálogos de referencia (Colors, StockGroups, PackageTypes, etc.)';
PRINT '  ✓ Catálogo COMPLETO de productos (StockItems, StockItemStockGroups)';
PRINT '  ✓ Catálogos completos (Suppliers, Customers sin sensibles)';
PRINT '';
PRINT 'NOTA: Catálogo de productos debe estar IDÉNTICO en las 3 bases';
PRINT '      ANTES de configurar Merge Replication.';
PRINT '';
PRINT 'ARQUITECTURA:';
PRINT '  • Catálogos estáticos: Cargados IDÉNTICOS (sin SucursalOrigen)';
PRINT '  • Productos (StockItems): IDÉNTICOS inicialmente, cambios futuros se replican';
PRINT '  • Datos operativos: Particionados por sucursal (NO se replican)';
PRINT '';
GO
