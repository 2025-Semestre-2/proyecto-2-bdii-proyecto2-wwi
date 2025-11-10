-- ============================================================
-- REPLICACIÓN DE PRODUCTOS - CORPORATIVO
-- ============================================================
-- Ejecutar en: 127.0.0.1,1436 (Corporativo)
-- ============================================================

USE master;
GO

PRINT '========================================';
PRINT 'CONFIGURANDO REPLICACIÓN EN CORPORATIVO';
PRINT '========================================';
GO

-- ============================================================
-- 1. CONFIGURAR DISTRIBUIDOR
-- ============================================================
PRINT 'Paso 1: Configurando distribuidor...';
GO

DECLARE @serverName NVARCHAR(128) = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128));
EXEC sp_adddistributor 
    @distributor = @serverName,
    @password = N'Passw0rd!';
GO

EXEC sp_adddistributiondb 
    @database = N'distribution',
    @data_folder = N'/var/opt/mssql/data',
    @log_folder = N'/var/opt/mssql/data',
    @log_file_size = 2,
    @min_distretention = 0,
    @max_distretention = 72,
    @history_retention = 48;
GO

DECLARE @serverName NVARCHAR(128) = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128));
EXEC sp_adddistpublisher 
    @publisher = @serverName,
    @distribution_db = N'distribution',
    @working_directory = N'/var/opt/mssql/repldata',
    @publisher_type = N'MSSQLSERVER';
GO

PRINT '✓ Distribuidor configurado';
GO

-- ============================================================
-- 2. HABILITAR BASE PARA REPLICACIÓN
-- ============================================================
PRINT 'Paso 2: Habilitando WWI_Corporativo para replicación...';
GO

USE WWI_Corporativo;
GO

EXEC sp_replicationdboption 
    @dbname = N'WWI_Corporativo',
    @optname = N'publish',
    @value = N'true';
GO

EXEC sp_replicationdboption 
    @dbname = N'WWI_Corporativo',
    @optname = N'subscribe',
    @value = N'true';
GO

PRINT '✓ WWI_Corporativo habilitada para replicación';
GO

-- ============================================================
-- 3. CREAR PUBLICACIÓN: CORP → Limon
-- ============================================================
PRINT 'Paso 3a: Creando publicación Pub_Productos_CORP_to_Limon...';
GO

EXEC sp_addpublication 
    @publication = N'Pub_Productos_CORP_to_Limon',
    @description = N'Replicación de productos desde Corporativo a Limon',
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

EXEC sp_addarticle 
    @publication = N'Pub_Productos_CORP_to_Limon',
    @article = N'StockItems',
    @source_owner = N'Warehouse',
    @source_object = N'StockItems',
    @type = N'logbased',
    @description = N'Catálogo de productos',
    @pre_creation_cmd = N'truncate',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'StockItems',
    @destination_owner = N'Warehouse';
GO

EXEC sp_addarticle 
    @publication = N'Pub_Productos_CORP_to_Limon',
    @article = N'StockItemStockGroups',
    @source_owner = N'Warehouse',
    @source_object = N'StockItemStockGroups',
    @type = N'logbased',
    @description = N'Relación producto-grupo',
    @pre_creation_cmd = N'truncate',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'StockItemStockGroups',
    @destination_owner = N'Warehouse';
GO

PRINT '✓ Publicación creada: Pub_Productos_CORP_to_Limon';
GO

-- ============================================================
-- 4. CREAR PUBLICACIÓN: CORP → SanJose
-- ============================================================
PRINT 'Paso 3b: Creando publicación Pub_Productos_CORP_to_SJ...';
GO

EXEC sp_addpublication 
    @publication = N'Pub_Productos_CORP_to_SJ',
    @description = N'Replicación de productos desde Corporativo a SanJose',
    @sync_method = N'concurrent',
    @retention = 0,
    @allow_push = N'true',
    @allow_pull = N'true',
    @repl_freq = N'continuous',
    @status = N'active',
    @independent_agent = N'true',
    @replicate_ddl = 1,
    @enabled_for_p2p = N'false';
GO

EXEC sp_addarticle 
    @publication = N'Pub_Productos_CORP_to_SJ',
    @article = N'StockItems',
    @source_owner = N'Warehouse',
    @source_object = N'StockItems',
    @type = N'logbased',
    @pre_creation_cmd = N'truncate',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'StockItems',
    @destination_owner = N'Warehouse';
GO

EXEC sp_addarticle 
    @publication = N'Pub_Productos_CORP_to_SJ',
    @article = N'StockItemStockGroups',
    @source_owner = N'Warehouse',
    @source_object = N'StockItemStockGroups',
    @type = N'logbased',
    @pre_creation_cmd = N'truncate',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'StockItemStockGroups',
    @destination_owner = N'Warehouse';
