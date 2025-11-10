-- ============================================================
-- REPLICACIÓN DE DATOS PROPIOS - LIMON
-- ============================================================
-- Ejecutar en: 127.0.0.1,1435 (Limon)
-- ============================================================

USE master;
GO

PRINT '========================================';
PRINT 'CONFIGURANDO REPLICACIÓN DATOS PROPIOS - LIMON';
PRINT '========================================';
GO

-- ============================================================
-- 1. CREAR PUBLICACIÓN: PropiasLimon → CORP
-- ============================================================
PRINT 'Paso 1: Creando publicación Pub_PropiasLimon_to_CORP...';
GO

USE WWI_Limon;
GO

EXEC sp_addpublication 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @description = N'Replicación de datos propios de Limon a Corporativo',
    @sync_method = N'concurrent',
    @retention = 0,
    @allow_push = N'true',
    @allow_pull = N'true',
    @allow_anonymous = N'false',
    @enabled_for_internet = N'false',
    @snapshot_in_defaultfolder = N'true',
    @compress_snapshot = N'false',
    @repl_freq = N'continuous',
    @status = N'active',
    @independent_agent = N'true',
    @immediate_sync = N'false',
    @allow_sync_tran = N'false',
    @replicate_ddl = 1,
    @enabled_for_p2p = N'false';
GO

-- Artículo 1: StockItemHoldings_Limon
EXEC sp_addarticle 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @article = N'StockItemHoldings_Limon',
    @source_owner = N'Warehouse',
    @source_object = N'StockItemHoldings_Limon',
    @type = N'logbased',
    @description = N'Inventario de Limon',
    @pre_creation_cmd = N'drop',
    @schema_option = 0x0000000008035DFF,
    @identityrangemanagementoption = N'none',
    @destination_table = N'StockItemHoldings_Limon',
    @destination_owner = N'Warehouse';
GO

-- Artículo 2: StockItemTransactions_Limon
EXEC sp_addarticle 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @article = N'StockItemTransactions_Limon',
    @source_owner = N'Warehouse',
    @source_object = N'StockItemTransactions_Limon',
    @type = N'logbased',
    @description = N'Transacciones de inventario de Limon',
    @pre_creation_cmd = N'drop',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'StockItemTransactions_Limon',
    @destination_owner = N'Warehouse';
GO

-- Artículo 3: Invoices_Limon
EXEC sp_addarticle 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @article = N'Invoices_Limon',
    @source_owner = N'Sales',
    @source_object = N'Invoices_Limon',
    @type = N'logbased',
    @description = N'Facturas de Limon',
    @pre_creation_cmd = N'drop',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'Invoices_Limon',
    @destination_owner = N'Sales';
GO

-- Artículo 4: InvoiceLines_Limon
EXEC sp_addarticle 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @article = N'InvoiceLines_Limon',
    @source_owner = N'Sales',
    @source_object = N'InvoiceLines_Limon',
    @type = N'logbased',
    @description = N'Líneas de facturas de Limon',
    @pre_creation_cmd = N'drop',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'InvoiceLines_Limon',
    @destination_owner = N'Sales';
GO

-- Artículo 5: PurchaseOrders_Limon
EXEC sp_addarticle 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @article = N'PurchaseOrders_Limon',
    @source_owner = N'Purchasing',
    @source_object = N'PurchaseOrders_Limon',
    @type = N'logbased',
    @description = N'Órdenes de compra de Limon',
    @pre_creation_cmd = N'drop',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'PurchaseOrders_Limon',
    @destination_owner = N'Purchasing';
GO

-- Artículo 6: PurchaseOrderLines_Limon
EXEC sp_addarticle 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @article = N'PurchaseOrderLines_Limon',
    @source_owner = N'Purchasing',
    @source_object = N'PurchaseOrderLines_Limon',
    @type = N'logbased',
    @description = N'Líneas de órdenes de compra de Limon',
    @pre_creation_cmd = N'drop',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'PurchaseOrderLines_Limon',
    @destination_owner = N'Purchasing';
GO

PRINT '✓ Publicación creada: Pub_PropiasLimon_to_CORP (6 artículos)';
GO

-- ============================================================
-- 2. CREAR SUSCRIPCIÓN: CORP suscribe a PropiasLimon
-- ============================================================
PRINT 'Paso 2: Creando suscripción CORP ← Limon (datos propios)...';
GO

EXEC sp_addsubscription 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @subscriber = N'sql_corp',
    @destination_db = N'WWI_Corporativo',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only',
    @subscriber_type = 0;
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @subscriber = N'sql_corp',
    @subscriber_db = N'WWI_Corporativo',
    @job_login = NULL,
    @job_password = NULL,
    @subscriber_security_mode = 0,
    @subscriber_login = N'sa',
    @subscriber_password = N'Passw0rd!',
    @frequency_type = 64,
    @frequency_interval = 1,
    @frequency_relative_interval = 1,
    @frequency_recurrence_factor = 0,
    @frequency_subday = 4,
    @frequency_subday_interval = 5,
    @active_start_time_of_day = 0,
    @active_end_time_of_day = 235959,
    @active_start_date = 0,
    @active_end_date = 0,
    @dts_package_location = N'Distributor';
GO

PRINT '✓ Suscripción creada: CORP ← Limon (datos propios)';
GO

-- ============================================================
-- 3. CREAR SNAPSHOT AGENT
-- ============================================================
PRINT 'Paso 3: Creando snapshot agent...';
GO

EXEC sp_addpublication_snapshot 
    @publication = N'Pub_PropiasLimon_to_CORP',
    @frequency_type = 1,
    @frequency_interval = 0,
    @frequency_relative_interval = 0,
    @frequency_recurrence_factor = 0,
    @frequency_subday = 0,
    @frequency_subday_interval = 0,
    @active_start_time_of_day = 0,
    @active_end_time_of_day = 235959,
    @active_start_date = 0,
    @active_end_date = 0,
    @job_login = NULL,
    @job_password = NULL,
    @publisher_security_mode = 1;
GO

PRINT '✓ Snapshot agent creado';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ DATOS PROPIOS LIMON CONFIGURADOS';
PRINT '========================================';
PRINT 'Publicación: Pub_PropiasLimon_to_CORP (6 tablas)';
PRINT 'Flujo: Limon → CORP (unidireccional)';
PRINT '';
GO
