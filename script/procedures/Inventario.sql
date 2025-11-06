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

  -- Información general del producto
  SELECT
      si.StockItemID,
      si.StockItemName,
      si.SupplierID,
      si.Brand,
      si.Size,
      si.ColorID,
      col.ColorName,
      si.UnitPackageID,
      up.PackageTypeName  AS UnitPackage,
      si.OuterPackageID,
      op.PackageTypeName  AS OuterPackage,
      si.QuantityPerOuter,
      si.UnitPrice,
      si.RecommendedRetailPrice,
      si.TaxRate,
      si.TypicalWeightPerUnit,
      si.LeadTimeDays,
      si.IsChillerStock,
      si.Barcode,
      si.SearchDetails
  FROM Warehouse.StockItems si
  LEFT JOIN Warehouse.Colors      col ON col.ColorID       = si.ColorID
  LEFT JOIN Warehouse.PackageTypes up  ON up.PackageTypeID  = si.UnitPackageID
  LEFT JOIN Warehouse.PackageTypes op  ON op.PackageTypeID  = si.OuterPackageID
  WHERE si.StockItemID = @stockitemid;

  -- Holdings (inventario)
  SELECT
      wh.QuantityOnHand,
      wh.BinLocation
  FROM Warehouse.StockItemHoldings wh
  WHERE wh.StockItemID = @stockitemid;

  -- Proveedor (desde la tabla StockItems directamente)
  SELECT
      s.SupplierID,
      s.SupplierName
  FROM Warehouse.StockItems si
  INNER JOIN Purchasing.Suppliers s ON s.SupplierID = si.SupplierID
  WHERE si.StockItemID = @stockitemid;
END;
GO

-- ============================================================
-- PROCEDURES AUXILIARES PARA OBTENER DATOS DE REFERENCIA
-- ============================================================

-- Procedure para obtener lista de proveedores (para dropdown/select)
CREATE OR ALTER PROCEDURE SP_GetSuppliersForProducts
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        SupplierID,
        SupplierName
    FROM Purchasing.Suppliers
    ORDER BY SupplierName ASC;
END
GO

-- Procedure para obtener lista de colores disponibles
CREATE OR ALTER PROCEDURE SP_GetColorsForProducts
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ColorID,
        ColorName
    FROM Warehouse.Colors
    ORDER BY ColorName ASC;
END
GO

-- Procedure para obtener tipos de empaquetamiento
CREATE OR ALTER PROCEDURE SP_GetPackageTypesForProducts
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        PackageTypeID,
        PackageTypeName
    FROM Warehouse.PackageTypes
    ORDER BY PackageTypeName ASC;
END
GO

-- Procedure para obtener grupos de productos (stock groups)
CREATE OR ALTER PROCEDURE SP_GetStockGroupsForProducts
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        StockGroupID,
        StockGroupName
    FROM Warehouse.StockGroups
    ORDER BY StockGroupName ASC;
END
GO

CREATE OR ALTER PROCEDURE SP_GetProductStockGroups
    @StockItemID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sg.StockGroupID,
        sg.StockGroupName
    FROM Warehouse.StockItemStockGroups sisg
        INNER JOIN Warehouse.StockGroups sg ON sisg.StockGroupID = sg.StockGroupID
    WHERE sisg.StockItemID = @StockItemID
    ORDER BY sg.StockGroupName;
END
GO

-- ============================================================
-- PROCEDURES PARA INSERCIÓN DE PRODUCTOS
-- ============================================================

