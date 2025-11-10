-- ============================================================
-- FIX AUTOMÁTICO DE STORED PROCEDURES PARA IDENTITY
-- ============================================================
-- ⚠️  EJECUTAR ESTE SCRIPT SIEMPRE DESPUÉS DE CONFIGURAR REPLICACIÓN
--
-- PROBLEMA:
--   Cuando usas @sync_type = 'replication support only',
--   SQL Server auto-genera SPs de INSERT sin SET IDENTITY_INSERT
--   
-- SOLUCIÓN:
--   Este script modifica todos los SP necesarios en Corporativo
--
-- CUÁNDO EJECUTAR:
--   Después de crear las publicaciones/suscripciones operacionales:
--   1. Ejecutar 4_SanJose_PropiasSuc.sql
--   2. Ejecutar 5_Limon_PropiasSuc.sql
--   3. ✅ EJECUTAR ESTE SCRIPT (6_Fix_Identity_SPs_ALWAYS.sql)
--   4. Reiniciar distribution agents
--
-- TABLAS AFECTADAS:
--   SanJose:
--     • Warehouse.StockItemTransactions_SJ    (StockItemTransactionID)
--     • Sales.Invoices_SJ                     (InvoiceID)
--     • Sales.InvoiceLines_SJ                 (InvoiceLineID)
--     • Purchasing.PurchaseOrders_SJ          (PurchaseOrderID)
--     • Purchasing.PurchaseOrderLines_SJ      (PurchaseOrderLineID)
--   
--   Limon:
--     • Warehouse.StockItemTransactions_Limon (StockItemTransactionID)
--     • Sales.Invoices_Limon                  (InvoiceID)
--     • Sales.InvoiceLines_Limon              (InvoiceLineID)
--     • Purchasing.PurchaseOrders_Limon       (PurchaseOrderID)
--     • Purchasing.PurchaseOrderLines_Limon   (PurchaseOrderLineID)
--
-- NOTA: Holdings NO necesita fix (no tiene columna IDENTITY)
-- ============================================================

USE WWI_Corporativo;
GO

PRINT '========================================';
PRINT 'FIXING IDENTITY INSERT STORED PROCEDURES';
PRINT '========================================';
PRINT '';
GO

-- ============================================================
-- SANJOSE - Stored Procedures
-- ============================================================

PRINT '📍 Modificando SPs de SanJose...';
GO