GO

PRINT '✓ Publicación creada: Pub_Productos_CORP_to_SJ';
GO

-- ============================================================
-- 5. REGISTRAR LINKED SERVERS
-- ============================================================
PRINT 'Paso 4: Registrando linked servers...';
GO

USE master;
GO

-- Linked server: SanJose
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'sql_sj')
    EXEC sp_dropserver @server = N'sql_sj', @droplogins = 'droplogins';
GO

EXEC sp_addlinkedserver 
    @server = N'sql_sj',
    @srvproduct = N'',
    @provider = N'SQLNCLI',
    @datasrc = N'172.18.0.4';
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'sql_sj',
    @useself = N'False',
    @locallogin = NULL,
    @rmtuser = N'sa',
    @rmtpassword = N'Passw0rd!';
GO

-- Linked server: Limon
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'sql_limon')
    EXEC sp_dropserver @server = N'sql_limon', @droplogins = 'droplogins';
GO

EXEC sp_addlinkedserver 
    @server = N'sql_limon',
    @srvproduct = N'',
    @provider = N'SQLNCLI',
    @datasrc = N'172.18.0.3';
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'sql_limon',
    @useself = N'False',
    @locallogin = NULL,
    @rmtuser = N'sa',
    @rmtpassword = N'Passw0rd!';
GO

PRINT '✓ Linked servers registrados: sql_sj, sql_limon';
GO

-- ============================================================
-- 6. CREAR SUSCRIPCIONES
-- ============================================================
PRINT 'Paso 5: Creando suscripciones...';
GO

USE WWI_Corporativo;
GO

-- Suscripción: Limon ← CORP
EXEC sp_addsubscription 
    @publication = N'Pub_Productos_CORP_to_Limon',
    @subscriber = N'sql_limon',
    @destination_db = N'WWI_Limon',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only';
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_Productos_CORP_to_Limon',
    @subscriber = N'sql_limon',
    @subscriber_db = N'WWI_Limon',
    @subscriber_security_mode = 0,
    @subscriber_login = N'sa',
    @subscriber_password = N'Passw0rd!',
    @frequency_type = 64,
    @frequency_subday = 4,
    @frequency_subday_interval = 5;
GO

PRINT '✓ Suscripción creada: Limon ← CORP';
GO

-- Suscripción: SanJose ← CORP
EXEC sp_addsubscription 
    @publication = N'Pub_Productos_CORP_to_SJ',
    @subscriber = N'sql_sj',
    @destination_db = N'WWI_SanJose',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only';
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_Productos_CORP_to_SJ',
    @subscriber = N'sql_sj',
    @subscriber_db = N'WWI_SanJose',
    @subscriber_security_mode = 0,
    @subscriber_login = N'sa',
    @subscriber_password = N'Passw0rd!',
    @frequency_type = 64,
    @frequency_subday = 4,
    @frequency_subday_interval = 5;
GO

PRINT '✓ Suscripción creada: SanJose ← CORP';
GO

-- ============================================================
-- 7. CREAR SNAPSHOT AGENTS
-- ============================================================
PRINT 'Paso 6: Creando snapshot agents...';
GO

EXEC sp_addpublication_snapshot 
    @publication = N'Pub_Productos_CORP_to_Limon',
    @frequency_type = 1,
    @frequency_interval = 1,
    @frequency_relative_interval = 1,
    @frequency_recurrence_factor = 0,
    @frequency_subday = 8,
    @frequency_subday_interval = 1,
    @active_start_time_of_day = 0,
    @active_end_time_of_day = 235959,
    @active_start_date = 0,
    @active_end_date = 0,
    @job_login = NULL,
    @job_password = NULL,
    @publisher_security_mode = 1;
GO

EXEC sp_addpublication_snapshot 
    @publication = N'Pub_Productos_CORP_to_SJ',
    @frequency_type = 1,
    @frequency_interval = 1,
    @frequency_relative_interval = 1,
    @frequency_recurrence_factor = 0,
    @frequency_subday = 8,
    @frequency_subday_interval = 1,
    @active_start_time_of_day = 0,
    @active_end_time_of_day = 235959,
    @active_start_date = 0,
    @active_end_date = 0,
    @job_login = NULL,
    @job_password = NULL,
    @publisher_security_mode = 1;
GO

PRINT '✓ Snapshot agents creados';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ CORPORATIVO CONFIGURADO EXITOSAMENTE';
PRINT '========================================';
PRINT 'Publicaciones: Pub_Productos_CORP_to_Limon, Pub_Productos_CORP_to_SJ';
PRINT 'Suscripciones: Limon ← CORP, SanJose ← CORP';
PRINT '';
GO
