use wideworldimporters;
go
create or alter procedure sp_obtenerClientes
  @search nvarchar(100) = null
as
begin
  set nocount on;

  select
    c.customerid,
    c.customername as nombrecliente,
    cat.customercategoryname as categoria,
    dm.deliverymethodname as metodoentrega
  from sales.customers c
  inner join sales.customercategories cat
    on cat.customercategoryid = c.customercategoryid
  left  join application.deliverymethods dm
    on dm.deliverymethodid = c.deliverymethodid
  where (@search is null or c.customername like '%' + @search + '%')
  order by c.customername asc;
end;
go

USE WideWorldImporters;
GO

CREATE OR ALTER PROCEDURE dbo.sp_obtenerDetalleCliente
  @customerid INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    c.CustomerID,
    c.CustomerName,
    cat.CustomerCategoryName AS Categoria,
    bg.BuyingGroupName       AS BuyingGroup,
    c.BillToCustomerID,
    c.WebsiteURL,
    c.PhoneNumber,
    c.FaxNumber,
    c.PaymentDays,
    c.DeliveryAddressLine1,
    c.DeliveryAddressLine2,
    c.DeliveryPostalCode AS CodigoPostal,
    c.DeliveryCityID,
    c.DeliveryMethodID,
    dm.DeliveryMethodName,
    c.DeliveryLocation,
    c.DeliveryLocation.Lat as Lat,
    c.DeliveryLocation.Long as Lng,
    cit.CityID               AS DeliveryCityID,
    cit.CityName             AS DeliveryCityName,
    sp.StateProvinceName     AS DeliveryStateProvinceName,
    co.CountryName           AS DeliveryCountryName,

    p1.FullName AS PrimaryContactName,
    p2.FullName AS AlternateContactName

  FROM Sales.Customers c
  LEFT JOIN Sales.CustomerCategories   cat ON cat.CustomerCategoryID   = c.CustomerCategoryID
  LEFT JOIN Sales.BuyingGroups        bg  ON bg.BuyingGroupID          = c.BuyingGroupID
  LEFT JOIN Application.DeliveryMethods dm ON dm.DeliveryMethodID      = c.DeliveryMethodID
  LEFT JOIN Application.Cities        cit ON cit.CityID                = c.DeliveryCityID
  LEFT JOIN Application.StateProvinces sp  ON sp.StateProvinceID       = cit.StateProvinceID
  LEFT JOIN Application.Countries     co  ON co.CountryID              = sp.CountryID
  LEFT JOIN Application.People        p1  ON p1.PersonID               = c.PrimaryContactPersonID
  LEFT JOIN Application.People        p2  ON p2.PersonID               = c.AlternateContactPersonID
  WHERE c.CustomerID = @customerid;
END;
GO




