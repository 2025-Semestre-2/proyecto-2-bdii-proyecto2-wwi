-- ============================================================
-- SCRIPT 2: CREACIÓN DE TABLAS - BD_CORPORATIVO
-- ============================================================
-- Contiene:
-- 1. Datos sensibles de clientes (contacto, privacidad)
-- 2. Catálogos maestros (productos, clientes básicos, proveedores)
-- ============================================================

USE BD_Corporativo;
GO

-- ============================================================
-- TABLAS DE REFERENCIA (Catálogos Maestros)
-- ============================================================

-- Categorías de Clientes
CREATE TABLE CustomerCategories (
    CustomerCategoryID INT PRIMARY KEY,
    CustomerCategoryName NVARCHAR(50) NOT NULL
);
GO

-- Grupos de Compra
CREATE TABLE BuyingGroups (
    BuyingGroupID INT PRIMARY KEY,
    BuyingGroupName NVARCHAR(50) NOT NULL
);
GO

-- Métodos de Entrega
CREATE TABLE DeliveryMethods (
    DeliveryMethodID INT PRIMARY KEY,
    DeliveryMethodName NVARCHAR(50) NOT NULL
);
GO

-- Países
CREATE TABLE Countries (
    CountryID INT PRIMARY KEY,
    CountryName NVARCHAR(60) NOT NULL
);
GO

-- Provincias/Estados
CREATE TABLE StateProvinces (
    StateProvinceID INT PRIMARY KEY,
    StateProvinceName NVARCHAR(50) NOT NULL,
    CountryID INT NOT NULL,
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);
GO

-- Ciudades
CREATE TABLE Cities (
    CityID INT PRIMARY KEY,
    CityName NVARCHAR(50) NOT NULL,
    StateProvinceID INT NOT NULL,
    FOREIGN KEY (StateProvinceID) REFERENCES StateProvinces(StateProvinceID)
);
GO

-- Personas (Contactos)
CREATE TABLE People (
    PersonID INT PRIMARY KEY,
    FullName NVARCHAR(50) NOT NULL,
    PhoneNumber NVARCHAR(20),
    FaxNumber NVARCHAR(20),
    EmailAddress NVARCHAR(256)
);
GO

-- ============================================================
-- CLIENTES - Información Básica (Compartida)
-- ============================================================
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    CustomerCategoryID INT NOT NULL,
    BuyingGroupID INT,
    BillToCustomerID INT NOT NULL,
    DeliveryMethodID INT NOT NULL,
    DeliveryCityID INT NOT NULL,
    PaymentDays INT NOT NULL,
    FOREIGN KEY (CustomerCategoryID) REFERENCES CustomerCategories(CustomerCategoryID),
    FOREIGN KEY (BuyingGroupID) REFERENCES BuyingGroups(BuyingGroupID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (DeliveryCityID) REFERENCES Cities(CityID)
);
GO

-- ============================================================
-- CLIENTES - Información Sensible (Solo en Corporativo)
-- ============================================================
CREATE TABLE CustomersSensitiveData (
    CustomerID INT PRIMARY KEY,
    PhoneNumber NVARCHAR(20),
    FaxNumber NVARCHAR(20),
    WebsiteURL NVARCHAR(256),
    DeliveryAddressLine1 NVARCHAR(60),
    DeliveryAddressLine2 NVARCHAR(60),
    DeliveryPostalCode NVARCHAR(10),
    DeliveryLatitude DECIMAL(18,7),
    DeliveryLongitude DECIMAL(18,7),
    PrimaryContactPersonID INT,
    AlternateContactPersonID INT,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (PrimaryContactPersonID) REFERENCES People(PersonID),
    FOREIGN KEY (AlternateContactPersonID) REFERENCES People(PersonID)
);
GO

-- ============================================================
-- PROVEEDORES
-- ============================================================

-- Categorías de Proveedores
CREATE TABLE SupplierCategories (
    SupplierCategoryID INT PRIMARY KEY,
    SupplierCategoryName NVARCHAR(50) NOT NULL
);
GO

-- Proveedores
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    SupplierCategoryID INT NOT NULL,
    SupplierReference NVARCHAR(20),
    DeliveryMethodID INT NULL,  -- Permite NULL
    DeliveryCityID INT NULL,    -- Permite NULL
    PhoneNumber NVARCHAR(20),
    FaxNumber NVARCHAR(20),
    WebsiteURL NVARCHAR(256),
    DeliveryAddressLine1 NVARCHAR(60),
    DeliveryAddressLine2 NVARCHAR(60),
    DeliveryPostalCode NVARCHAR(10),
    DeliveryLatitude DECIMAL(18,7),
    DeliveryLongitude DECIMAL(18,7),
    PaymentDays INT NOT NULL DEFAULT 0,  -- Valor por defecto
    PrimaryContactPersonID INT,
    AlternateContactPersonID INT,
    BankAccountName NVARCHAR(50),
    BankAccountBranch NVARCHAR(50),
    BankAccountCode NVARCHAR(20),
    BankAccountNumber NVARCHAR(20),
    BankInternationalCode NVARCHAR(20),
    FOREIGN KEY (SupplierCategoryID) REFERENCES SupplierCategories(SupplierCategoryID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (DeliveryCityID) REFERENCES Cities(CityID),
    FOREIGN KEY (PrimaryContactPersonID) REFERENCES People(PersonID),
    FOREIGN KEY (AlternateContactPersonID) REFERENCES People(PersonID)
);
GO

-- ============================================================
-- PRODUCTOS (Catálogo Maestro)
-- ============================================================

-- Colores
CREATE TABLE Colors (
    ColorID INT PRIMARY KEY,
    ColorName NVARCHAR(20) NOT NULL
);
GO

-- Tipos de Empaquetamiento
CREATE TABLE PackageTypes (
    PackageTypeID INT PRIMARY KEY,
    PackageTypeName NVARCHAR(50) NOT NULL
);
GO

-- Grupos de Productos
CREATE TABLE StockGroups (
    StockGroupID INT PRIMARY KEY,
    StockGroupName NVARCHAR(50) NOT NULL
);
GO

-- Productos (Items de Stock)
CREATE TABLE StockItems (
    StockItemID INT PRIMARY KEY,
    StockItemName NVARCHAR(100) NOT NULL,
    SupplierID INT NOT NULL,
    ColorID INT,
    UnitPackageID INT NOT NULL,
    OuterPackageID INT NOT NULL,
    Brand NVARCHAR(50),
    Size NVARCHAR(20),
    LeadTimeDays INT NOT NULL,
    QuantityPerOuter INT NOT NULL,
    IsChillerStock BIT NOT NULL,
    Barcode NVARCHAR(50),
    TaxRate DECIMAL(18,3) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    RecommendedRetailPrice DECIMAL(18,2),
    TypicalWeightPerUnit DECIMAL(18,3),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (ColorID) REFERENCES Colors(ColorID),
    FOREIGN KEY (UnitPackageID) REFERENCES PackageTypes(PackageTypeID),
    FOREIGN KEY (OuterPackageID) REFERENCES PackageTypes(PackageTypeID)
);
GO

-- Relación Productos - Grupos de Stock
CREATE TABLE StockItemStockGroups (
    StockItemStockGroupID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    StockGroupID INT NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID),
    FOREIGN KEY (StockGroupID) REFERENCES StockGroups(StockGroupID)
);
GO

PRINT '=================================================';
PRINT 'TABLAS DE BD_CORPORATIVO CREADAS EXITOSAMENTE';
PRINT '=================================================';
