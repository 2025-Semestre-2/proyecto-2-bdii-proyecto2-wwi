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
PRINT '  ✓ Catálogos de referencia (para constraints)';
PRINT '';
PRINT 'NOTA: Los datos operativos (Clientes, Productos, Ventas, etc.)';
PRINT '      llegarán automáticamente por REPLICACIÓN SQL SERVER';
PRINT '      desde las sucursales SanJose y Limon.';
PRINT '';
GO
