-- ============================================================
-- SCRIPT 3: CREACIÓN DE TABLAS - BD_SANJOS Y BD_LIMON
-- ============================================================
-- Contiene:
-- 1. Réplica de catálogos (clientes básicos, productos, proveedores)
-- 2. Inventario propio de cada sucursal
-- 3. Ventas propias de cada sucursal
-- ============================================================

-- ============================================================
-- SUCURSAL SAN JOSÉ
-- ============================================================
USE BD_SanJose;
GO

-- ============================================================
-- TABLAS DE REFERENCIA (Réplica de Catálogos)
-- ============================================================

CREATE TABLE CustomerCategories (
    CustomerCategoryID INT PRIMARY KEY,
    CustomerCategoryName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE BuyingGroups (
    BuyingGroupID INT PRIMARY KEY,
    BuyingGroupName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE DeliveryMethods (
    DeliveryMethodID INT PRIMARY KEY,
    DeliveryMethodName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE Countries (
    CountryID INT PRIMARY KEY,
    CountryName NVARCHAR(60) NOT NULL
);
GO

CREATE TABLE StateProvinces (
    StateProvinceID INT PRIMARY KEY,
    StateProvinceName NVARCHAR(50) NOT NULL,
    CountryID INT NOT NULL,
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);
GO

CREATE TABLE Cities (
    CityID INT PRIMARY KEY,
    CityName NVARCHAR(50) NOT NULL,
    StateProvinceID INT NOT NULL,
    FOREIGN KEY (StateProvinceID) REFERENCES StateProvinces(StateProvinceID)
);
GO

CREATE TABLE People (
    PersonID INT PRIMARY KEY,
    FullName NVARCHAR(50) NOT NULL
);
GO

-- Clientes (Sin datos sensibles)
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

-- Categorías de Proveedores
CREATE TABLE SupplierCategories (
    SupplierCategoryID INT PRIMARY KEY,
    SupplierCategoryName NVARCHAR(50) NOT NULL
);
GO

-- Proveedores (versión simplificada para sucursales)
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    SupplierCategoryID INT NOT NULL,
    PhoneNumber NVARCHAR(20),
    FOREIGN KEY (SupplierCategoryID) REFERENCES SupplierCategories(SupplierCategoryID)
);
GO

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

-- Productos (Catálogo)
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

CREATE TABLE StockItemStockGroups (
    StockItemStockGroupID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    StockGroupID INT NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID),
    FOREIGN KEY (StockGroupID) REFERENCES StockGroups(StockGroupID)
);
GO

-- ============================================================
-- INVENTARIO - ESPECÍFICO DE SUCURSAL SAN JOSÉ
-- ============================================================

CREATE TABLE StockItemHoldings (
    StockItemID INT PRIMARY KEY,
    QuantityOnHand INT NOT NULL,
    BinLocation NVARCHAR(20),
    LastStocktakeQuantity INT NOT NULL,
    LastCostPrice DECIMAL(18,2) NOT NULL,
    ReorderLevel INT NOT NULL,
    TargetStockLevel INT NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID)
);
GO