-- 1. StockItemTransactions_SJ
IF OBJECT_ID('dbo.sp_MSins_WarehouseStockItemTransactions_SJ', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_WarehouseStockItemTransactions_SJ;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_WarehouseStockItemTransactions_SJ
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 int,@c6 decimal(18,3),@c7 datetime2(7),@c8 int
    AS
    BEGIN
        SET IDENTITY_INSERT Warehouse.StockItemTransactions_SJ ON;
        INSERT INTO Warehouse.StockItemTransactions_SJ (StockItemTransactionID,StockItemID,TransactionTypeID,CustomerID,SupplierID,Quantity,TransactionOccurredWhen,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8);
        SET IDENTITY_INSERT Warehouse.StockItemTransactions_SJ OFF;
    END';
    
    PRINT '  ✅ sp_MSins_WarehouseStockItemTransactions_SJ';
END
GO

-- 2. Invoices_SJ
IF OBJECT_ID('dbo.sp_MSins_SalesInvoices_SJ', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_SalesInvoices_SJ;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_SalesInvoices_SJ
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 nvarchar(20),@c6 int,@c7 datetime2(7),@c8 nvarchar(max),@c9 int
    AS
    BEGIN
        SET IDENTITY_INSERT Sales.Invoices_SJ ON;
        INSERT INTO Sales.Invoices_SJ (InvoiceID,CustomerID,BillToCustomerID,OrderID,CustomerPurchaseOrderNumber,DeliveryMethodID,InvoiceDate,Comments,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8,@c9);
        SET IDENTITY_INSERT Sales.Invoices_SJ OFF;
    END';
    
    PRINT '  ✅ sp_MSins_SalesInvoices_SJ';
END
GO

-- 3. InvoiceLines_SJ
IF OBJECT_ID('dbo.sp_MSins_SalesInvoiceLines_SJ', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_SalesInvoiceLines_SJ;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_SalesInvoiceLines_SJ
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 nvarchar(100),@c6 int,@c7 decimal(18,3),@c8 decimal(18,2),@c9 decimal(18,2),@c10 decimal(18,2),@c11 int
    AS
    BEGIN
        SET IDENTITY_INSERT Sales.InvoiceLines_SJ ON;
        INSERT INTO Sales.InvoiceLines_SJ (InvoiceLineID,InvoiceID,StockItemID,PackageTypeID,Description,Quantity,UnitPrice,TaxRate,ExtendedPrice,LineProfit,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8,@c9,@c10,@c11);
        SET IDENTITY_INSERT Sales.InvoiceLines_SJ OFF;
    END';
    
    PRINT '  ✅ sp_MSins_SalesInvoiceLines_SJ';
END
GO

-- 4. PurchaseOrders_SJ
IF OBJECT_ID('dbo.sp_MSins_PurchasingPurchaseOrders_SJ', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_PurchasingPurchaseOrders_SJ;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_PurchasingPurchaseOrders_SJ
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 nvarchar(20),@c6 datetime2(7),@c7 datetime2(7),@c8 nvarchar(max),@c9 int
    AS
    BEGIN
        SET IDENTITY_INSERT Purchasing.PurchaseOrders_SJ ON;
        INSERT INTO Purchasing.PurchaseOrders_SJ (PurchaseOrderID,SupplierID,OrderDate,DeliveryMethodID,SupplierReference,ExpectedDeliveryDate,IsOrderFinalized,Comments,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8,@c9);
        SET IDENTITY_INSERT Purchasing.PurchaseOrders_SJ OFF;
    END';
    
    PRINT '  ✅ sp_MSins_PurchasingPurchaseOrders_SJ';
END
GO

-- 5. PurchaseOrderLines_SJ
IF OBJECT_ID('dbo.sp_MSins_PurchasingPurchaseOrderLines_SJ', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_PurchasingPurchaseOrderLines_SJ;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_PurchasingPurchaseOrderLines_SJ
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 nvarchar(100),@c6 int,@c7 decimal(18,2),@c8 int
    AS
    BEGIN
        SET IDENTITY_INSERT Purchasing.PurchaseOrderLines_SJ ON;
        INSERT INTO Purchasing.PurchaseOrderLines_SJ (PurchaseOrderLineID,PurchaseOrderID,StockItemID,PackageTypeID,Description,OrderedOuters,ExpectedUnitPricePerOuter,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8);
        SET IDENTITY_INSERT Purchasing.PurchaseOrderLines_SJ OFF;
    END';
    
    PRINT '  ✅ sp_MSins_PurchasingPurchaseOrderLines_SJ';
END
GO

-- ============================================================
-- LIMON - Stored Procedures
-- ============================================================

PRINT '';
PRINT '📍 Modificando SPs de Limon...';
GO

-- 6. StockItemTransactions_Limon
IF OBJECT_ID('dbo.sp_MSins_WarehouseStockItemTransactions_Limon', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_WarehouseStockItemTransactions_Limon;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_WarehouseStockItemTransactions_Limon
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 int,@c6 decimal(18,3),@c7 datetime2(7),@c8 int
    AS
    BEGIN
        SET IDENTITY_INSERT Warehouse.StockItemTransactions_Limon ON;
        INSERT INTO Warehouse.StockItemTransactions_Limon (StockItemTransactionID,StockItemID,TransactionTypeID,CustomerID,SupplierID,Quantity,TransactionOccurredWhen,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8);
        SET IDENTITY_INSERT Warehouse.StockItemTransactions_Limon OFF;
    END';
    
    PRINT '  ✅ sp_MSins_WarehouseStockItemTransactions_Limon';
END
GO

-- 7. Invoices_Limon
IF OBJECT_ID('dbo.sp_MSins_SalesInvoices_Limon', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_SalesInvoices_Limon;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_SalesInvoices_Limon
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 nvarchar(20),@c6 int,@c7 datetime2(7),@c8 nvarchar(max),@c9 int
    AS
    BEGIN
        SET IDENTITY_INSERT Sales.Invoices_Limon ON;
        INSERT INTO Sales.Invoices_Limon (InvoiceID,CustomerID,BillToCustomerID,OrderID,CustomerPurchaseOrderNumber,DeliveryMethodID,InvoiceDate,Comments,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8,@c9);
        SET IDENTITY_INSERT Sales.Invoices_Limon OFF;
    END';
    
    PRINT '  ✅ sp_MSins_SalesInvoices_Limon';
END
GO

-- 8. InvoiceLines_Limon
IF OBJECT_ID('dbo.sp_MSins_SalesInvoiceLines_Limon', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_SalesInvoiceLines_Limon;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_SalesInvoiceLines_Limon
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 nvarchar(100),@c6 int,@c7 decimal(18,3),@c8 decimal(18,2),@c9 decimal(18,2),@c10 decimal(18,2),@c11 int
    AS
    BEGIN
        SET IDENTITY_INSERT Sales.InvoiceLines_Limon ON;
        INSERT INTO Sales.InvoiceLines_Limon (InvoiceLineID,InvoiceID,StockItemID,PackageTypeID,Description,Quantity,UnitPrice,TaxRate,ExtendedPrice,LineProfit,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8,@c9,@c10,@c11);
        SET IDENTITY_INSERT Sales.InvoiceLines_Limon OFF;
    END';
    
    PRINT '  ✅ sp_MSins_SalesInvoiceLines_Limon';
END
GO

-- 9. PurchaseOrders_Limon
IF OBJECT_ID('dbo.sp_MSins_PurchasingPurchaseOrders_Limon', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_PurchasingPurchaseOrders_Limon;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_PurchasingPurchaseOrders_Limon
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 nvarchar(20),@c6 datetime2(7),@c7 datetime2(7),@c8 nvarchar(max),@c9 int
    AS
    BEGIN
        SET IDENTITY_INSERT Purchasing.PurchaseOrders_Limon ON;
        INSERT INTO Purchasing.PurchaseOrders_Limon (PurchaseOrderID,SupplierID,OrderDate,DeliveryMethodID,SupplierReference,ExpectedDeliveryDate,IsOrderFinalized,Comments,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8,@c9);
        SET IDENTITY_INSERT Purchasing.PurchaseOrders_Limon OFF;
    END';
    
    PRINT '  ✅ sp_MSins_PurchasingPurchaseOrders_Limon';
END
GO

-- 10. PurchaseOrderLines_Limon
IF OBJECT_ID('dbo.sp_MSins_PurchasingPurchaseOrderLines_Limon', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MSins_PurchasingPurchaseOrderLines_Limon;
    
    EXEC sp_executesql N'
    CREATE PROCEDURE dbo.sp_MSins_PurchasingPurchaseOrderLines_Limon
        @c1 int,@c2 int,@c3 int,@c4 int,@c5 nvarchar(100),@c6 int,@c7 decimal(18,2),@c8 int
    AS
    BEGIN
        SET IDENTITY_INSERT Purchasing.PurchaseOrderLines_Limon ON;
        INSERT INTO Purchasing.PurchaseOrderLines_Limon (PurchaseOrderLineID,PurchaseOrderID,StockItemID,PackageTypeID,Description,OrderedOuters,ExpectedUnitPricePerOuter,LastEditedBy)
        VALUES (@c1,@c2,@c3,@c4,@c5,@c6,@c7,@c8);
        SET IDENTITY_INSERT Purchasing.PurchaseOrderLines_Limon OFF;
    END';
    
    PRINT '  ✅ sp_MSins_PurchasingPurchaseOrderLines_Limon';
END
GO

-- ============================================================
-- VERIFICACIÓN
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT 'VERIFICACIÓN DE SPs MODIFICADOS';
PRINT '========================================';
GO

SELECT 
    OBJECT_NAME(object_id) AS [Stored Procedure],
    CASE 
        WHEN OBJECT_DEFINITION(object_id) LIKE '%SET IDENTITY_INSERT%ON%' 
        THEN '✅ FIXED'
        ELSE '❌ MISSING FIX'
    END AS [Status]
FROM sys.procedures
WHERE name LIKE 'sp_MSins_%'
  AND name NOT LIKE '%Holdings%' -- Holdings no necesita fix
ORDER BY name;
GO

PRINT '';
PRINT '========================================';
PRINT '✅ FIX COMPLETADO';
PRINT '========================================';
PRINT '';
PRINT '📋 SIGUIENTE PASO:';
PRINT '   Reiniciar distribution agents:';
PRINT '   • SanJose:  Job ''sql_sj-WWI_SanJose-Pub_PropiasSJ_to_CORP-sql_corp-2''';
PRINT '   • Limon:    Job ''sql_limon-WWI_Limon-Pub_PropiasLimon_to_C-sql_corp-2''';
PRINT '';
GO
