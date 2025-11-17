-- ============================================================
-- STORED PROCEDURES DE ESTADÍSTICAS - CORPORATIVO
-- CON VISTAS MATERIALIZADAS
-- ============================================================
-- Base de datos: WWI_Corporativo
-- Consolida datos de las sucursales San José y Limón
-- ============================================================

USE WWI_Corporativo;
GO

-- ============================================================
-- PASO 1: CREAR TABLAS MATERIALIZADAS
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Corporate')
    EXEC('CREATE SCHEMA Corporate');
GO

-- Tabla materializada: Compras por proveedor y categoría
CREATE TABLE Corporate.CompraProveedorCategoria_Mat (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    SupplierCategoryName NVARCHAR(100) NOT NULL,
    PurchaseOrderID INT NOT NULL,
    OrderAmount DECIMAL(18,2) NOT NULL,
    Sucursal NVARCHAR(50) NOT NULL,
    LastUpdated DATETIME2 DEFAULT SYSDATETIME(),
    INDEX IDX_Supplier (SupplierName),
    INDEX IDX_Category (SupplierCategoryName),
    INDEX IDX_Sucursal (Sucursal)
);
GO

-- Tabla materializada: Ventas por cliente y categoría
CREATE TABLE Corporate.VentaClienteCategoria_Mat (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    StockGroupName NVARCHAR(100),
    InvoiceID INT NOT NULL,
    InvoiceAmountByCategory DECIMAL(18,2) NOT NULL,
    Sucursal NVARCHAR(50) NOT NULL,
    LastUpdated DATETIME2 DEFAULT SYSDATETIME(),
    INDEX IDX_Customer (CustomerName),
    INDEX IDX_Category (StockGroupName),
    INDEX IDX_Sucursal (Sucursal)
);
GO

-- Tabla materializada: Productos con ganancia anual
CREATE TABLE Corporate.ProductosGananciaAnual_Mat (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Year INT NOT NULL,
    StockItemID INT NOT NULL,
    SalesAmount DECIMAL(18,2) NOT NULL,
    CostAmount DECIMAL(18,2) NOT NULL,
    ProfitAmount DECIMAL(18,2) NOT NULL,
    Sucursal NVARCHAR(50) NOT NULL,
    LastUpdated DATETIME2 DEFAULT SYSDATETIME(),
    INDEX IDX_Year_Item (Year, StockItemID),
    INDEX IDX_Sucursal (Sucursal)
);
GO

-- Tabla materializada: Top clientes anual
CREATE TABLE Corporate.TopClientesAnual_Mat (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Year INT NOT NULL,
    CustomerID INT NOT NULL,
    InvoiceCount INT NOT NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    Sucursal NVARCHAR(50) NOT NULL,
    LastUpdated DATETIME2 DEFAULT SYSDATETIME(),
    INDEX IDX_Year_Customer (Year, CustomerID),
    INDEX IDX_Sucursal (Sucursal)
);
GO

-- Tabla materializada: Top proveedores anual
CREATE TABLE Corporate.TopProveedoresAnual_Mat (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Year INT NOT NULL,
    SupplierID INT NOT NULL,
    OrderCount INT NOT NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    Sucursal NVARCHAR(50) NOT NULL,
    LastUpdated DATETIME2 DEFAULT SYSDATETIME(),
    INDEX IDX_Year_Supplier (Year, SupplierID),
    INDEX IDX_Sucursal (Sucursal)
);
GO

-- ============================================================
-- PASO 2: PROCEDURES PARA REFRESCAR TABLAS MATERIALIZADAS
-- ============================================================