-- Procedure para insertar un nuevo producto
CREATE OR ALTER PROCEDURE SP_InsertProduct
    @NombreProducto NVARCHAR(255),
    @SupplierID INT,
    @ColorID INT = NULL,
    @UnitPackageID INT,
    @OuterPackageID INT,
    @CantidadEmpaquetamiento INT,
    @Marca NVARCHAR(100) = NULL,
    @Talla NVARCHAR(50) = NULL,
    @Impuesto DECIMAL(5,2),
    @PrecioUnitario DECIMAL(18,2),
    @PrecioVenta DECIMAL(18,2),
    @Peso DECIMAL(10,2) = NULL,
    @PalabrasClave NVARCHAR(4000) = NULL,
    @CantidadDisponible INT,
    @Ubicacion NVARCHAR(100) = NULL,
    @TiempoEntrega INT = 0,
    @RequiereFrio BIT = 0,
    @CodigoBarras NVARCHAR(100) = NULL,
    @CamposPersonalizados NVARCHAR(MAX) = NULL,
    @Etiquetas NVARCHAR(MAX) = NULL,
    @StockGroupIDs NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewStockItemID TABLE (ID INT);

    INSERT INTO Warehouse.StockItems
    (
        StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID,
        Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock,
        Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit,
        MarketingComments, InternalComments, Photo, CustomFields, LastEditedBy
    )
    OUTPUT INSERTED.StockItemID INTO @NewStockItemID
    VALUES
    (
        @NombreProducto, @SupplierID, @ColorID, @UnitPackageID, @OuterPackageID,
        @Marca, @Talla, @TiempoEntrega, @CantidadEmpaquetamiento, @RequiereFrio,
        @CodigoBarras, @Impuesto, @PrecioUnitario, @PrecioVenta, @Peso,
        NULL, NULL, NULL, @CamposPersonalizados, 1
    );

    DECLARE @ID INT = (SELECT ID FROM @NewStockItemID);

    IF @ID IS NULL OR @ID = 0
    BEGIN
        RAISERROR('Error: No se pudo obtener el ID del nuevo producto', 16, 1);
        RETURN;
    END;

    INSERT INTO Warehouse.StockItemHoldings
    (
        StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
        LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen
    )
    VALUES
    (
        @ID, @CantidadDisponible, @Ubicacion, @CantidadDisponible,
        @PrecioUnitario, 0, @CantidadDisponible, 1, SYSDATETIME()
    );

    IF @CantidadDisponible > 0
    BEGIN
        INSERT INTO Warehouse.StockItemTransactions
        (
            StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID,
            PurchaseOrderID, TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen
        )
        VALUES
        (
            @ID, 10, NULL, NULL, @SupplierID, NULL, SYSDATETIME(),
            @CantidadDisponible, 1, SYSDATETIME()
        );
    END

    IF @StockGroupIDs IS NOT NULL AND @StockGroupIDs != ''
    BEGIN
        DECLARE @GroupID INT;
        DECLARE @Pos INT = 1;
        DECLARE @NextPos INT;
        
        WHILE @Pos <= LEN(@StockGroupIDs)
        BEGIN
            SET @NextPos = CHARINDEX(',', @StockGroupIDs, @Pos);
            IF @NextPos = 0
                SET @NextPos = LEN(@StockGroupIDs) + 1;
            
            SET @GroupID = CAST(SUBSTRING(@StockGroupIDs, @Pos, @NextPos - @Pos) AS INT);
            
            INSERT INTO Warehouse.StockItemStockGroups
            (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen)
            VALUES (@ID, @GroupID, 1, SYSDATETIME());
            
            SET @Pos = @NextPos + 1;
        END
    END

    SELECT @ID AS NewStockItemID;
END
GO

-- ============================================================
-- PROCEDURES PARA MODIFICACIÓN DE PRODUCTOS
-- ============================================================

-- Procedure para actualizar un producto existente
CREATE OR ALTER PROCEDURE SP_UpdateProduct
    @StockItemID INT,
    @NombreProducto NVARCHAR(255),
    @SupplierID INT,
    @ColorID INT = NULL,
    @UnitPackageID INT,
    @OuterPackageID INT,
    @CantidadEmpaquetamiento INT,
    @Marca NVARCHAR(100) = NULL,
    @Talla NVARCHAR(50) = NULL,
    @Impuesto DECIMAL(5,2),
    @PrecioUnitario DECIMAL(18,2),
    @PrecioVenta DECIMAL(18,2),
    @Peso DECIMAL(10,2) = NULL,
    @PalabrasClave NVARCHAR(4000) = NULL,
    @CantidadDisponible INT = NULL,
    @Ubicacion NVARCHAR(100) = NULL,
    @TiempoEntrega INT = 0,
    @RequiereFrio BIT = 0,
    @CodigoBarras NVARCHAR(100) = NULL,
    @CamposPersonalizados NVARCHAR(MAX) = NULL,
    @Etiquetas NVARCHAR(MAX) = NULL,
    @StockGroupIDs NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Warehouse.StockItems
    SET 
        StockItemName = @NombreProducto,
        SupplierID = @SupplierID,
        ColorID = @ColorID,
        UnitPackageID = @UnitPackageID,
        OuterPackageID = @OuterPackageID,
        Brand = @Marca,
        Size = @Talla,
        LeadTimeDays = @TiempoEntrega,
        QuantityPerOuter = @CantidadEmpaquetamiento,
        IsChillerStock = @RequiereFrio,
        Barcode = @CodigoBarras,
        TaxRate = @Impuesto,
        UnitPrice = @PrecioUnitario,
        RecommendedRetailPrice = @PrecioVenta,
        TypicalWeightPerUnit = @Peso,
        CustomFields = @CamposPersonalizados,
        LastEditedBy = 1
    WHERE StockItemID = @StockItemID;

    IF @CantidadDisponible IS NOT NULL
    BEGIN
        DECLARE @CantidadActual INT;
        SELECT @CantidadActual = QuantityOnHand 
        FROM Warehouse.StockItemHoldings 
        WHERE StockItemID = @StockItemID;
        
        DECLARE @Diferencia INT = @CantidadDisponible - ISNULL(@CantidadActual, 0);
        
        UPDATE Warehouse.StockItemHoldings
        SET 
            QuantityOnHand = @CantidadDisponible,
            BinLocation = @Ubicacion,
            LastEditedBy = 1,
            LastEditedWhen = SYSDATETIME()
        WHERE StockItemID = @StockItemID;
        
        IF @Diferencia != 0
        BEGIN
            INSERT INTO Warehouse.StockItemTransactions
            (
                StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID,
                PurchaseOrderID, TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen
            )
            VALUES
            (
                @StockItemID, 
                CASE WHEN @Diferencia > 0 THEN 10 ELSE 11 END,
                NULL, NULL, @SupplierID, NULL, SYSDATETIME(),
                @Diferencia, 1, SYSDATETIME()
            );
        END
    END
    ELSE
    BEGIN
        UPDATE Warehouse.StockItemHoldings
        SET 
            BinLocation = @Ubicacion,
            LastEditedBy = 1,
            LastEditedWhen = SYSDATETIME()
        WHERE StockItemID = @StockItemID;
    END

    IF @StockGroupIDs IS NOT NULL
    BEGIN
        DELETE FROM Warehouse.StockItemStockGroups 
        WHERE StockItemID = @StockItemID;
        
        IF @StockGroupIDs != ''
        BEGIN
            DECLARE @GroupID INT;
            DECLARE @Pos INT = 1;
            DECLARE @NextPos INT;
            
            WHILE @Pos <= LEN(@StockGroupIDs)
            BEGIN
                SET @NextPos = CHARINDEX(',', @StockGroupIDs, @Pos);
                IF @NextPos = 0
                    SET @NextPos = LEN(@StockGroupIDs) + 1;
                
                SET @GroupID = CAST(SUBSTRING(@StockGroupIDs, @Pos, @NextPos - @Pos) AS INT);
                
                INSERT INTO Warehouse.StockItemStockGroups
                (StockItemID, StockGroupID, LastEditedBy, LastEditedWhen)
                VALUES (@StockItemID, @GroupID, 1, SYSDATETIME());
                
                SET @Pos = @NextPos + 1;
            END
        END
    END
    
    SELECT @StockItemID AS UpdatedStockItemID;
