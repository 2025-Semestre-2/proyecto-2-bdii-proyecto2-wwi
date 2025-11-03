USE WideWorldImporters;
GO
CREATE OR ALTER PROCEDURE sp_obtenerVentas
  @client NVARCHAR(100) = NULL,
  @from   DATE = NULL,
  @to     DATE = NULL,
  @minamt DECIMAL(18,2) = NULL,
  @maxamt DECIMAL(18,2) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH tot AS (
    SELECT
      i.InvoiceID,
      i.InvoiceDate,
      c.CustomerName,
      dm.DeliveryMethodName,
      SUM(il.ExtendedPrice) AS Monto
    FROM Sales.Invoices i
    INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
    LEFT  JOIN Application.DeliveryMethods dm ON dm.DeliveryMethodID = i.DeliveryMethodID
    INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
    WHERE (@client IS NULL OR c.CustomerName LIKE '%' + @client + '%')
      AND (@from   IS NULL OR i.InvoiceDate >= @from)
      AND (@to     IS NULL OR i.InvoiceDate < DATEADD(DAY,1,@to))
    GROUP BY i.InvoiceID, i.InvoiceDate, c.CustomerName, dm.DeliveryMethodName
  )
  SELECT *
  FROM tot
  WHERE (@minamt IS NULL OR Monto >= @minamt)
    AND (@maxamt IS NULL OR Monto <= @maxamt)
  ORDER BY CustomerName ASC, InvoiceDate DESC;
END;
GO

USE WideWorldImporters;
GO
CREATE OR ALTER PROCEDURE sp_obtenerDetalleVentas
  @invoiceid INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    i.InvoiceID,
    i.InvoiceDate,
    i.CustomerID,                              
    c.CustomerName,                            
    dm.DeliveryMethodName,                     
    i.CustomerPurchaseOrderNumber,            
    i.ContactPersonID,
    cp.FullName    AS ContactPersonName,       
    i.SalespersonPersonID,
    sp.FullName    AS SalespersonName,        
    i.DeliveryInstructions                     
  FROM Sales.Invoices i
  INNER JOIN Sales.Customers c           ON c.CustomerID = i.CustomerID
  LEFT  JOIN Application.DeliveryMethods dm ON dm.DeliveryMethodID = i.DeliveryMethodID
  LEFT  JOIN Application.People cp       ON cp.PersonID = i.ContactPersonID
  LEFT  JOIN Application.People sp       ON sp.PersonID = i.SalespersonPersonID
  WHERE i.InvoiceID = @invoiceid;

  SELECT
    il.InvoiceLineID,
    si.StockItemID,
    si.StockItemName,                          
    il.Quantity,
    il.UnitPrice,
    il.TaxRate,                             
    il.TaxAmount,                             
    il.ExtendedPrice,                        
    (il.ExtendedPrice + il.TaxAmount) AS TotalPorLinea
  FROM Sales.InvoiceLines il
  INNER JOIN Warehouse.StockItems si ON si.StockItemID = il.StockItemID
  WHERE il.InvoiceID = @invoiceid
  ORDER BY il.InvoiceLineID;
END;
GO
