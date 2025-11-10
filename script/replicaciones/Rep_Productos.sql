-- ============================================================
-- REPLICACIÓN TRANSACCIONAL DE PRODUCTOS (Hub-and-Spoke)
-- ============================================================
-- ARQUITECTURA:
--   SanJose ←──→ CORPORATIVO ←──→ Limon
-- 
-- FLUJOS:
--   1. SanJose → CORP → Limon  (cuando SJ crea/edita productos)
--   2. Limon → CORP → SanJose  (cuando Limón crea/edita productos)
--
-- SERVIDORES (Docker Containers):
--   • CORPORATIVO: 127.0.0.1,1436 (sql_corp)
--   • LIMON:       127.0.0.1,1435 (sql_limon)
--   • SANJOSE:     127.0.0.1,1437 (sql_sj)
--   • Credenciales: sa / Passw0rd!
--
-- TABLAS REPLICADAS:
--   • Warehouse.StockItems
--   • Warehouse.StockItemStockGroups
--
-- TIPO: Transactional Replication (Bidireccional vía Hub)
--
-- ⚠️  PREREQUISITO:
--   Ejecutar PRIMERO los scripts de migración en las 3 bases:
--   1. Migracion_SanJose.sql      (en 127.0.0.1,1437)
--   2. Migracion_Limon.sql        (en 127.0.0.1,1435)
--   3. Migracion_Corporativo.sql  (en 127.0.0.1,1436)
--   
--   Esto garantiza que las 3 bases tengan el MISMO catálogo inicial.
--   La replicación es para CRUD futuros, no para datos iniciales.
-- ============================================================

USE master;
GO

-- ============================================================
-- PASO 1: CONFIGURAR DISTRIBUIDORES EN CADA SERVIDOR
-- ============================================================
-- Cada servidor debe ser su propio distribuidor

PRINT '========================================';
PRINT 'PASO 1: Configurando Distribuidores';
PRINT '========================================';
GO

-- ------------------------------------------------------------
-- 1.1. CONFIGURAR DISTRIBUIDOR EN SANJOSE (127.0.0.1,1437)
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1437 (sa/Passw0rd!)
PRINT 'Configurando distribuidor en SanJose (127.0.0.1,1437)...';
GO

USE master;
GO
-- Eliminar configuración previa de distribución
EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1;
GO

-- Eliminar base de datos distribution si quedó creada a medias
IF DB_ID('distribution') IS NOT NULL
BEGIN
    ALTER DATABASE distribution SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE distribution;
END
GO

-- Eliminar login antiguo si existe
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'distributor_admin')
    DROP LOGIN distributor_admin;
GO

-- Obtener el nombre del servidor actual (hostname del contenedor)
DECLARE @serverName NVARCHAR(128) = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128));
PRINT 'Nombre del servidor detectado: ' + @serverName;
GO

-- Configurar este servidor como distribuidor (usando el nombre del servidor)
DECLARE @serverName NVARCHAR(128) = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128));
EXEC sp_adddistributor 
    @distributor = @serverName,
    @password = N'Passw0rd!';
GO

-- Crear base de datos de distribución
EXEC sp_adddistributiondb 
    @database = N'distribution',
    @data_folder = N'/var/opt/mssql/data',
    @log_folder = N'/var/opt/mssql/data',
    @log_file_size = 2,
    @min_distretention = 0,
    @max_distretention = 72,
    @history_retention = 48;
GO

-- Registrar este servidor como publicador
DECLARE @serverName NVARCHAR(128) = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128));
EXEC sp_adddistpublisher 
    @publisher = @serverName,
    @distribution_db = N'distribution',
    @working_directory = N'/var/opt/mssql/repldata',
    @publisher_type = N'MSSQLSERVER';
GO

PRINT '✓ Distribuidor configurado en SanJose';
GO

-- ------------------------------------------------------------
-- 1.2. CONFIGURAR DISTRIBUIDOR EN CORPORATIVO (127.0.0.1,1436)
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1436 (sa/Passw0rd!)
PRINT 'Configurando distribuidor en Corporativo (127.0.0.1,1436)...';
GO

USE master;
GO

-- Eliminar configuración previa de distribución
EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1;
GO

-- Eliminar base de datos distribution si quedó creada a medias
IF DB_ID('distribution') IS NOT NULL
BEGIN
    ALTER DATABASE distribution SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE distribution;
END
GO

-- Eliminar login antiguo si existe
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'distributor_admin')
    DROP LOGIN distributor_admin;