-- Procedure: Refrescar CompraProveedorCategoria_Mat
CREATE OR ALTER PROCEDURE Corporate.SP_RefreshComprasMaterializada
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        TRUNCATE TABLE Corporate.CompraProveedorCategoria_Mat;
        
        INSERT INTO Corporate.CompraProveedorCategoria_Mat (
            SupplierName, SupplierCategoryName, PurchaseOrderID, 
            OrderAmount, Sucursal, LastUpdated
        )
        -- San José
        SELECT
            s.SupplierName,
            sc.SupplierCategoryName,
            po.PurchaseOrderID,
            SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS OrderAmount,
            'San José' AS Sucursal,
            SYSDATETIME()
        FROM Purchasing.PurchaseOrders_SJ AS po
        JOIN Purchasing.Suppliers AS s ON s.SupplierID = po.SupplierID
        JOIN Purchasing.SupplierCategories AS sc ON sc.SupplierCategoryID = s.SupplierCategoryID
        JOIN Purchasing.PurchaseOrderLines_SJ AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
        GROUP BY s.SupplierName, sc.SupplierCategoryName, po.PurchaseOrderID

        UNION ALL

        -- Limón
        SELECT
            s.SupplierName,
            sc.SupplierCategoryName,
            po.PurchaseOrderID,
            SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS OrderAmount,
            'Limón' AS Sucursal,
            SYSDATETIME()
        FROM Purchasing.PurchaseOrders_Limon AS po
        JOIN Purchasing.Suppliers AS s ON s.SupplierID = po.SupplierID
        JOIN Purchasing.SupplierCategories AS sc ON sc.SupplierCategoryID = s.SupplierCategoryID
        JOIN Purchasing.PurchaseOrderLines_Limon AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
        GROUP BY s.SupplierName, sc.SupplierCategoryName, po.PurchaseOrderID;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedure: Refrescar VentaClienteCategoria_Mat
CREATE OR ALTER PROCEDURE Corporate.SP_RefreshVentasMaterializada
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        TRUNCATE TABLE Corporate.VentaClienteCategoria_Mat;
        
        INSERT INTO Corporate.VentaClienteCategoria_Mat (
            CustomerName, StockGroupName, InvoiceID, 
            InvoiceAmountByCategory, Sucursal, LastUpdated
        )
        -- San José
        SELECT
            c.CustomerName,
            sg.StockGroupName,
            i.InvoiceID,
            SUM(il.ExtendedPrice) AS InvoiceAmountByCategory,
            'San José' AS Sucursal,
            SYSDATETIME()
        FROM Sales.Invoices_SJ AS i
        JOIN Sales.Customers AS c ON c.CustomerID = i.CustomerID
        JOIN Sales.InvoiceLines_SJ AS il ON il.InvoiceID = i.InvoiceID
        LEFT JOIN Warehouse.StockItemStockGroups AS sgs ON sgs.StockItemID = il.StockItemID
        LEFT JOIN Warehouse.StockGroups AS sg ON sg.StockGroupID = sgs.StockGroupID
        GROUP BY c.CustomerName, sg.StockGroupName, i.InvoiceID

        UNION ALL

        -- Limón
        SELECT
            c.CustomerName,
            sg.StockGroupName,
            i.InvoiceID,
            SUM(il.ExtendedPrice) AS InvoiceAmountByCategory,
            'Limón' AS Sucursal,
            SYSDATETIME()
        FROM Sales.Invoices_Limon AS i
        JOIN Sales.Customers AS c ON c.CustomerID = i.CustomerID
        JOIN Sales.InvoiceLines_Limon AS il ON il.InvoiceID = i.InvoiceID
        LEFT JOIN Warehouse.StockItemStockGroups AS sgs ON sgs.StockItemID = il.StockItemID
        LEFT JOIN Warehouse.StockGroups AS sg ON sg.StockGroupID = sgs.StockGroupID
        GROUP BY c.CustomerName, sg.StockGroupName, i.InvoiceID;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedure: Refrescar ProductosGananciaAnual_Mat
CREATE OR ALTER PROCEDURE Corporate.SP_RefreshGananciasMaterializada
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        TRUNCATE TABLE Corporate.ProductosGananciaAnual_Mat;
        
        INSERT INTO Corporate.ProductosGananciaAnual_Mat (
            Year, StockItemID, SalesAmount, CostAmount, 
            ProfitAmount, Sucursal, LastUpdated
        )
        -- San José
        SELECT
            YEAR(i.InvoiceDate) AS Year,
            il.StockItemID,
            SUM(il.ExtendedPrice) AS SalesAmount,
            SUM(ISNULL(sih.LastCostPrice,0.0) * il.Quantity) AS CostAmount,
            SUM(il.ExtendedPrice - ISNULL(sih.LastCostPrice,0.0) * il.Quantity) AS ProfitAmount,
            'San José' AS Sucursal,
            SYSDATETIME()
        FROM Sales.InvoiceLines_SJ AS il
        JOIN Sales.Invoices_SJ AS i ON i.InvoiceID = il.InvoiceID
        LEFT JOIN Warehouse.StockItemHoldings_SJ AS sih ON sih.StockItemID = il.StockItemID
        GROUP BY YEAR(i.InvoiceDate), il.StockItemID

        UNION ALL

        -- Limón
        SELECT
            YEAR(i.InvoiceDate) AS Year,
            il.StockItemID,
            SUM(il.ExtendedPrice) AS SalesAmount,
            SUM(ISNULL(sih.LastCostPrice,0.0) * il.Quantity) AS CostAmount,
            SUM(il.ExtendedPrice - ISNULL(sih.LastCostPrice,0.0) * il.Quantity) AS ProfitAmount,
            'Limón' AS Sucursal,
            SYSDATETIME()
        FROM Sales.InvoiceLines_Limon AS il
        JOIN Sales.Invoices_Limon AS i ON i.InvoiceID = il.InvoiceID
        LEFT JOIN Warehouse.StockItemHoldings_Limon AS sih ON sih.StockItemID = il.StockItemID
        GROUP BY YEAR(i.InvoiceDate), il.StockItemID;
        
        COMMIT TRANSACTION;

        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedure: Refrescar TopClientesAnual_Mat
