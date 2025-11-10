-- ============================================================
-- REPLICACIÓN DE PRODUCTOS - LIMON
-- ============================================================
-- Ejecutar en: 127.0.0.1,1435 (Limon)
-- ============================================================

USE master;
GO

PRINT '========================================';
PRINT 'CONFIGURANDO REPLICACIÓN EN LIMON';
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
PRINT 'Paso 2: Habilitando WWI_Limon para replicación...';
GO

USE WWI_Limon;
GO

EXEC sp_replicationdboption 
    @dbname = N'WWI_Limon',
    @optname = N'publish',
    @value = N'true';
GO

EXEC sp_replicationdboption 
    @dbname = N'WWI_Limon',
    @optname = N'subscribe',
    @value = N'true';
GO

PRINT '✓ WWI_Limon habilitada para replicación';
GO

-- ============================================================
-- 3. CREAR PUBLICACIÓN: Limon → CORP
-- ============================================================
PRINT 'Paso 3: Creando publicación Pub_Productos_Limon_to_CORP...';
GO

EXEC sp_addpublication 
    @publication = N'Pub_Productos_Limon_to_CORP',
    @description = N'Replicación de productos desde Limon a Corporativo',
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
    @publication = N'Pub_Productos_Limon_to_CORP',
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
    @publication = N'Pub_Productos_Limon_to_CORP',
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

PRINT '✓ Publicación creada: Pub_Productos_Limon_to_CORP';
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
-- 5. CREAR SUSCRIPCIÓN: CORP suscribe a Pub_Productos_Limon_to_CORP
-- ============================================================
PRINT 'Paso 5: Creando suscripción CORP ← Limon...';
GO

USE WWI_Limon;
GO

EXEC sp_addsubscription 
    @publication = N'Pub_Productos_Limon_to_CORP',
    @subscriber = N'sql_corp',
    @destination_db = N'WWI_Corporativo',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only';
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_Productos_Limon_to_CORP',
    @subscriber = N'sql_corp',
    @subscriber_db = N'WWI_Corporativo',
    @subscriber_security_mode = 0,
    @subscriber_login = N'sa',
    @subscriber_password = N'Passw0rd!',
    @frequency_type = 64,
    @frequency_subday = 4,
    @frequency_subday_interval = 5;
GO

PRINT '✓ Suscripción creada: CORP ← Limon';
GO

-- ============================================================
-- 6. CREAR SNAPSHOT AGENT
-- ============================================================
PRINT 'Paso 6: Creando snapshot agent...';
GO

EXEC sp_addpublication_snapshot 
    @publication = N'Pub_Productos_Limon_to_CORP',
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
PRINT '✓ LIMON CONFIGURADO EXITOSAMENTE';
PRINT '========================================';
PRINT 'Publicación: Pub_Productos_Limon_to_CORP';
PRINT 'Suscripción: CORP ← Limon';
PRINT '';
GO