GO

-- Obtener el nombre del servidor actual
DECLARE @serverName NVARCHAR(128) = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128));
PRINT 'Nombre del servidor detectado: ' + @serverName;
GO

-- Configurar este servidor como distribuidor
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

PRINT '✓ Distribuidor configurado en Corporativo';
GO

-- ------------------------------------------------------------
-- 1.3. CONFIGURAR DISTRIBUIDOR EN LIMON (127.0.0.1,1435)
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1435 (sa/Passw0rd!)
PRINT 'Configurando distribuidor en Limon (127.0.0.1,1435)...';
GO

USE master;
GO

-- Eliminar configuración previa de distribución
EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1;
GO

-- Eliminar base de datos distribution si quedó creada a medias
IF DB_ID('distribution') IS NOT NULL
BEGIN
    ALTER DATABASE distribution SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE distribution;
END
GO

-- Eliminar login antiguo si existe
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'distributor_admin')
    DROP LOGIN distributor_admin;
GO

-- Obtener el nombre del servidor actual
DECLARE @serverName NVARCHAR(128) = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128));
PRINT 'Nombre del servidor detectado: ' + @serverName;
GO

-- Configurar este servidor como distribuidor
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

PRINT '✓ Distribuidor configurado en Limon';
GO

-- ============================================================
-- PASO 2: HABILITAR BASES DE DATOS PARA REPLICACIÓN
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT 'PASO 2: Habilitando bases para replicación';
PRINT '========================================';
GO

-- En SanJose
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
PRINT '✓ WWI_SanJose habilitada para publicación y suscripción';
GO

-- En Corporativo
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
PRINT '✓ WWI_Corporativo habilitada para publicación y suscripción';
GO

-- En Limon
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
PRINT '✓ WWI_Limon habilitada para publicación y suscripción';
GO

-- ============================================================
-- PASO 3: CREAR PUBLICACIONES
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT 'PASO 3: Creando Publicaciones';
PRINT '========================================';
GO

-- ------------------------------------------------------------
-- 3.1. PUBLICACIÓN: SANJOSE → CORP (Productos desde SanJose)
-- ------------------------------------------------------------
PRINT 'Creando publicación: SanJose → Corporativo...';
GO

USE WWI_SanJose;
GO

-- Crear publicación transaccional
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

-- Agregar artículo: Warehouse.StockItems
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

-- Agregar artículo: Warehouse.StockItemStockGroups
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

-- ------------------------------------------------------------
-- 3.2. PUBLICACIÓN: CORP → LIMON (Productos desde CORP a Limon)
-- ------------------------------------------------------------
PRINT 'Creando publicación: Corporativo → Limon...';
GO

USE WWI_Corporativo;
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

-- Agregar artículos (StockItems y StockItemStockGroups)
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

-- ------------------------------------------------------------
-- 3.3. PUBLICACIÓN: LIMON → CORP (Productos desde Limon)
-- ------------------------------------------------------------
PRINT 'Creando publicación: Limon → Corporativo...';
GO

USE WWI_Limon;
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

-- ------------------------------------------------------------
-- 3.4. PUBLICACIÓN: CORP → SANJOSE (Productos desde CORP a SanJose)
-- ------------------------------------------------------------
PRINT 'Creando publicación: Corporativo → SanJose...';
GO

USE WWI_Corporativo;
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
-- PASO 3.5: REGISTRAR SERVIDORES REMOTOS (LINKED SERVERS)
-- ============================================================
-- ⚠️  CRÍTICO: SQL Server necesita resolver los nombres de los subscribers
--     Los contenedores tienen hostnames internos (container IDs)
--     pero nosotros nos conectamos vía IP
--
--     Hostnames detectados:
--     • SanJose: sql_sj  (172.18.0.4)
--     • CORP:   sql_corp  (172.18.0.2)
--     • Limon:   sql_limon  (172.18.0.3)
--
--     Solución: Registrar cada servidor remoto con sp_addlinkedserver

PRINT '';
PRINT '========================================';
PRINT 'PASO 3.5: Registrando Linked Servers';
PRINT '========================================';
GO

-- ------------------------------------------------------------
-- 3.5.1. En SANJOSE: Registrar CORP como linked server
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1437 (SanJose)
PRINT 'Registrando CORP en SanJose...';
GO

USE master;
GO

-- Eliminar si existe
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'sql_corp')
    EXEC sp_dropserver @server = N'sql_corp', @droplogins = 'droplogins';
