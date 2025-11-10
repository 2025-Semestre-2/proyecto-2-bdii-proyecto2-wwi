-- ============================================================
-- REPLICACIÓN DE PRODUCTOS - SANJOSE
-- ============================================================
-- Ejecutar en: 127.0.0.1,1437 (SanJose)
-- ============================================================

USE master;
GO

PRINT '========================================';
PRINT 'CONFIGURANDO REPLICACIÓN EN SANJOSE';
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
PRINT 'Paso 2: Habilitando WWI_SanJose para replicación...';
GO

USE WWI_SanJose;
GO

EXEC sp_replicationdboption 
    @dbname = N'WWI_SanJose',
    @optname = N'publish',
    @value = N'true';
GO

EXEC sp_replicationdboption 
    @dbname = N'WWI_SanJose',
    @optname = N'subscribe',
    @value = N'true';
GO

PRINT '✓ WWI_SanJose habilitada para replicación';
GO

-- ============================================================
-- 3. CREAR PUBLICACIÓN: SanJose → CORP
-- ============================================================
PRINT 'Paso 3: Creando publicación Pub_Productos_SJ_to_CORP...';
GO

EXEC sp_addpublication 
    @publication = N'Pub_Productos_SJ_to_CORP',
    @description = N'Replicación de productos desde SanJose a Corporativo',
    @sync_method = N'concurrent',
    @retention = 0,
    @allow_push = N'true',
    @allow_pull = N'true',
    @allow_anonymous = N'false',
    @enabled_for_internet = N'false',
    @snapshot_in_defaultfolder = N'true',
    @compress_snapshot = N'false',
    @ftp_port = 21,
    @ftp_login = N'anonymous',
    @allow_subscription_copy = N'false',
    @add_to_active_directory = N'false',
    @repl_freq = N'continuous',
    @status = N'active',
    @independent_agent = N'true',
    @immediate_sync = N'false',
    @allow_sync_tran = N'false',
    @autogen_sync_procs = N'false',
    @allow_queued_tran = N'false',
    @allow_dts = N'false',
    @replicate_ddl = 1,
    @allow_initialize_from_backup = N'false',
    @enabled_for_p2p = N'false',
    @enabled_for_het_sub = N'false';
GO

-- Artículo: StockItems
EXEC sp_addarticle 
    @publication = N'Pub_Productos_SJ_to_CORP',
    @article = N'StockItems',
    @source_owner = N'Warehouse',
    @source_object = N'StockItems',
    @type = N'logbased',
    @description = N'Catálogo de productos',
    @creation_script = NULL,
    @pre_creation_cmd = N'truncate',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'StockItems',
    @destination_owner = N'Warehouse',
    @status = 24,
    @vertical_partition = N'false',
    @ins_cmd = N'CALL [sp_MSins_WarehouseStockItems]',
    @del_cmd = N'CALL [sp_MSdel_WarehouseStockItems]',
    @upd_cmd = N'SCALL [sp_MSupd_WarehouseStockItems]';
GO

-- Artículo: StockItemStockGroups
EXEC sp_addarticle 
    @publication = N'Pub_Productos_SJ_to_CORP',
    @article = N'StockItemStockGroups',
    @source_owner = N'Warehouse',
    @source_object = N'StockItemStockGroups',
    @type = N'logbased',
    @description = N'Relación producto-grupo',
    @creation_script = NULL,
    @pre_creation_cmd = N'truncate',
    @schema_option = 0x0000000008835DFF,
    @identityrangemanagementoption = N'manual',
    @destination_table = N'StockItemStockGroups',
    @destination_owner = N'Warehouse',
    @status = 24,
    @vertical_partition = N'false',
    @ins_cmd = N'CALL [sp_MSins_WarehouseStockItemStockGroups]',
    @del_cmd = N'CALL [sp_MSdel_WarehouseStockItemStockGroups]',
    @upd_cmd = N'SCALL [sp_MSupd_WarehouseStockItemStockGroups]';
GO

PRINT '✓ Publicación creada: Pub_Productos_SJ_to_CORP';
GO

-- ============================================================
-- 4. REGISTRAR LINKED SERVER: CORP
-- ============================================================
PRINT 'Paso 4: Registrando linked server sql_corp...';
GO

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'sql_corp')
    EXEC sp_dropserver @server = N'sql_corp', @droplogins = 'droplogins';
GO

EXEC sp_addlinkedserver 
    @server = N'sql_corp',
    @srvproduct = N'',
    @provider = N'SQLNCLI',
    @datasrc = N'172.18.0.2';
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'sql_corp',
    @useself = N'False',
    @locallogin = NULL,
    @rmtuser = N'sa',
    @rmtpassword = N'Passw0rd!';
GO

PRINT '✓ Linked server sql_corp registrado';
GO

-- ============================================================
-- 5. CREAR SUSCRIPCIÓN: CORP suscribe a Pub_Productos_SJ_to_CORP
-- ============================================================
PRINT 'Paso 5: Creando suscripción CORP ← SanJose...';
GO

USE WWI_SanJose;
GO

EXEC sp_addsubscription 
    @publication = N'Pub_Productos_SJ_to_CORP',
    @subscriber = N'sql_corp',
    @destination_db = N'WWI_Corporativo',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only',
    @subscriber_type = 0;
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_Productos_SJ_to_CORP',
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

PRINT '✓ Suscripción creada: CORP ← SanJose';
GO

-- ============================================================
-- 6. CREAR SNAPSHOT AGENT
-- ============================================================
PRINT 'Paso 6: Creando snapshot agent...';
GO

EXEC sp_addpublication_snapshot 
    @publication = N'Pub_Productos_SJ_to_CORP',
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

PRINT '✓ Snapshot agent creado';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ SANJOSE CONFIGURADO EXITOSAMENTE';
PRINT '========================================';
PRINT 'Publicación: Pub_Productos_SJ_to_CORP';
PRINT 'Suscripción: CORP ← SanJose';
PRINT '';
GO
