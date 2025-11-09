USE master;
GO
-- Poner la base de datos en modo SINGLE_USER para desconectar a todos
ALTER DATABASE WWI_Limon SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
-- Ahora sí eliminar el distribuidor
EXEC sp_dropdistributor @no_checks = 1;
GO

-- Eliminar la base de datos
DROP DATABASE IF EXISTS WWI_Limon;
GO

IF DB_ID('WWI_Limon') IS NULL
BEGIN
    CREATE DATABASE WWI_Limon;
    PRINT 'Database WWI_Limon created.';
END
ELSE
BEGIN
    PRINT 'Database WWI_Limon already exists.';
END
GO

use WWI_Limon;
GO

-- ============================================================
-- CREAR ESQUEMAS
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Sales')
    EXEC('CREATE SCHEMA Sales');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Purchasing')
    EXEC('CREATE SCHEMA Purchasing');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Warehouse')
    EXEC('CREATE SCHEMA Warehouse');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Application')
    EXEC('CREATE SCHEMA Application');
GO

-- ============================================================
-- TABLAS DE APPLICATION (Tablas auxiliares)
-- ============================================================

-- Tabla de métodos de entrega
CREATE TABLE Application.DeliveryMethods (
    DeliveryMethodID INT PRIMARY KEY IDENTITY(1,1),
    DeliveryMethodName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

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

-- Tabla de personas (simplificada, sin datos sensibles)
CREATE TABLE Application.People (
    PersonID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- TABLAS DE SALES (Ventas y Clientes)
-- ============================================================

-- Tabla de categorías de clientes
CREATE TABLE Sales.CustomerCategories (
    CustomerCategoryID INT PRIMARY KEY IDENTITY(1,1),
    CustomerCategoryName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de grupos de compra
CREATE TABLE Sales.BuyingGroups (
    BuyingGroupID INT PRIMARY KEY IDENTITY(1,1),
    BuyingGroupName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de clientes (SIN DATOS SENSIBLES)
-- NO incluye: PhoneNumber, FaxNumber, DeliveryAddressLine1, DeliveryAddressLine2, 
-- DeliveryPostalCode, DeliveryLocation, WebsiteURL
CREATE TABLE Sales.Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
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

-- Tabla de facturas (Invoices)
CREATE TABLE Sales.Invoices (
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

-- ============================================================
-- TABLAS DE WAREHOUSE (Inventario)
-- ============================================================

-- Tabla de colores
CREATE TABLE Warehouse.Colors (
    ColorID INT PRIMARY KEY IDENTITY(1,1),
    ColorName NVARCHAR(20) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de tipos de empaquetamiento
CREATE TABLE Warehouse.PackageTypes (
    PackageTypeID INT PRIMARY KEY IDENTITY(1,1),
    PackageTypeName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de grupos de stock
CREATE TABLE Warehouse.StockGroups (
    StockGroupID INT PRIMARY KEY IDENTITY(1,1),
    StockGroupName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- TABLAS DE PURCHASING (Proveedores)
-- ============================================================

-- Tabla de categorías de proveedores
CREATE TABLE Purchasing.SupplierCategories (
    SupplierCategoryID INT PRIMARY KEY IDENTITY(1,1),
    SupplierCategoryName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1
);
GO

-- Tabla de proveedores (CON todos los datos, incluyendo sensibles)
CREATE TABLE Purchasing.Suppliers (
    SupplierID INT PRIMARY KEY IDENTITY(1,1),
    SupplierName NVARCHAR(100) NOT NULL,
    SupplierCategoryID INT NOT NULL,
    SupplierReference NVARCHAR(20) NULL,
    PrimaryContactPersonID INT NOT NULL,
    AlternateContactPersonID INT NULL,
    DeliveryMethodID INT NULL,
    DeliveryCityID INT NOT NULL,
    PaymentDays INT NOT NULL,
    -- Información de contacto (sensible)
    PhoneNumber NVARCHAR(20) NOT NULL,
    FaxNumber NVARCHAR(20) NOT NULL,
    WebsiteURL NVARCHAR(256) NOT NULL,
    -- Información de dirección (sensible)
    DeliveryAddressLine1 NVARCHAR(60) NOT NULL,
    DeliveryAddressLine2 NVARCHAR(60) NULL,
    DeliveryPostalCode NVARCHAR(10) NOT NULL,
    DeliveryLocation GEOGRAPHY NULL,
    -- Información bancaria (sensible)
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

CREATE TABLE Purchasing.PurchaseOrders (
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

-- ============================================================
-- TABLAS DE WAREHOUSE (Inventario)
-- ============================================================

-- Tabla de items de stock (productos)
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

-- Tabla de holdings de stock (inventario disponible)
CREATE TABLE Warehouse.StockItemHoldings (
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

-- Tabla de relación entre items de stock y grupos
CREATE TABLE Warehouse.StockItemStockGroups (
    StockItemStockGroupID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    StockGroupID INT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID),
    FOREIGN KEY (StockGroupID) REFERENCES Warehouse.StockGroups(StockGroupID)
);
GO

-- Tabla de transacciones de stock
CREATE TABLE Warehouse.StockItemTransactions (
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

-- Tabla de líneas de facturas (detalle de ventas)
CREATE TABLE Sales.InvoiceLines (
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
    FOREIGN KEY (InvoiceID) REFERENCES Sales.Invoices(InvoiceID),
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID)
);
GO

-- Tabla de órdenes de compra (para relación con proveedores)
CREATE TABLE Purchasing.PurchaseOrderLines (
    PurchaseOrderLineID INT PRIMARY KEY IDENTITY(1,1),
    PurchaseOrderID INT NOT NULL,
    StockItemID INT NOT NULL,
    OrderedOuters INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    ReceivedOuters INT NOT NULL,
    LastEditedBy INT NOT NULL DEFAULT 1,
    FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID),
    FOREIGN KEY (PurchaseOrderID) REFERENCES Purchasing.PurchaseOrders(PurchaseOrderID)
);
GO

PRINT 'Estructura de base de datos WWI_Limon creada exitosamente.';
PRINT '';
PRINT 'ESQUEMAS CREADOS:';
PRINT '  - Application: Tablas auxiliares (DeliveryMethods, Cities, People, etc.)';
PRINT '  - Sales: Clientes (SIN datos sensibles) y Ventas';
PRINT '  - Purchasing: Proveedores (CON todos los datos)';
PRINT '  - Warehouse: Inventario completo';
PRINT '';
PRINT 'NOTA: La tabla Sales.Customers NO incluye campos sensibles como:';
PRINT '  PhoneNumber, FaxNumber, DeliveryAddressLine1/2, DeliveryPostalCode,';
PRINT '  DeliveryLocation, WebsiteURL';
GO
