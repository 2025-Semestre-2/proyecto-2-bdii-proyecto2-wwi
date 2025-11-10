-- ============================================================
-- STORED PROCEDURES DE PROVEEDORES - SAN JOSÉ
-- ============================================================
-- Procedimientos para gestión de proveedores en sucursal San José
-- Base de datos: WWI_SanJose
-- ============================================================

USE WWI_SanJose;
GO

-- ============================================================
-- SP: Obtener lista de proveedores con filtros
-- ============================================================
CREATE OR ALTER PROCEDURE sp_obtenerProveedores
  @search   NVARCHAR(100) = NULL,  
  @category NVARCHAR(100) = NULL   
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    s.SupplierID,
    s.SupplierName AS NombreProveedor,
    sc.SupplierCategoryName AS Categoria,
    dm.DeliveryMethodName    AS MetodoEntrega
  FROM Purchasing.Suppliers s
  INNER JOIN Purchasing.SupplierCategories sc
    ON sc.SupplierCategoryID = s.SupplierCategoryID
  LEFT  JOIN Application.DeliveryMethods dm
    ON dm.DeliveryMethodID = s.DeliveryMethodID
  WHERE (@search   IS NULL OR s.SupplierName          LIKE '%' + @search   + '%')
    AND (@category IS NULL OR sc.SupplierCategoryName LIKE '%' + @category + '%')
  ORDER BY s.SupplierName ASC;
END;
GO

-- ============================================================
-- SP: Obtener detalle completo de un proveedor
-- ============================================================
CREATE OR ALTER PROCEDURE sp_obtenerDetalleProveedor
  @supplierid INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    s.SupplierID,
    s.SupplierReference,
    s.SupplierName,
    sc.SupplierCategoryName       AS Categoria,

    s.WebsiteURL,
    s.PhoneNumber,
    s.FaxNumber,
    s.PaymentDays,

    s.DeliveryAddressLine1,
    s.DeliveryAddressLine2,
    s.DeliveryPostalCode          AS CodigoPostal,

    s.DeliveryMethodID,
    dm.DeliveryMethodName,

    s.DeliveryLocation,
    s.DeliveryLocation.Lat        AS Lat,
    s.DeliveryLocation.Long       AS Lng,

    cit.CityID                    AS DeliveryCityID,
    cit.CityName                  AS DeliveryCityName,
    sp.StateProvinceName          AS DeliveryStateProvinceName,
    co.CountryName                AS DeliveryCountryName,

    p1.FullName                   AS PrimaryContactName,
    p2.FullName                   AS AlternateContactName,

    s.BankAccountName             AS BankName,
    s.BankAccountBranch           AS BankBranch,
    s.BankAccountCode             AS BankCode,
    s.BankAccountNumber           AS AccountNumber,
    s.BankInternationalCode       AS BankInternationalCode

  FROM Purchasing.Suppliers s
  LEFT JOIN Purchasing.SupplierCategories  sc  ON sc.SupplierCategoryID = s.SupplierCategoryID
  LEFT JOIN Application.DeliveryMethods    dm  ON dm.DeliveryMethodID   = s.DeliveryMethodID
  LEFT JOIN Application.Cities            cit  ON cit.CityID            = s.DeliveryCityID
  LEFT JOIN Application.StateProvinces     sp  ON sp.StateProvinceID    = cit.StateProvinceID
  LEFT JOIN Application.Countries          co  ON co.CountryID          = sp.CountryID
  LEFT JOIN Application.People             p1  ON p1.PersonID           = s.PrimaryContactPersonID
  LEFT JOIN Application.People             p2  ON p2.PersonID           = s.AlternateContactPersonID
  WHERE s.SupplierID = @supplierid;
END;
GO

PRINT '✅ Stored Procedures de Proveedores creados para SAN JOSÉ';
PRINT '';
PRINT 'Procedures disponibles:';
PRINT '  • sp_obtenerProveedores - Lista de proveedores con filtros';
PRINT '  • sp_obtenerDetalleProveedor - Detalle completo de un proveedor';
PRINT '';
PRINT '⚠️  NOTA: La tabla Suppliers es compartida (replicada) entre las 3 bases.';
GO