CREATE OR ALTER PROCEDURE Corporate.SP_RefreshClientesMaterializada
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        TRUNCATE TABLE Corporate.TopClientesAnual_Mat;
        
        INSERT INTO Corporate.TopClientesAnual_Mat (
            Year, CustomerID, InvoiceCount, TotalAmount, 
            Sucursal, LastUpdated
        )
        -- San José
        SELECT
            YEAR(i.InvoiceDate) AS Year,
            i.CustomerID,
            COUNT(*) AS InvoiceCount,
            SUM(il.ExtendedPrice) AS TotalAmount,
            'San José' AS Sucursal,
            SYSDATETIME()
        FROM Sales.Invoices_SJ AS i
        JOIN Sales.InvoiceLines_SJ AS il ON il.InvoiceID = i.InvoiceID
        GROUP BY YEAR(i.InvoiceDate), i.CustomerID

        UNION ALL

        -- Limón
        SELECT
            YEAR(i.InvoiceDate) AS Year,
            i.CustomerID,
            COUNT(*) AS InvoiceCount,
            SUM(il.ExtendedPrice) AS TotalAmount,
            'Limón' AS Sucursal,
            SYSDATETIME()
        FROM Sales.Invoices_Limon AS i
        JOIN Sales.InvoiceLines_Limon AS il ON il.InvoiceID = i.InvoiceID
        GROUP BY YEAR(i.InvoiceDate), i.CustomerID;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedure: Refrescar TopProveedoresAnual_Mat
CREATE OR ALTER PROCEDURE Corporate.SP_RefreshProveedoresMaterializada
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        TRUNCATE TABLE Corporate.TopProveedoresAnual_Mat;
        
        INSERT INTO Corporate.TopProveedoresAnual_Mat (
            Year, SupplierID, OrderCount, TotalAmount, 
            Sucursal, LastUpdated
        )
        -- San José
        SELECT
            YEAR(po.OrderDate) AS Year,
            po.SupplierID,
            COUNT(DISTINCT po.PurchaseOrderID) AS OrderCount,
            SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS TotalAmount,
            'San José' AS Sucursal,
            SYSDATETIME()
        FROM Purchasing.PurchaseOrders_SJ AS po
        JOIN Purchasing.PurchaseOrderLines_SJ AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
        GROUP BY YEAR(po.OrderDate), po.SupplierID

        UNION ALL

        -- Limón
        SELECT
            YEAR(po.OrderDate) AS Year,
            po.SupplierID,
            COUNT(DISTINCT po.PurchaseOrderID) AS OrderCount,
            SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS TotalAmount,
            'Limón' AS Sucursal,
            SYSDATETIME()
        FROM Purchasing.PurchaseOrders_Limon AS po
        JOIN Purchasing.PurchaseOrderLines_Limon AS pol ON pol.PurchaseOrderID = po.PurchaseOrderID
        GROUP BY YEAR(po.OrderDate), po.SupplierID;
        
        COMMIT TRANSACTION;
      
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- ============================================================
-- PASO 3: VISTAS SOBRE LAS TABLAS MATERIALIZADAS
-- ============================================================

-- Vista: Compras por proveedor y categoría (consolidada)
CREATE OR ALTER VIEW dbo.vw_CompraProveedorCategoria
AS
SELECT
    SupplierName,
    SupplierCategoryName,
    PurchaseOrderID,
    OrderAmount,
    Sucursal,
    LastUpdated
