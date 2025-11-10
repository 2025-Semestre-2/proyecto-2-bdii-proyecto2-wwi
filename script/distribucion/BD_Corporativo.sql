USE master;
GO

-- Limpiar replicación si existe
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'WWI_Corporativo')
BEGIN
    EXEC sp_removedbreplication 'WWI_Corporativo';
END
GO

-- Eliminar distribuidor si existe
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'distribution')
BEGIN
    EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1;
END
GO

-- Eliminar base de datos
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'WWI_Corporativo')
BEGIN
    ALTER DATABASE WWI_Corporativo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE WWI_Corporativo;
    PRINT 'Database WWI_Corporativo dropped.';
END
GO

-- Crear base de datos
CREATE DATABASE WWI_Corporativo;
PRINT 'Database WWI_Corporativo created.';
GO

use WWI_Corporativo;
GO

-- ============================================================
-- CREAR ESQUEMAS
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Sales')
    EXEC('CREATE SCHEMA Sales');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Application')
    EXEC('CREATE SCHEMA Application');
GO

-- ============================================================
-- TABLAS DE APPLICATION (Tablas auxiliares mínimas)
-- ============================================================

-- Tabla de países
CREATE TABLE Application.Countries (
    CountryID INT PRIMARY KEY IDENTITY(1,1),
    CountryName NVARCHAR(60) NOT NULL,
    FormalName NVARCHAR(60) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de provincias/estados
CREATE TABLE Application.StateProvinces (
    StateProvinceID INT PRIMARY KEY IDENTITY(1,1),
    StateProvinceCode NVARCHAR(5) NOT NULL,
    StateProvinceName NVARCHAR(50) NOT NULL,
    CountryID INT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (CountryID) REFERENCES Application.Countries(CountryID)
);
GO

-- Tabla de ciudades
CREATE TABLE Application.Cities (
    CityID INT PRIMARY KEY IDENTITY(1,1),
    CityName NVARCHAR(50) NOT NULL,
    StateProvinceID INT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (StateProvinceID) REFERENCES Application.StateProvinces(StateProvinceID)
);
GO

-- ============================================================
-- TABLA DE SALES (SOLO DATOS SENSIBLES DE CLIENTES)
-- ============================================================

-- Tabla de datos sensibles de clientes
-- SOLO contiene información privada y de contacto
CREATE TABLE Sales.CustomerSensitiveData (
    CustomerID INT PRIMARY KEY,
    -- Información de contacto (sensible)
    PhoneNumber NVARCHAR(20) NULL,
    FaxNumber NVARCHAR(20) NULL,
    WebsiteURL NVARCHAR(256) NULL,
    -- Información de dirección (sensible)
    DeliveryAddressLine1 NVARCHAR(60) NULL,
    DeliveryAddressLine2 NVARCHAR(60) NULL,
    DeliveryPostalCode NVARCHAR(10) NULL,
    DeliveryCityID INT NULL,
    -- Ubicación geográfica (sensible)
    DeliveryLocation GEOGRAPHY NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (DeliveryCityID) REFERENCES Application.Cities(CityID)
);
GO

-- ============================================================
-- CREAR ESQUEMAS ADICIONALES PARA REPLICACIÓN
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Purchasing')
    EXEC('CREATE SCHEMA Purchasing');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Warehouse')
    EXEC('CREATE SCHEMA Warehouse');
GO

-- ============================================================
-- TABLAS REPLICADAS PARA ESTADÍSTICAS CONSOLIDADAS
-- ============================================================

-- Tabla de categorías de clientes (réplica)
CREATE TABLE Sales.CustomerCategories (
    CustomerCategoryID INT PRIMARY KEY,
    CustomerCategoryName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de grupos de compra (réplica)
CREATE TABLE Sales.BuyingGroups (
    BuyingGroupID INT PRIMARY KEY,
    BuyingGroupName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de personas (réplica simplificada)
CREATE TABLE Application.People (
    PersonID INT PRIMARY KEY,
    FullName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de métodos de entrega (réplica)
CREATE TABLE Application.DeliveryMethods (
    DeliveryMethodID INT PRIMARY KEY,
    DeliveryMethodName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- PRIMERO: TABLAS DE WAREHOUSE (sin FK a otras tablas complejas)
-- ============================================================

-- Tabla de grupos de stock (réplica)
CREATE TABLE Warehouse.StockGroups (
    StockGroupID INT PRIMARY KEY,
    StockGroupName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de colores (réplica)
CREATE TABLE Warehouse.Colors (
    ColorID INT PRIMARY KEY,
    ColorName NVARCHAR(20) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de tipos de empaquetamiento (réplica)
CREATE TABLE Warehouse.PackageTypes (
    PackageTypeID INT PRIMARY KEY,
    PackageTypeName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- SEGUNDO: TABLAS DE PURCHASING
-- ============================================================

-- Tabla de categorías de proveedores (réplica)
CREATE TABLE Purchasing.SupplierCategories (
    SupplierCategoryID INT PRIMARY KEY,
    SupplierCategoryName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de proveedores consolidada (réplica completa)
CREATE TABLE Purchasing.Suppliers (
    SupplierID INT PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    SupplierCategoryID INT NOT NULL,
    SupplierReference NVARCHAR(20) NULL,
    PrimaryContactPersonID INT NOT NULL,
    AlternateContactPersonID INT NULL,
    DeliveryMethodID INT NULL,
    DeliveryCityID INT NOT NULL,
    PaymentDays INT NOT NULL,
    PhoneNumber NVARCHAR(20) NOT NULL,
    FaxNumber NVARCHAR(20) NOT NULL,
    WebsiteURL NVARCHAR(256) NOT NULL,
    DeliveryAddressLine1 NVARCHAR(60) NOT NULL,
    DeliveryAddressLine2 NVARCHAR(60) NULL,
    DeliveryPostalCode NVARCHAR(10) NOT NULL,
    DeliveryLocation GEOGRAPHY NULL,
    BankAccountName NVARCHAR(50) NULL,
    BankAccountBranch NVARCHAR(50) NULL,
    BankAccountCode NVARCHAR(20) NULL,
    BankAccountNumber NVARCHAR(20) NULL,
    BankInternationalCode NVARCHAR(20) NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (SupplierCategoryID) REFERENCES Purchasing.SupplierCategories(SupplierCategoryID),
    FOREIGN KEY (PrimaryContactPersonID) REFERENCES Application.People(PersonID),
    FOREIGN KEY (AlternateContactPersonID) REFERENCES Application.People(PersonID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (DeliveryCityID) REFERENCES Application.Cities(CityID)
);
GO

-- ============================================================
-- TERCERO: TABLA DE ITEMS (depende de Suppliers, Colors, PackageTypes)
-- ============================================================

-- Tabla de items de stock consolidada (réplica completa)
CREATE TABLE Warehouse.StockItems (
    StockItemID INT PRIMARY KEY IDENTITY(1,1),
    StockItemName NVARCHAR(100) NOT NULL,
    SupplierID INT NOT NULL,
    ColorID INT NULL,
    UnitPackageID INT NOT NULL,
    OuterPackageID INT NOT NULL,
    Brand NVARCHAR(50) NULL,
    Size NVARCHAR(20) NULL,
    LeadTimeDays INT NOT NULL,
    QuantityPerOuter INT NOT NULL,
    IsChillerStock BIT NOT NULL,
    Barcode NVARCHAR(50) NULL,
    TaxRate DECIMAL(18,3) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    RecommendedRetailPrice DECIMAL(18,2) NULL,
    TypicalWeightPerUnit DECIMAL(18,3) NOT NULL,
    MarketingComments NVARCHAR(MAX) NULL,
    InternalComments NVARCHAR(MAX) NULL,
    Photo VARBINARY(MAX) NULL,
    CustomFields NVARCHAR(MAX) NULL,
    SearchDetails NVARCHAR(MAX) NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (SupplierID) REFERENCES Purchasing.Suppliers(SupplierID),
    FOREIGN KEY (ColorID) REFERENCES Warehouse.Colors(ColorID),
    FOREIGN KEY (UnitPackageID) REFERENCES Warehouse.PackageTypes(PackageTypeID),
    FOREIGN KEY (OuterPackageID) REFERENCES Warehouse.PackageTypes(PackageTypeID)
);
GO

-- ============================================================
-- CUARTO: TABLAS QUE DEPENDEN DE STOCKITEMS
-- ============================================================

-- Tabla de relación entre items de stock y grupos (réplica)
CREATE TABLE Warehouse.StockItemStockGroups (
    StockItemStockGroupID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    StockGroupID INT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID),
    FOREIGN KEY (StockGroupID) REFERENCES Warehouse.StockGroups(StockGroupID)
);
GO

-- ============================================================
-- TABLAS DE WAREHOUSE - RÉPLICAS DE SUCURSALES
-- ============================================================

-- Tabla de holdings de SanJose (réplica exacta)
CREATE TABLE Warehouse.StockItemHoldings_SJ (
    StockItemID INT PRIMARY KEY,
    QuantityOnHand INT NOT NULL,
    BinLocation NVARCHAR(20) NOT NULL,
    LastStocktakeQuantity INT NOT NULL,
    LastCostPrice DECIMAL(18,2) NOT NULL,
    ReorderLevel INT NOT NULL,
    TargetStockLevel INT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    LastEditedWhen DATETIME2 NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

-- Tabla de holdings de Limon (réplica exacta)
CREATE TABLE Warehouse.StockItemHoldings_Limon (
    StockItemID INT PRIMARY KEY,
    QuantityOnHand INT NOT NULL,
    BinLocation NVARCHAR(20) NOT NULL,
    LastStocktakeQuantity INT NOT NULL,
    LastCostPrice DECIMAL(18,2) NOT NULL,
    ReorderLevel INT NOT NULL,
    TargetStockLevel INT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    LastEditedWhen DATETIME2 NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

-- Tabla de transacciones de SanJose (réplica exacta)
CREATE TABLE Warehouse.StockItemTransactions_SJ (
    StockItemTransactionID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    CustomerID INT NULL,
    InvoiceID INT NULL,
    SupplierID INT NULL,
    PurchaseOrderID INT NULL,
    TransactionOccurredWhen DATETIME2 NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    LastEditedWhen DATETIME2 NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

-- Tabla de transacciones de Limon (réplica exacta)
CREATE TABLE Warehouse.StockItemTransactions_Limon (
    StockItemTransactionID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    CustomerID INT NULL,
    InvoiceID INT NULL,
    SupplierID INT NULL,
    PurchaseOrderID INT NULL,
    TransactionOccurredWhen DATETIME2 NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    LastEditedWhen DATETIME2 NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

-- ============================================================
-- QUINTO: TABLAS DE SALES
-- ============================================================

-- Tabla de clientes consolidada (réplica sin datos sensibles)
CREATE TABLE Sales.Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    CustomerCategoryID INT NOT NULL,
    BuyingGroupID INT NULL,
    BillToCustomerID INT NOT NULL,
    PrimaryContactPersonID INT NOT NULL,
    AlternateContactPersonID INT NULL,
    DeliveryCityID INT NOT NULL,
    DeliveryMethodID INT NULL,
    PaymentDays INT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (CustomerCategoryID) REFERENCES Sales.CustomerCategories(CustomerCategoryID),
    FOREIGN KEY (BuyingGroupID) REFERENCES Sales.BuyingGroups(BuyingGroupID),
    FOREIGN KEY (DeliveryCityID) REFERENCES Application.Cities(CityID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (PrimaryContactPersonID) REFERENCES Application.People(PersonID),
    FOREIGN KEY (AlternateContactPersonID) REFERENCES Application.People(PersonID)
);
GO

-- ============================================================
-- TABLAS DE SALES - RÉPLICAS DE SUCURSALES
-- ============================================================

-- Tabla de facturas de SanJose (réplica exacta)
CREATE TABLE Sales.Invoices_SJ (
    InvoiceID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    InvoiceDate DATE NOT NULL,
    DeliveryMethodID INT NULL,
    CustomerPurchaseOrderNumber NVARCHAR(20) NULL,
    ContactPersonID INT NOT NULL,
    SalespersonPersonID INT NOT NULL,
    DeliveryInstructions NVARCHAR(MAX) NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (CustomerID) REFERENCES Sales.Customers(CustomerID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (ContactPersonID) REFERENCES Application.People(PersonID),
    FOREIGN KEY (SalespersonPersonID) REFERENCES Application.People(PersonID)
);
GO

-- Tabla de facturas de Limon (réplica exacta)
CREATE TABLE Sales.Invoices_Limon (
    InvoiceID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    InvoiceDate DATE NOT NULL,
    DeliveryMethodID INT NULL,
    CustomerPurchaseOrderNumber NVARCHAR(20) NULL,
    ContactPersonID INT NOT NULL,
    SalespersonPersonID INT NOT NULL,
    DeliveryInstructions NVARCHAR(MAX) NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (CustomerID) REFERENCES Sales.Customers(CustomerID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (ContactPersonID) REFERENCES Application.People(PersonID),
    FOREIGN KEY (SalespersonPersonID) REFERENCES Application.People(PersonID)
);
GO

-- Tabla de líneas de facturas de SanJose (réplica exacta)
CREATE TABLE Sales.InvoiceLines_SJ (
    InvoiceLineID INT PRIMARY KEY IDENTITY(1,1),
    InvoiceID INT NOT NULL,
    StockItemID INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NULL,
    TaxRate DECIMAL(18,3) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL,
    LineProfit DECIMAL(18,2) NOT NULL,
    ExtendedPrice DECIMAL(18,2) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (InvoiceID) REFERENCES Sales.Invoices_SJ(InvoiceID),
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

-- Tabla de líneas de facturas de Limon (réplica exacta)
CREATE TABLE Sales.InvoiceLines_Limon (
    InvoiceLineID INT PRIMARY KEY IDENTITY(1,1),
    InvoiceID INT NOT NULL,
    StockItemID INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NULL,
    TaxRate DECIMAL(18,3) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL,
    LineProfit DECIMAL(18,2) NOT NULL,
    ExtendedPrice DECIMAL(18,2) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (InvoiceID) REFERENCES Sales.Invoices_Limon(InvoiceID),
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

-- ============================================================
-- SEXTO: TABLAS DE PURCHASING QUE DEPENDEN DE STOCKITEMS
-- ============================================================

-- ============================================================
-- TABLAS DE PURCHASING - RÉPLICAS DE SUCURSALES
-- ============================================================

-- Tabla de órdenes de compra de SanJose (réplica exacta)
CREATE TABLE Purchasing.PurchaseOrders_SJ (
    PurchaseOrderID INT PRIMARY KEY IDENTITY(1,1),
    SupplierID INT NOT NULL,
    OrderDate DATE NOT NULL,
    ExpectedDeliveryDate DATE NOT NULL,
    DeliveryMethodID INT NULL,
    ContactPersonID INT NOT NULL,
    SupplierReference NVARCHAR(20) NULL,
    IsOrderFinalized BIT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (SupplierID) REFERENCES Purchasing.Suppliers(SupplierID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (ContactPersonID) REFERENCES Application.People(PersonID)
);
GO

-- Tabla de órdenes de compra de Limon (réplica exacta)
CREATE TABLE Purchasing.PurchaseOrders_Limon (
    PurchaseOrderID INT PRIMARY KEY IDENTITY(1,1),
    SupplierID INT NOT NULL,
    OrderDate DATE NOT NULL,
    ExpectedDeliveryDate DATE NOT NULL,
    DeliveryMethodID INT NULL,
    ContactPersonID INT NOT NULL,
    SupplierReference NVARCHAR(20) NULL,
    IsOrderFinalized BIT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (SupplierID) REFERENCES Purchasing.Suppliers(SupplierID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (ContactPersonID) REFERENCES Application.People(PersonID)
);
GO

-- Tabla de líneas de órdenes de compra de SanJose (réplica exacta)
CREATE TABLE Purchasing.PurchaseOrderLines_SJ (
    PurchaseOrderLineID INT PRIMARY KEY IDENTITY(1,1),
    PurchaseOrderID INT NOT NULL,
    StockItemID INT NOT NULL,
    OrderedOuters INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    ReceivedOuters INT NOT NULL,
    ExpectedUnitPricePerOuter DECIMAL(18,2) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (PurchaseOrderID) REFERENCES Purchasing.PurchaseOrders_SJ(PurchaseOrderID),
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

-- Tabla de líneas de órdenes de compra de Limon (réplica exacta)
CREATE TABLE Purchasing.PurchaseOrderLines_Limon (
    PurchaseOrderLineID INT PRIMARY KEY IDENTITY(1,1),
    PurchaseOrderID INT NOT NULL,
    StockItemID INT NOT NULL,
    OrderedOuters INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    ReceivedOuters INT NOT NULL,
    ExpectedUnitPricePerOuter DECIMAL(18,2) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (PurchaseOrderID) REFERENCES Purchasing.PurchaseOrders_Limon(PurchaseOrderID),
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

PRINT 'Estructura de base de datos WWI_Corporativo creada exitosamente.';
PRINT '';
PRINT 'ESQUEMAS CREADOS:';
PRINT '  - Application: Tablas auxiliares (Countries, StateProvinces, Cities, People, DeliveryMethods)';
PRINT '  - Sales: Datos sensibles de clientes + Réplicas de SJ y Limon';
PRINT '  - Purchasing: Réplicas de proveedores y órdenes de SJ y Limon';
PRINT '  - Warehouse: Réplicas de productos e inventario de SJ y Limon';
PRINT '';
PRINT 'PROPOSITO:';
PRINT '  1. Almacenar datos sensibles de clientes (Sales.CustomerSensitiveData)';
PRINT '  2. Consolidar réplicas de AMBAS sucursales para disaster recovery';
PRINT '  3. Generar estadísticas consolidadas desde tablas separadas';
PRINT '';
PRINT 'TABLAS REPLICADAS (POR SUCURSAL):';
PRINT '  - Warehouse: StockItemHoldings_SJ, StockItemHoldings_Limon';
PRINT '  - Warehouse: StockItemTransactions_SJ, StockItemTransactions_Limon';
PRINT '  - Sales: Invoices_SJ, Invoices_Limon, InvoiceLines_SJ, InvoiceLines_Limon';
PRINT '  - Purchasing: PurchaseOrders_SJ, PurchaseOrders_Limon, PurchaseOrderLines_SJ, PurchaseOrderLines_Limon';
PRINT '';
PRINT 'VENTAJAS:';
PRINT '  ✓ Sin conflictos de IDs (tablas separadas por sucursal)';
PRINT '  ✓ Replicación directa (nombre a nombre)';
PRINT '  ✓ Disaster recovery completo (copia exacta de cada sucursal)';
PRINT '  ✓ Estadísticas con UNION ALL entre tablas _SJ y _Limon';
GO