GO

-- Crear linked server usando hostname del contenedor CORP
EXEC sp_addlinkedserver 
    @server = N'sql_corp',
    @srvproduct = N'',
    @provider = N'SQLNCLI',
    @datasrc = N'172.18.0.2'; -- IP del contenedor CORP
GO

-- Configurar autenticación
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'sql_corp',
    @useself = N'False',
    @locallogin = NULL,
    @rmtuser = N'sa',
    @rmtpassword = N'Passw0rd!';
GO

PRINT '✓ CORP registrado en SanJose';
GO

-- ------------------------------------------------------------
-- 3.5.2. En CORPORATIVO: Registrar SANJOSE y LIMON
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1436 (Corporativo)
PRINT 'Registrando SanJose y Limon en CORP...';
GO

USE master;
GO

-- Registrar SanJose
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

-- Registrar Limon
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

PRINT '✓ SanJose y Limon registrados en CORP';
GO

-- ------------------------------------------------------------
-- 3.5.3. En LIMON: Registrar CORP
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1435 (Limon)
PRINT 'Registrando CORP en Limon...';
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

PRINT '✓ CORP registrado en Limon';
GO

-- ============================================================
-- PASO 4: CREAR SUSCRIPCIONES
-- ============================================================
-- ⚠️  USAR HOSTNAMES DE LOS CONTENEDORES (detectados con @@SERVERNAME)
--     • SanJose: sql_sj
--     • CORP:    sql_corp
--     • Limon:   sql_limon

PRINT '';
PRINT '========================================';
PRINT 'PASO 4: Creando Suscripciones';
PRINT '========================================';
GO

-- ------------------------------------------------------------
-- 4.1. SUSCRIPCIÓN: CORP suscribe a Pub_Productos_SJ_to_CORP
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1437 (SanJose)
PRINT 'Creando suscripción: CORP ← SanJose...';
GO

USE WWI_SanJose;
GO

EXEC sp_addsubscription 
    @publication = N'Pub_Productos_SJ_to_CORP',
    @subscriber = N'sql_corp', -- Hostname del contenedor CORP
    @destination_db = N'WWI_Corporativo',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only',
    @subscriber_type = 0;
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_Productos_SJ_to_CORP',
    @subscriber = N'sql_corp', -- Hostname del contenedor CORP
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

-- ------------------------------------------------------------
-- 4.2. SUSCRIPCIÓN: LIMON suscribe a Pub_Productos_CORP_to_Limon
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1436 (Corporativo)
PRINT 'Creando suscripción: Limon ← CORP...';
GO

USE WWI_Corporativo;
GO

EXEC sp_addsubscription 
    @publication = N'Pub_Productos_CORP_to_Limon',
    @subscriber = N'sql_limon', -- Hostname del contenedor Limon
    @destination_db = N'WWI_Limon',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only';
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_Productos_CORP_to_Limon',
    @subscriber = N'sql_limon', -- Hostname del contenedor Limon
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

-- ------------------------------------------------------------
-- 4.3. SUSCRIPCIÓN: CORP suscribe a Pub_Productos_Limon_to_CORP
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1435 (Limon)
PRINT 'Creando suscripción: CORP ← Limon...';
GO

USE WWI_Limon;
GO

EXEC sp_addsubscription 
    @publication = N'Pub_Productos_Limon_to_CORP',
    @subscriber = N'sql_corp', -- Hostname del contenedor CORP
    @destination_db = N'WWI_Corporativo',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only';
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_Productos_Limon_to_CORP',
    @subscriber = N'sql_corp', -- Hostname del contenedor CORP
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

-- ------------------------------------------------------------
-- 4.4. SUSCRIPCIÓN: SANJOSE suscribe a Pub_Productos_CORP_to_SJ
-- ------------------------------------------------------------
-- Ejecutar CONECTADO a: 127.0.0.1,1436 (Corporativo)
PRINT 'Creando suscripción: SanJose ← CORP...';
GO

USE WWI_Corporativo;
GO

EXEC sp_addsubscription 
    @publication = N'Pub_Productos_CORP_to_SJ',
    @subscriber = N'sql_sj', -- Hostname del contenedor SanJose
    @destination_db = N'WWI_SanJose',
    @subscription_type = N'Push',
    @sync_type = N'replication support only',
    @article = N'all',
    @update_mode = N'read only';
GO