END
GO

-- ============================================================
-- PROCEDURES PARA ELIMINACIÓN DE PRODUCTOS
-- ============================================================

-- Procedure para eliminar (desactivar) un producto
CREATE OR ALTER PROCEDURE SP_DeleteProduct
    @StockItemID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DELETE FROM Warehouse.StockItemStockGroups 
    WHERE StockItemID = @StockItemID;
    
    DECLARE @CantidadActual INT;
    SELECT @CantidadActual = QuantityOnHand 
    FROM Warehouse.StockItemHoldings 
    WHERE StockItemID = @StockItemID;
    
    IF @CantidadActual > 0
    BEGIN
        INSERT INTO Warehouse.StockItemTransactions
        (
            StockItemID, TransactionTypeID, TransactionOccurredWhen,
            Quantity, LastEditedBy, LastEditedWhen
        )
        VALUES
        (
            @StockItemID, 11, SYSDATETIME(),
            -@CantidadActual, 1, SYSDATETIME()
        );
    END

    DELETE FROM Warehouse.StockItemHoldings
    WHERE StockItemID = @StockItemID;
    
    DELETE FROM Warehouse.StockItemTransactions
    WHERE StockItemID = @StockItemID;

    DELETE FROM Warehouse.StockItems
    WHERE StockItemID = @StockItemID;
    
    SELECT @StockItemID AS DeletedStockItemID;
END
GO

-- ============================================================
-- PROCEDURES AUXILIARES PARA VALIDACIONES
-- ============================================================

-- Procedure para verificar si existe un producto
CREATE OR ALTER PROCEDURE SP_CheckProductExists
    @StockItemID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CASE 
            WHEN EXISTS (SELECT 1 FROM Warehouse.StockItems WHERE StockItemID = @StockItemID) 
            THEN 1 
            ELSE 0 
        END AS ProductExists;
END
GO

-- Procedure para verificar transacciones críticas que impedirían eliminar un producto
CREATE OR ALTER PROCEDURE SP_CheckProductCriticalTransactions
    @StockItemID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @InvoiceCount INT = 0;
    DECLARE @PurchaseOrderCount INT = 0;
    
    -- Contar facturas (ventas)
    SELECT @InvoiceCount = COUNT(*)
    FROM Sales.InvoiceLines 
    WHERE StockItemID = @StockItemID;
    
    -- Contar órdenes de compra
    SELECT @PurchaseOrderCount = COUNT(*)
    FROM Purchasing.PurchaseOrderLines 
    WHERE StockItemID = @StockItemID;
    
    -- Retornar resultado
    SELECT 
        @InvoiceCount AS InvoiceCount,
        @PurchaseOrderCount AS PurchaseOrderCount,
        CASE 
            WHEN (@InvoiceCount > 0 OR @PurchaseOrderCount > 0) 
            THEN 1 
            ELSE 0 
        END AS HasCriticalTransactions;
END
GO


