USE WideWorldImporters;
GO

CREATE OR ALTER PROCEDURE dbo.sp_obtenerInventario
  @search NVARCHAR(100) = NULL, 
  @group  NVARCHAR(100) = NULL    
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
      si.StockItemID                   AS stockitemid,
      si.StockItemName                 AS nombreproducto,

      (
        SELECT TOP (1) sg2.StockGroupName
        FROM Warehouse.StockItemStockGroups m2
        JOIN Warehouse.StockGroups sg2 ON sg2.StockGroupID = m2.StockGroupID
        WHERE m2.StockItemID = si.StockItemID
        ORDER BY sg2.StockGroupName
      )                                 AS grupo,
      wh.QuantityOnHand                 AS cantidad
  FROM Warehouse.StockItems si
  LEFT JOIN Warehouse.StockItemHoldings wh
         ON wh.StockItemID = si.StockItemID
  WHERE
      (
        @search IS NULL
        OR si.StockItemName LIKE '%' + @search + '%'
        OR EXISTS (
             SELECT 1
             FROM Warehouse.StockItemStockGroups m
             JOIN Warehouse.StockGroups sg ON sg.StockGroupID = m.StockGroupID
             WHERE m.StockItemID = si.StockItemID
               AND sg.StockGroupName LIKE '%' + @search + '%'
           )
      )
      AND (
        @group IS NULL
        OR EXISTS (
             SELECT 1
             FROM Warehouse.StockItemStockGroups m3
             JOIN Warehouse.StockGroups sg3 ON sg3.StockGroupID = m3.StockGroupID
             WHERE m3.StockItemID = si.StockItemID
               AND sg3.StockGroupName LIKE '%' + @group + '%'
           )
      )
  ORDER BY si.StockItemName ASC;
END;
GO

USE WideWorldImporters;
GO

CREATE OR ALTER PROCEDURE sp_obtenerDetalleInventario
  @stockitemid INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
      si.StockItemID,
      si.StockItemName,
      si.Brand,
      si.Size,
      si.ColorID,
      col.ColorName,
      si.UnitPackageID,
      up.PackageTypeName  AS UnitPackage,
      si.OuterPackageID,
      op.PackageTypeName  AS OuterPackage,
      si.QuantityPerOuter,           
      si.RecommendedRetailPrice,
      si.TaxRate,
      si.TypicalWeightPerUnit,
      si.SearchDetails
  FROM Warehouse.StockItems si
  LEFT JOIN Warehouse.Colors      col ON col.ColorID       = si.ColorID
  LEFT JOIN Warehouse.PackageTypes up  ON up.PackageTypeID  = si.UnitPackageID
  LEFT JOIN Warehouse.PackageTypes op  ON op.PackageTypeID  = si.OuterPackageID
  WHERE si.StockItemID = @stockitemid;

  SELECT
      wh.QuantityOnHand,
      wh.BinLocation
  FROM Warehouse.StockItemHoldings wh
  WHERE wh.StockItemID = @stockitemid;

  SELECT TOP (1)
      s.SupplierID,
      s.SupplierName
  FROM Purchasing.PurchaseOrderLines pol
  INNER JOIN Purchasing.PurchaseOrders po ON po.PurchaseOrderID = pol.PurchaseOrderID
  INNER JOIN Purchasing.Suppliers     s  ON s.SupplierID        = po.SupplierID
  WHERE pol.StockItemID = @stockitemid
  ORDER BY po.OrderDate DESC;
END;
GO

--==================================CRUD================================================

USE WideWorldImporters;
GO

CREATE OR ALTER PROCEDURE sp_inventario_insertar
  @StockItemName NVARCHAR(100),
  @SupplierID INT,
  @UnitPackageID INT,
  @OuterPackageID INT,
  @QuantityPerOuter INT,
  @UnitPrice DECIMAL(18,2),
  @RecommendedRetailPrice DECIMAL(18,2),
  @TaxRate DECIMAL(18,3),
  @TypicalWeightPerUnit DECIMAL(18,3)
AS
BEGIN
  INSERT INTO Warehouse.StockItems
    (StockItemName, SupplierID, UnitPackageID, OuterPackageID,
     QuantityPerOuter, UnitPrice, RecommendedRetailPrice,
     TaxRate, TypicalWeightPerUnit, LastEditedBy)
  VALUES
    (@StockItemName, @SupplierID, @UnitPackageID, @OuterPackageID,
     @QuantityPerOuter, @UnitPrice, @RecommendedRetailPrice,
     @TaxRate, @TypicalWeightPerUnit, 1);
END;
GO

CREATE OR ALTER PROCEDURE sp_inventario_actualizar
  @StockItemID INT,
  @StockItemName NVARCHAR(100),
  @SupplierID INT,
  @UnitPackageID INT,
  @OuterPackageID INT,
  @QuantityPerOuter INT,
  @UnitPrice DECIMAL(18,2),
  @RecommendedRetailPrice DECIMAL(18,2),
  @TaxRate DECIMAL(18,3),
  @TypicalWeightPerUnit DECIMAL(18,3)
AS
BEGIN
  UPDATE Warehouse.StockItems
  SET
    StockItemName = @StockItemName,
    SupplierID = @SupplierID,
    UnitPackageID = @UnitPackageID,
    OuterPackageID = @OuterPackageID,
    QuantityPerOuter = @QuantityPerOuter,
    UnitPrice = @UnitPrice,
    RecommendedRetailPrice = @RecommendedRetailPrice,
    TaxRate = @TaxRate,
    TypicalWeightPerUnit = @TypicalWeightPerUnit,
    LastEditedBy = 1
  WHERE StockItemID = @StockItemID;
END;
GO

CREATE OR ALTER PROCEDURE sp_inventario_eliminar
  @StockItemID INT
AS
BEGIN
  DELETE FROM Warehouse.StockItems
  WHERE StockItemID = @StockItemID;
END;
GO