FROM Corporate.CompraProveedorCategoria_Mat;
GO

-- Vista: Ventas por cliente y categoría (consolidada)
CREATE OR ALTER VIEW dbo.vw_VentaClienteCategoria
AS
SELECT
    CustomerName,
    StockGroupName,
    InvoiceID,
    InvoiceAmountByCategory,
    Sucursal,
    LastUpdated
FROM Corporate.VentaClienteCategoria_Mat;
GO

-- Vista: Productos con ganancia anual (consolidada)
CREATE OR ALTER VIEW dbo.vw_ProductosGananciaAnual
AS
SELECT
    Year,
    StockItemID,
    SalesAmount,
    CostAmount,
    ProfitAmount,
    Sucursal,
    LastUpdated
FROM Corporate.ProductosGananciaAnual_Mat;
GO

-- Vista: Top clientes anual (consolidada)
CREATE OR ALTER VIEW dbo.vw_TopClientesAnual
AS
SELECT
    Year,
    CustomerID,
    InvoiceCount,
    TotalAmount,
    Sucursal,
    LastUpdated
FROM Corporate.TopClientesAnual_Mat;
GO

-- Vista: Top proveedores anual (consolidada)
CREATE OR ALTER VIEW dbo.vw_TopProveedoresAnual
AS
SELECT
    Year,
    SupplierID,
    OrderCount,
    TotalAmount,
    Sucursal,
    LastUpdated
FROM Corporate.TopProveedoresAnual_Mat;
GO

-- ============================================================
-- PASO 4: STORED PROCEDURES ACTUALIZADOS
-- ============================================================

-- SP: Estadísticas de compras por proveedor y categoría
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasCompras
    @supplier NVARCHAR(100) = NULL,
    @category NVARCHAR(100) = NULL,
    @sucursal NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Refrescar si se solicita
    
    EXEC Corporate.SP_RefreshComprasMaterializada;
   

    IF @sucursal = 'Consolidado' OR @sucursal IS NULL
    BEGIN
        -- Consolidado
        SELECT
            SupplierName,
            SupplierCategoryName,
            Sucursal,
            COUNT(*) AS total_ordenes,
            MIN(OrderAmount) AS monto_minimo,
            MAX(OrderAmount) AS monto_maximo,
            AVG(OrderAmount) AS monto_promedio,
            SUM(OrderAmount) AS monto_total,
            MAX(LastUpdated) AS ultima_actualizacion
        FROM dbo.vw_CompraProveedorCategoria
        WHERE (@supplier IS NULL OR SupplierName LIKE '%' + @supplier + '%')
          AND (@category IS NULL OR SupplierCategoryName LIKE '%' + @category + '%')
        GROUP BY ROLLUP (SupplierName, SupplierCategoryName, Sucursal)
        ORDER BY monto_total DESC;
    END
    ELSE
    BEGIN
        -- Por sucursal
        SELECT
            SupplierName,
            SupplierCategoryName,
            Sucursal,
            MIN(OrderAmount) AS monto_minimo,
            MAX(OrderAmount) AS monto_maximo,
            AVG(OrderAmount) AS monto_promedio,
            SUM(OrderAmount) AS monto_total,
            MAX(LastUpdated) AS ultima_actualizacion
        FROM dbo.vw_CompraProveedorCategoria
        WHERE (@supplier IS NULL OR SupplierName LIKE '%' + @supplier + '%')
          AND (@category IS NULL OR SupplierCategoryName LIKE '%' + @category + '%')
          AND Sucursal = @sucursal
        GROUP BY ROLLUP (SupplierName, SupplierCategoryName, Sucursal)
        ORDER BY SupplierName, SupplierCategoryName, Sucursal;
    END
END;
GO

