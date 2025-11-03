use wideworldimporters;
go

create or alter procedure sp_obtenerProveedores
  @search   nvarchar(100) = null,  
  @category nvarchar(100) = null   
as
begin
  set nocount on;

  select
    s.supplierid,
    s.suppliername as nombreproveedor,
    sc.suppliercategoryname as categoria,
    dm.deliverymethodname    as metodoentrega
  from purchasing.suppliers s
  inner join purchasing.suppliercategories sc
    on sc.suppliercategoryid = s.suppliercategoryid
  left  join application.deliverymethods dm
    on dm.deliverymethodid = s.deliverymethodid
  where (@search   is null or s.suppliername          like '%' + @search   + '%')
    and (@category is null or sc.suppliercategoryname like '%' + @category + '%')
  order by s.suppliername asc;
end;
go

USE WideWorldImporters;
GO

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