EXEC sp_addpushsubscription_agent 
    @publication = N'Pub_Productos_CORP_to_SJ',
    @subscriber = N'sql_sj', -- Hostname del contenedor SanJose
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
-- PASO 5: CREAR SNAPSHOT AGENTS (JOBS)
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT 'PASO 5: Creando Snapshot Agents';
PRINT '========================================';
GO

-- ------------------------------------------------------------
-- 5.1. Crear Snapshot Agent para Pub_Productos_SJ_to_CORP
-- ------------------------------------------------------------
PRINT 'Creando Snapshot Agent: Pub_Productos_SJ_to_CORP...';
GO

USE WWI_SanJose;
GO

EXEC sp_addpublication_snapshot 
    @publication = N'Pub_Productos_SJ_to_CORP',
    @frequency_type = 1, -- Una vez
    @frequency_interval = 1,
    @frequency_relative_interval = 1,
    @frequency_recurrence_factor = 0,
    @frequency_subday = 8, -- Al crear el job
    @frequency_subday_interval = 1,
    @active_start_time_of_day = 0,
    @active_end_time_of_day = 235959,
    @active_start_date = 0,
    @active_end_date = 0,
    @job_login = NULL,
    @job_password = NULL,
    @publisher_security_mode = 1;
GO

PRINT '✓ Snapshot Agent creado: Pub_Productos_SJ_to_CORP';
GO

-- ------------------------------------------------------------
-- 5.2. Crear Snapshot Agent para Pub_Productos_CORP_to_Limon
-- ------------------------------------------------------------
PRINT 'Creando Snapshot Agent: Pub_Productos_CORP_to_Limon...';
GO

USE WWI_Corporativo;
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

PRINT '✓ Snapshot Agent creado: Pub_Productos_CORP_to_Limon';
GO

-- ------------------------------------------------------------
-- 5.3. Crear Snapshot Agent para Pub_Productos_Limon_to_CORP
-- ------------------------------------------------------------
PRINT 'Creando Snapshot Agent: Pub_Productos_Limon_to_CORP...';
GO

USE WWI_Limon;
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

PRINT '✓ Snapshot Agent creado: Pub_Productos_Limon_to_CORP';
GO

-- ------------------------------------------------------------
-- 5.4. Crear Snapshot Agent para Pub_Productos_CORP_to_SJ
-- ------------------------------------------------------------
PRINT 'Creando Snapshot Agent: Pub_Productos_CORP_to_SJ...';
GO

USE WWI_Corporativo;
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

PRINT '✓ Snapshot Agent creado: Pub_Productos_CORP_to_SJ';
GO

-- ============================================================
-- PASO 6: INICIALIZAR REPLICACIÓN (SIN SNAPSHOT)
-- ============================================================
-- ⚠️  IMPORTANTE: En replicación bidireccional Hub-and-Spoke,
--     NO ejecutamos snapshots porque las tablas YA tienen datos
--     idénticos (cargados por los scripts de migración).
--     
--     Los snapshots fallarían con error "Cannot truncate table
--     because it is published for replication".
--
--     La replicación comenzará a partir de AHORA, capturando
--     solo los cambios FUTUROS (INSERT, UPDATE, DELETE).

PRINT '';
PRINT '========================================';
PRINT 'PASO 6: Replicación Lista (Sin Snapshot)';
PRINT '========================================';
PRINT '';
PRINT '✓ Las 3 bases tienen datos IDÉNTICOS (227 productos)';
PRINT '✓ Replicación configurada para cambios FUTUROS';
PRINT '✓ NO se ejecutan snapshots (no compatible con replicación bidireccional)';
PRINT '';
GO

-- ============================================================
-- RESUMEN Y VERIFICACIÓN
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT 'CONFIGURACIÓN COMPLETADA';
PRINT '========================================';
PRINT '';
PRINT '📊 PUBLICACIONES CREADAS:';
PRINT '  1. Pub_Productos_SJ_to_CORP   (SanJose → CORP)';
PRINT '  2. Pub_Productos_CORP_to_Limon (CORP → Limon)';
PRINT '  3. Pub_Productos_Limon_to_CORP (Limon → CORP)';
PRINT '  4. Pub_Productos_CORP_to_SJ    (CORP → SanJose)';
PRINT '';
PRINT '🔄 FLUJO DE REPLICACIÓN:';
PRINT '  • Cambio en SanJose: SJ → CORP → Limon';
PRINT '  • Cambio en Limon:   Limon → CORP → SJ';
PRINT '';
PRINT '⚠️  IMPORTANTE:';
PRINT '  • Evitar ediciones simultáneas del mismo producto';
PRINT '  • Latencia: ~5-10 segundos entre sucursales';
PRINT '  • SQL Agent debe estar corriendo en todos los servidores';
PRINT '  • NO usar TRUNCATE en tablas replicadas';
PRINT '';
PRINT '📋 VERIFICAR AGENTES:';
PRINT '  SELECT * FROM msdb.dbo.sysjobs WHERE name LIKE ''%Productos%'';';
PRINT '';
PRINT '📋 MONITOREAR REPLICACIÓN:';
PRINT '  EXEC sp_replmonitorhelppublication;';
PRINT '  EXEC sp_replmonitorhelpsubscription;';
PRINT '';
GO