-- SP: Estadísticas de ventas por cliente y categoría
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasVentas
    @customer NVARCHAR(100) = NULL,
    @category NVARCHAR(100) = NULL,
    @sucursal NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    
    EXEC Corporate.SP_RefreshVentasMaterializada;

    IF @sucursal = 'Consolidado' OR @sucursal IS NULL
    BEGIN
        SELECT
            CustomerName,
            StockGroupName,
            Sucursal,
            COUNT(*) AS total_facturas,
            MIN(InvoiceAmountByCategory) AS monto_minimo,
            MAX(InvoiceAmountByCategory) AS monto_maximo,
            AVG(InvoiceAmountByCategory) AS monto_promedio,
            SUM(InvoiceAmountByCategory) AS monto_total,
            MAX(LastUpdated) AS ultima_actualizacion
        FROM dbo.vw_VentaClienteCategoria
        WHERE (@customer IS NULL OR CustomerName LIKE '%' + @customer + '%')
          AND (@category IS NULL OR StockGroupName LIKE '%' + @category + '%')
        GROUP BY ROLLUP (CustomerName, StockGroupName, Sucursal)
        ORDER BY CustomerName, StockGroupName, Sucursal;
    END
    ELSE
    BEGIN
        SELECT
            CustomerName,
            StockGroupName,
            Sucursal,
            MIN(InvoiceAmountByCategory) AS monto_minimo,
            MAX(InvoiceAmountByCategory) AS monto_maximo,
            AVG(InvoiceAmountByCategory) AS monto_promedio,
            SUM(InvoiceAmountByCategory) AS monto_total,
            MAX(LastUpdated) AS ultima_actualizacion
        FROM dbo.vw_VentaClienteCategoria
        WHERE (@customer IS NULL OR CustomerName LIKE '%' + @customer + '%')
          AND (@category IS NULL OR StockGroupName LIKE '%' + @category + '%')
          AND Sucursal = @sucursal
        GROUP BY ROLLUP (CustomerName, StockGroupName, Sucursal)
        ORDER BY CustomerName, StockGroupName, Sucursal;
    END
END;
GO

-- SP: Estadísticas de ganancias por producto y año
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasGananciasProductosAnio
    @year INT = NULL,
    @sucursal NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    
    EXEC Corporate.SP_RefreshGananciasMaterializada;

    IF @sucursal IS NULL OR @sucursal = 'Consolidado'
    BEGIN
        -- Consolidado: agrupa por año y producto sumando ambas sucursales
        WITH consolidated AS (
            SELECT
                v.Year,
                v.StockItemID,
                SUM(v.SalesAmount) AS SalesAmount,
                SUM(v.CostAmount) AS CostAmount,
                SUM(v.ProfitAmount) AS ProfitAmount
            FROM dbo.vw_ProductosGananciaAnual v
            WHERE (@year IS NULL OR v.Year = @year)
            GROUP BY v.Year, v.StockItemID
        ),
        ranked AS (
            SELECT
                Year,
                StockItemID,
                SalesAmount,
                CostAmount,
                ProfitAmount,
                DENSE_RANK() OVER (PARTITION BY Year ORDER BY ProfitAmount DESC) AS rnk
            FROM consolidated
        )
        SELECT 
            r.Year, 
            si.StockItemName, 
            r.SalesAmount, 
            r.CostAmount, 
            r.ProfitAmount, 
            r.rnk,
            'Consolidado' AS Sucursal
        FROM ranked r
        JOIN Warehouse.StockItems si ON si.StockItemID = r.StockItemID
        WHERE r.rnk <= 5
        ORDER BY r.Year, r.rnk;
    END
    ELSE
    BEGIN
        -- Por sucursal específica
        WITH r AS (
            SELECT
                v.Year,
                v.StockItemID,
                v.SalesAmount,
                v.CostAmount,
                v.ProfitAmount,
                v.Sucursal,
                DENSE_RANK() OVER (PARTITION BY v.Year, v.Sucursal ORDER BY v.ProfitAmount DESC) AS rnk
            FROM dbo.vw_ProductosGananciaAnual v
            WHERE (@year IS NULL OR v.Year = @year)
              AND v.Sucursal = @sucursal
        )
        SELECT 
            r.Year, 
            si.StockItemName, 
            r.SalesAmount, 
            r.CostAmount, 
            r.ProfitAmount, 
            r.rnk,
            r.Sucursal
        FROM r
        JOIN Warehouse.StockItems si ON si.StockItemID = r.StockItemID
        WHERE r.rnk <= 5
        ORDER BY r.Year, r.rnk;
    END
END;
GO