-- Tipos de Transacciones
CREATE TABLE TransactionTypes (
    TransactionTypeID INT PRIMARY KEY,
    TransactionTypeName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE StockItemTransactions (
    StockItemTransactionID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    CustomerID INT,
    InvoiceID INT,
    SupplierID INT,
    PurchaseOrderID INT,
    TransactionOccurredWhen DATETIME2 NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID),
    FOREIGN KEY (TransactionTypeID) REFERENCES TransactionTypes(TransactionTypeID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
GO

-- ============================================================
-- VENTAS - ESPECÍFICO DE SUCURSAL SAN JOSÉ
-- ============================================================

CREATE TABLE Invoices (
    InvoiceID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    BillToCustomerID INT NOT NULL,
    InvoiceDate DATE NOT NULL,
    DeliveryMethodID INT NOT NULL,
    ContactPersonID INT,
    SalespersonPersonID INT,
    CustomerPurchaseOrderNumber NVARCHAR(20),
    DeliveryInstructions NVARCHAR(MAX),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (ContactPersonID) REFERENCES People(PersonID),
    FOREIGN KEY (SalespersonPersonID) REFERENCES People(PersonID)
);
GO

CREATE TABLE InvoiceLines (
    InvoiceLineID INT PRIMARY KEY IDENTITY(1,1),
    InvoiceID INT NOT NULL,
    StockItemID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    TaxRate DECIMAL(18,3) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL,
    ExtendedPrice DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (InvoiceID) REFERENCES Invoices(InvoiceID),
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID)
);
GO

PRINT '=================================================';
PRINT 'TABLAS DE BD_SANJOSE CREADAS EXITOSAMENTE';
PRINT '=================================================';

-- ============================================================
-- SUCURSAL LIMÓN (Misma estructura que San José)
-- ============================================================
USE BD_Limon;
GO

-- ============================================================
-- TABLAS DE REFERENCIA (Réplica de Catálogos)
-- ============================================================

CREATE TABLE CustomerCategories (
    CustomerCategoryID INT PRIMARY KEY,
    CustomerCategoryName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE BuyingGroups (
    BuyingGroupID INT PRIMARY KEY,
    BuyingGroupName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE DeliveryMethods (
    DeliveryMethodID INT PRIMARY KEY,
    DeliveryMethodName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE Countries (
    CountryID INT PRIMARY KEY,
    CountryName NVARCHAR(60) NOT NULL
);
GO

CREATE TABLE StateProvinces (
    StateProvinceID INT PRIMARY KEY,
    StateProvinceName NVARCHAR(50) NOT NULL,
    CountryID INT NOT NULL,
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);
GO

CREATE TABLE Cities (
    CityID INT PRIMARY KEY,
    CityName NVARCHAR(50) NOT NULL,
    StateProvinceID INT NOT NULL,
    FOREIGN KEY (StateProvinceID) REFERENCES StateProvinces(StateProvinceID)
);
GO

CREATE TABLE People (
    PersonID INT PRIMARY KEY,
    FullName NVARCHAR(50) NOT NULL
);
GO

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

CREATE TABLE SupplierCategories (
    SupplierCategoryID INT PRIMARY KEY,
    SupplierCategoryName NVARCHAR(50) NOT NULL
);
GO

-- Proveedores (versión simplificada para sucursales)
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    SupplierCategoryID INT NOT NULL,
    PhoneNumber NVARCHAR(20),
    FOREIGN KEY (SupplierCategoryID) REFERENCES SupplierCategories(SupplierCategoryID)
);
GO

CREATE TABLE Colors (
    ColorID INT PRIMARY KEY,
    ColorName NVARCHAR(20) NOT NULL
);
GO

CREATE TABLE PackageTypes (
    PackageTypeID INT PRIMARY KEY,
    PackageTypeName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE StockGroups (
    StockGroupID INT PRIMARY KEY,
    StockGroupName NVARCHAR(50) NOT NULL
);
GO

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

CREATE TABLE StockItemStockGroups (
    StockItemStockGroupID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    StockGroupID INT NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID),
    FOREIGN KEY (StockGroupID) REFERENCES StockGroups(StockGroupID)
);
GO

-- ============================================================
-- INVENTARIO - ESPECÍFICO DE SUCURSAL LIMÓN
-- ============================================================

CREATE TABLE StockItemHoldings (
    StockItemID INT PRIMARY KEY,
    QuantityOnHand INT NOT NULL,
    BinLocation NVARCHAR(20),
    LastStocktakeQuantity INT NOT NULL,
    LastCostPrice DECIMAL(18,2) NOT NULL,
    ReorderLevel INT NOT NULL,
    TargetStockLevel INT NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID)
);
GO

CREATE TABLE TransactionTypes (
    TransactionTypeID INT PRIMARY KEY,
    TransactionTypeName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE StockItemTransactions (
    StockItemTransactionID INT PRIMARY KEY IDENTITY(1,1),
    StockItemID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    CustomerID INT,
    InvoiceID INT,
    SupplierID INT,
    PurchaseOrderID INT,
    TransactionOccurredWhen DATETIME2 NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID),
    FOREIGN KEY (TransactionTypeID) REFERENCES TransactionTypes(TransactionTypeID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
GO

-- ============================================================
-- VENTAS - ESPECÍFICO DE SUCURSAL LIMÓN
-- ============================================================

CREATE TABLE Invoices (
    InvoiceID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    BillToCustomerID INT NOT NULL,
    InvoiceDate DATE NOT NULL,
    DeliveryMethodID INT NOT NULL,
    ContactPersonID INT,
    SalespersonPersonID INT,
    CustomerPurchaseOrderNumber NVARCHAR(20),
    DeliveryInstructions NVARCHAR(MAX),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (DeliveryMethodID) REFERENCES DeliveryMethods(DeliveryMethodID),
    FOREIGN KEY (ContactPersonID) REFERENCES People(PersonID),
    FOREIGN KEY (SalespersonPersonID) REFERENCES People(PersonID)
);
GO

CREATE TABLE InvoiceLines (
    InvoiceLineID INT PRIMARY KEY IDENTITY(1,1),
    InvoiceID INT NOT NULL,
    StockItemID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    TaxRate DECIMAL(18,3) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL,
    ExtendedPrice DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (InvoiceID) REFERENCES Invoices(InvoiceID),
    FOREIGN KEY (StockItemID) REFERENCES StockItems(StockItemID)
);
GO

PRINT '=================================================';
PRINT 'TABLAS DE BD_LIMON CREADAS EXITOSAMENTE';
PRINT '=================================================';
