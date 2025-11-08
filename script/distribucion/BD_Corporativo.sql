use master;

GO
drop database if exists WWI_Corporativo;
GO

IF DB_ID('WWI_Corporativo') IS NULL
BEGIN
    CREATE DATABASE WWI_Corporativo;
    PRINT 'Database WWI_Corporativo created.';
END
ELSE
BEGIN
    PRINT 'Database WWI_Corporativo already exists.';
END
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

PRINT 'Estructura de base de datos WWI_Corporativo creada exitosamente.';
PRINT '';
PRINT 'ESQUEMAS CREADOS:';
PRINT '  - Application: Tablas auxiliares (Countries, StateProvinces, Cities)';
PRINT '  - Sales: SOLO datos sensibles de clientes';
PRINT '';
PRINT 'PROPOSITO:';
PRINT '  Base de datos centralizada para almacenar UNICAMENTE datos sensibles';
PRINT '  de clientes (contacto, direcciones, ubicacion geografica).';
PRINT '  Los datos no sensibles permanecen en las sucursales (SanJose, Limon).';
PRINT '';
PRINT 'TABLA PRINCIPAL:';
PRINT '  - Sales.CustomerSensitiveData: PhoneNumber, FaxNumber, WebsiteURL,';
PRINT '    DeliveryAddressLine1/2, DeliveryPostalCode, DeliveryLocation';
GO
