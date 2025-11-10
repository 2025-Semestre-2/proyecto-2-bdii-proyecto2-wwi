-- ============================================================
-- STORED PROCEDURES DE CLIENTES - SAN JOSÉ
-- ============================================================
-- Procedimientos para gestión de clientes en sucursal San José
-- Base de datos: WWI_SanJose
-- ============================================================

USE WWI_SanJose;
GO

-- Limpiar procedures si existen en master (error común)
IF EXISTS (SELECT 1 FROM master.sys.procedures WHERE name = 'sp_obtenerClientes')
BEGIN
    EXEC('USE master; DROP PROCEDURE sp_obtenerClientes;');
    PRINT '⚠️  Eliminado sp_obtenerClientes de master (ubicación incorrecta)';
END
GO

IF EXISTS (SELECT 1 FROM master.sys.procedures WHERE name = 'sp_obtenerDetalleCliente')
BEGIN
    EXEC('USE master; DROP PROCEDURE sp_obtenerDetalleCliente;');
    PRINT '⚠️  Eliminado sp_obtenerDetalleCliente de master (ubicación incorrecta)';
END
GO

-- ============================================================
-- SP: Obtener lista de clientes con filtros
-- ============================================================
CREATE OR ALTER PROCEDURE sp_obtenerClientes
  @search NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    c.CustomerID,
    c.CustomerName AS NombreCliente,
    cat.CustomerCategoryName AS Categoria,
    dm.DeliveryMethodName AS MetodoEntrega
  FROM Sales.Customers c
  INNER JOIN Sales.CustomerCategories cat
    ON cat.CustomerCategoryID = c.CustomerCategoryID
  LEFT JOIN Application.DeliveryMethods dm
    ON dm.DeliveryMethodID = c.DeliveryMethodID
  WHERE (@search IS NULL OR c.CustomerName LIKE '%' + @search + '%')
  ORDER BY c.CustomerName ASC;
END;
GO

-- ============================================================
-- SP: Obtener detalle completo de un cliente
-- ============================================================
-- Usa OPENQUERY para evitar problemas con tipos CLR (GEOGRAPHY)
-- en consultas distribuidas via linked server
-- ============================================================
CREATE OR ALTER PROCEDURE sp_obtenerDetalleCliente
  @customerid INT
AS
BEGIN
  SET NOCOUNT ON;

  -- Datos básicos del cliente con datos sensibles
  SELECT
    c.CustomerID,
    c.CustomerName,
    cat.CustomerCategoryName AS Categoria,
    bg.BuyingGroupName       AS BuyingGroup,
    c.BillToCustomerID,
    c.PaymentDays,
    
    -- Información de entrega
    c.DeliveryCityID,
    c.DeliveryMethodID,
    dm.DeliveryMethodName,
    -- DeliveryLocation desde datos sensibles (reconstruido desde Lat/Long)
    CASE 
      WHEN sens.Lat IS NOT NULL AND sens.Lng IS NOT NULL 
      THEN geography::Point(sens.Lat, sens.Lng, 4326)
      ELSE NULL 
    END AS DeliveryLocation,
    sens.Lat AS Lat,
    sens.Lng AS Lng,
    
    -- Información geográfica
    cit.CityID               AS DeliveryCityID,
    cit.CityName             AS DeliveryCityName,
    sp.StateProvinceName     AS DeliveryStateProvinceName,
    co.CountryName           AS DeliveryCountryName,

    -- Contactos
    p1.FullName AS PrimaryContactName,
    p2.FullName AS AlternateContactName,
    
    -- DATOS SENSIBLES desde Corporativo (via OPENQUERY)
    sens.WebsiteURL,
    sens.PhoneNumber,
    sens.FaxNumber,
    sens.DeliveryAddressLine1,
    sens.DeliveryAddressLine2,
    sens.DeliveryPostalCode  AS CodigoPostal

  FROM Sales.Customers c
  LEFT JOIN Sales.CustomerCategories   cat ON cat.CustomerCategoryID   = c.CustomerCategoryID
  LEFT JOIN Sales.BuyingGroups        bg  ON bg.BuyingGroupID          = c.BuyingGroupID
  LEFT JOIN Application.DeliveryMethods dm ON dm.DeliveryMethodID      = c.DeliveryMethodID
  LEFT JOIN Application.Cities        cit ON cit.CityID                = c.DeliveryCityID
  LEFT JOIN Application.StateProvinces sp  ON sp.StateProvinceID       = cit.StateProvinceID
  LEFT JOIN Application.Countries     co  ON co.CountryID              = sp.CountryID
  LEFT JOIN Application.People        p1  ON p1.PersonID               = c.PrimaryContactPersonID
  LEFT JOIN Application.People        p2  ON p2.PersonID               = c.AlternateContactPersonID
  
  -- Consulta datos sensibles usando OPENQUERY (evita problemas con tipos CLR)
  -- NOTA: Convertimos DeliveryLocation a Lat/Long en el servidor remoto
  --       para evitar problemas con tipo GEOGRAPHY (CLR)
  LEFT JOIN OPENQUERY(sql_corp, 'SELECT 
      CustomerID,
      WebsiteURL,
      PhoneNumber,
      FaxNumber,
      DeliveryAddressLine1,
      DeliveryAddressLine2,
      DeliveryPostalCode,
      DeliveryLocation.Lat AS Lat,
      DeliveryLocation.Long AS Lng
    FROM WWI_Corporativo.Sales.CustomerSensitiveData') sens
    ON sens.CustomerID = c.CustomerID
    
  WHERE c.CustomerID = @customerid;
END;
GO

PRINT '✅ Stored Procedures de Clientes creados para SAN JOSÉ';
PRINT '';
PRINT 'Procedures disponibles:';
PRINT '  • sp_obtenerClientes - Lista de clientes con filtro';
PRINT '  • sp_obtenerDetalleCliente - Detalle completo de un cliente';
PRINT '';
PRINT '✅ sp_obtenerDetalleCliente incluye TODOS los datos sensibles via OPENQUERY';
PRINT '   Linked Server: sql_corp';
PRINT '   Tabla remota: WWI_Corporativo.Sales.CustomerSensitiveData';
PRINT '   Método: OPENQUERY con conversión de GEOGRAPHY a Lat/Long';
PRINT '   DeliveryLocation se reconstruye desde coordenadas con geography::Point()';
GO