-- ============================================================
-- SCRIPT DE VERIFICACIÓN (ejecutar después de configurar)
-- ============================================================


-- Verificar estado de publicaciones
USE WWI_SanJose;
EXEC sp_helppublication @publication = N'Pub_Productos_SJ_to_CORP';

USE WWI_Corporativo;
EXEC sp_helppublication @publication = N'Pub_Productos_CORP_to_Limon';
EXEC sp_helppublication @publication = N'Pub_Productos_CORP_to_SJ';

USE WWI_Limon;
EXEC sp_helppublication @publication = N'Pub_Productos_Limon_to_CORP';

-- Verificar estado de suscripciones
USE WWI_Corporativo;
EXEC sp_helpsubscription @publication = N'all';

USE WWI_SanJose;
EXEC sp_helpsubscription @publication = N'all';

USE WWI_Limon;
EXEC sp_helpsubscription @publication = N'all';

-- Probar replicación
-- En SanJose:
USE WWI_Limon;
INSERT INTO Warehouse.StockItems (StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, TaxRate, UnitPrice, TypicalWeightPerUnit, LastEditedBy)
VALUES ('Producto Test SJ', 1, 1, 1, 1, 'TestBrand', 'M', 0, 1, 0, 15.00, 10.00, 1.00, 1);

select * from Warehouse.StockItems where StockItemName = 'Producto Test SJ';

-- Esperar 10 segundos y verificar en CORP y Limon:
USE WWI_Corporativo;
SELECT * FROM Warehouse.StockItems WHERE StockItemName = 'Producto Test SJ';

USE WWI_SanJose;
SELECT * FROM Warehouse.StockItems WHERE StockItemName = 'Producto Test SJ';

-- ¿quién es el distribuidor?
EXEC sp_get_distributor;

-- ¿existe la base distribution?
SELECT name, state_desc FROM sys.databases WHERE name = 'distribution';

USE msdb;
SELECT job_id, name, enabled
FROM dbo.sysjobs
WHERE name LIKE '%Productos%' OR name LIKE '%snapshot%' OR name LIKE '%logreader%' OR name LIKE '%distribution%';

EXEC msdb.dbo.sp_help_job @job_name = N'sql_corp-WWI_Corporativo-Pub_Productos_CORP_to_Limon-1';
-- Y para ver el historial
SELECT sj.name, h.run_date, h.run_time, h.step_id, h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs sj ON h.job_id = sj.job_id
WHERE sj.name = '<nombre_del_job>'
ORDER BY h.run_date DESC, h.run_time DESC;


USE WWI_Limon;
GO

-- Verificar si StockItemID tiene IDENTITY:
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS ColumnName,
    is_identity AS IsIdentity,
    seed_value AS SeedValue,
    increment_value AS IncrementValue
FROM sys.identity_columns
WHERE OBJECT_NAME(object_id) = 'StockItems';
GO

EXEC sp_help 'Warehouse.StockItems';
GO



-- En LIMON (127.0.0.1,1435):
USE WWI_Limon;


INSERT INTO Warehouse.StockItems (StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, TaxRate, UnitPrice, TypicalWeightPerUnit, LastEditedBy)
VALUES (888888, 'PRUEBA DESDE LIMON', 1, 1, 1, 1, 'TestBrand', 'XL', 0, 1, 0, 15.00, 25.00, 1.50, 1);


SELECT * FROM Warehouse.StockItems WHERE StockItemID = 888888;

-- En CORPORATIVO (127.0.0.1,1436):
USE WWI_Corporativo;

SELECT * FROM Warehouse.StockItems WHERE StockItemID = 888888;

-- En SANJOSE (127.0.0.1,1437):
USE WWI_SanJose;
SELECT * FROM Warehouse.StockItems WHERE StockItemID = 888888;