-- SP: Estadísticas de clientes con mayor ganancia por año
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasClientesMayorGananciaAnio
    @fromyear INT = NULL, 
    @toyear INT = NULL,
    @sucursal NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    
    EXEC Corporate.SP_RefreshClientesMaterializada;

    IF @sucursal IS NULL OR @sucursal = 'Consolidado'
    BEGIN
        -- Consolidado
        WITH consolidated AS (
            SELECT
                v.Year,
                v.CustomerID,
                SUM(v.InvoiceCount) AS InvoiceCount,
                SUM(v.TotalAmount) AS TotalAmount
            FROM dbo.vw_TopClientesAnual v
            WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
              AND (@toyear IS NULL OR v.Year <= @toyear)
            GROUP BY v.Year, v.CustomerID
        ),
        ranked AS (
            SELECT
                Year,
                CustomerID,
                InvoiceCount,
                TotalAmount,
                DENSE_RANK() OVER (PARTITION BY Year ORDER BY InvoiceCount DESC) AS rnk
            FROM consolidated
        )
        SELECT 
            r.Year, 
            c.CustomerName, 
            r.InvoiceCount, 
            r.TotalAmount, 
            r.rnk,
            'Consolidado' AS Sucursal
        FROM ranked r
        JOIN Sales.Customers c ON c.CustomerID = r.CustomerID
        WHERE r.rnk <= 5
        ORDER BY r.Year, r.rnk;
    END
    ELSE
    BEGIN
        -- Por sucursal
        WITH r AS (
            SELECT
                v.Year,
                v.CustomerID,
                v.InvoiceCount,
                v.TotalAmount,
                v.Sucursal,
                DENSE_RANK() OVER (PARTITION BY v.Year, v.Sucursal ORDER BY v.InvoiceCount DESC) AS rnk
            FROM dbo.vw_TopClientesAnual v
            WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
              AND (@toyear IS NULL OR v.Year <= @toyear)
              AND v.Sucursal = @sucursal
        )
        SELECT 
            r.Year, 
            c.CustomerName, 
            r.InvoiceCount, 
            r.TotalAmount, 
            r.rnk,
            r.Sucursal
        FROM r
        JOIN Sales.Customers c ON c.CustomerID = r.CustomerID
        WHERE r.rnk <= 5
        ORDER BY r.Year, r.rnk;
    END
END;
GO

-- SP: Estadísticas de proveedores con mayores órdenes
CREATE OR ALTER PROCEDURE dbo.sp_estadisticasProveedoresConMayoresOrdenes
    @fromyear INT = NULL, 
    @toyear INT = NULL,
    @sucursal NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
   
    EXEC Corporate.SP_RefreshProveedoresMaterializada;

    IF @sucursal IS NULL OR @sucursal = 'Consolidado'
    BEGIN
        -- Consolidado
        WITH consolidated AS (
            SELECT
                v.Year,
                v.SupplierID,
                SUM(v.OrderCount) AS OrderCount,
                SUM(v.TotalAmount) AS TotalAmount
            FROM dbo.vw_TopProveedoresAnual v
            WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
              AND (@toyear IS NULL OR v.Year <= @toyear)
            GROUP BY v.Year, v.SupplierID
        ),
        ranked AS (
            SELECT
                Year,
                SupplierID,
                OrderCount,
                TotalAmount,
                DENSE_RANK() OVER (PARTITION BY Year ORDER BY OrderCount DESC) AS rnk
            FROM consolidated
        )
        SELECT 
            r.Year, 
            s.SupplierName, 
            r.OrderCount, 
            r.TotalAmount, 
            r.rnk,
            'Consolidado' AS Sucursal
        FROM ranked r
        JOIN Purchasing.Suppliers s ON s.SupplierID = r.SupplierID
        WHERE r.rnk <= 5
        ORDER BY r.Year, r.rnk;
    END
    ELSE
    BEGIN
        -- Por sucursal
        WITH r AS (
            SELECT
                v.Year,
                v.SupplierID,
                v.OrderCount,
                v.TotalAmount,
                v.Sucursal,
                DENSE_RANK() OVER (PARTITION BY v.Year, v.Sucursal ORDER BY v.OrderCount DESC) AS rnk
            FROM dbo.vw_TopProveedoresAnual v
            WHERE (@fromyear IS NULL OR v.Year >= @fromyear)
              AND (@toyear IS NULL OR v.Year <= @toyear)
              AND v.Sucursal = @sucursal
        )
        SELECT 
            r.Year, 
            s.SupplierName, 
            r.OrderCount, 
            r.TotalAmount, 
            r.rnk,
            r.Sucursal
        FROM r
        JOIN Purchasing.Suppliers s ON s.SupplierID = r.SupplierID
        WHERE r.rnk <= 5
        ORDER BY r.Year, r.rnk;
    END
END;
GO



