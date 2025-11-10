-- ============================================================
-- LIMPIEZA COMPLETA DE REPLICACIÓN (Rep_Productos.sql)
-- ============================================================
-- Este script elimina TODA la configuración de replicación
-- creada por Rep_Productos.sql en los 3 servidores.
--
-- ⚠️  EJECUTAR EN ESTE ORDEN:
--   1. En SanJose (127.0.0.1,1437)
--   2. En Corporativo (127.0.0.1,1436)  
--   3. En Limon (127.0.0.1,1435)
--
-- ⚠️  NO REINICIA LOS CONTENEDORES - Solo limpia metadata
-- ============================================================

USE master;
GO

PRINT '========================================';
PRINT 'LIMPIEZA COMPLETA DE REPLICACIÓN';
PRINT 'Servidor: ' + @@SERVERNAME;
PRINT '========================================';
GO

-- ============================================================
-- PASO 1: DETENER TODOS LOS JOBS DE REPLICACIÓN
-- ============================================================
PRINT '';
PRINT 'PASO 1: Deteniendo jobs de replicación...';
GO

DECLARE @job_name NVARCHAR(256);
DECLARE @job_id UNIQUEIDENTIFIER;

DECLARE job_cursor CURSOR FOR
SELECT job_id, name 
FROM msdb.dbo.sysjobs
WHERE name LIKE '%Productos%' 
   OR name LIKE '%snapshot%' 
   OR name LIKE '%logreader%' 
   OR name LIKE '%distribution%'
   OR name LIKE '%Pub_%'
   OR name LIKE '%WWI_%';

OPEN job_cursor;
FETCH NEXT FROM job_cursor INTO @job_id, @job_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        PRINT '  Deteniendo job: ' + @job_name;
        EXEC msdb.dbo.sp_stop_job @job_id = @job_id;
    END TRY
    BEGIN CATCH
        PRINT '  (Job ya estaba detenido o no se pudo detener)';
    END CATCH
    
    FETCH NEXT FROM job_cursor INTO @job_id, @job_name;
END

CLOSE job_cursor;
DEALLOCATE job_cursor;
GO

PRINT '✓ Jobs detenidos';
GO

-- ============================================================
-- PASO 2: ELIMINAR SUSCRIPCIONES (Push Subscriptions)
-- ============================================================
PRINT '';
PRINT 'PASO 2: Eliminando suscripciones...';
GO

-- Detectar qué base de datos usar según el servidor
DECLARE @dbName NVARCHAR(128);
DECLARE @serverName NVARCHAR(128) = @@SERVERNAME;

IF @serverName = 'sql_sj'
    SET @dbName = 'WWI_SanJose';
ELSE IF @serverName = 'sql_corp'
    SET @dbName = 'WWI_Corporativo';
ELSE IF @serverName = 'sql_limon'
    SET @dbName = 'WWI_Limon';
ELSE
    SET @dbName = 'WWI_Corporativo'; -- Default

PRINT '  Base de datos detectada: ' + @dbName;
GO

-- En SanJose: Eliminar suscripción CORP ← SanJose
IF @@SERVERNAME = 'sql_sj'
BEGIN
    USE WWI_SanJose;
    
    IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'Pub_Productos_SJ_to_CORP')
    BEGIN
        PRINT '  Eliminando suscripción: CORP ← SanJose';
        
        EXEC sp_dropsubscription 
            @publication = N'Pub_Productos_SJ_to_CORP',
            @subscriber = N'sql_corp',
            @destination_db = N'WWI_Corporativo',
            @article = N'all';
    END
END
GO

-- En Corporativo: Eliminar suscripciones Limon ← CORP y SanJose ← CORP
IF @@SERVERNAME = 'sql_corp'
BEGIN
    USE WWI_Corporativo;
    
    -- Eliminar suscripción a Limon
    IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'Pub_Productos_CORP_to_Limon')
    BEGIN
        PRINT '  Eliminando suscripción: Limon ← CORP';
        
        EXEC sp_dropsubscription 
            @publication = N'Pub_Productos_CORP_to_Limon',
            @subscriber = N'sql_limon',
            @destination_db = N'WWI_Limon',
            @article = N'all';
    END
    
    -- Eliminar suscripción a SanJose
    IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'Pub_Productos_CORP_to_SJ')
    BEGIN
        PRINT '  Eliminando suscripción: SanJose ← CORP';
        
        EXEC sp_dropsubscription 
            @publication = N'Pub_Productos_CORP_to_SJ',
            @subscriber = N'sql_sj',
            @destination_db = N'WWI_SanJose',
            @article = N'all';
    END
END
GO

-- En Limon: Eliminar suscripción CORP ← Limon
IF @@SERVERNAME = 'sql_limon'
BEGIN
    USE WWI_Limon;
    
    IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'Pub_Productos_Limon_to_CORP')
    BEGIN
        PRINT '  Eliminando suscripción: CORP ← Limon';
        
        EXEC sp_dropsubscription 
            @publication = N'Pub_Productos_Limon_to_CORP',
            @subscriber = N'sql_corp',
            @destination_db = N'WWI_Corporativo',
            @article = N'all';
    END
END
GO

PRINT '✓ Suscripciones eliminadas';
GO

-- ============================================================
-- PASO 3: ELIMINAR PUBLICACIONES
-- ============================================================
PRINT '';
PRINT 'PASO 3: Eliminando publicaciones...';
GO

-- En SanJose
IF @@SERVERNAME = 'sql_sj'
BEGIN
    USE WWI_SanJose;
    
    IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'Pub_Productos_SJ_to_CORP')
    BEGIN
        PRINT '  Eliminando publicación: Pub_Productos_SJ_to_CORP';
        EXEC sp_droppublication @publication = N'Pub_Productos_SJ_to_CORP';
    END
END
GO

-- En Corporativo
IF @@SERVERNAME = 'sql_corp'
BEGIN
    USE WWI_Corporativo;
    
    IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'Pub_Productos_CORP_to_Limon')
    BEGIN
        PRINT '  Eliminando publicación: Pub_Productos_CORP_to_Limon';
        EXEC sp_droppublication @publication = N'Pub_Productos_CORP_to_Limon';
    END
    
    IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'Pub_Productos_CORP_to_SJ')
    BEGIN
        PRINT '  Eliminando publicación: Pub_Productos_CORP_to_SJ';
        EXEC sp_droppublication @publication = N'Pub_Productos_CORP_to_SJ';
    END
END
GO

-- En Limon
IF @@SERVERNAME = 'sql_limon'
BEGIN
    USE WWI_Limon;
    
    IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'Pub_Productos_Limon_to_CORP')
    BEGIN
        PRINT '  Eliminando publicación: Pub_Productos_Limon_to_CORP';
        EXEC sp_droppublication @publication = N'Pub_Productos_Limon_to_CORP';
    END
END
GO

PRINT '✓ Publicaciones eliminadas';
GO

-- ============================================================
-- PASO 4: DESHABILITAR BASES DE DATOS PARA REPLICACIÓN
-- ============================================================
PRINT '';
PRINT 'PASO 4: Deshabilitando bases de datos...';
GO

-- En SanJose
IF @@SERVERNAME = 'sql_sj'
BEGIN
    USE master;
    
    EXEC sp_replicationdboption 
        @dbname = N'WWI_SanJose',
        @optname = N'publish',
        @value = N'false';
    
    EXEC sp_replicationdboption 
        @dbname = N'WWI_SanJose',
        @optname = N'subscribe',
        @value = N'false';
    
    PRINT '  WWI_SanJose deshabilitada';
END
GO

-- En Corporativo
IF @@SERVERNAME = 'sql_corp'
BEGIN
    USE master;
    
    EXEC sp_replicationdboption 
        @dbname = N'WWI_Corporativo',
        @optname = N'publish',
        @value = N'false';
    
    EXEC sp_replicationdboption 
        @dbname = N'WWI_Corporativo',
        @optname = N'subscribe',
        @value = N'false';
    
    PRINT '  WWI_Corporativo deshabilitada';
END
GO

-- En Limon
IF @@SERVERNAME = 'sql_limon'
BEGIN
    USE master;
    
    EXEC sp_replicationdboption 
        @dbname = N'WWI_Limon',
        @optname = N'publish',
        @value = N'false';
    
    EXEC sp_replicationdboption 
        @dbname = N'WWI_Limon',
        @optname = N'subscribe',
        @value = N'false';
    
    PRINT '  WWI_Limon deshabilitada';
END
GO

PRINT '✓ Bases de datos deshabilitadas';
GO

-- ============================================================
-- PASO 5: ELIMINAR DISTRIBUIDOR
-- ============================================================
PRINT '';
PRINT 'PASO 5: Eliminando distribuidor...';
GO

USE master;
GO

-- Forzar eliminación del distribuidor
EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1;
GO

PRINT '✓ Distribuidor eliminado';
GO

-- ============================================================
-- PASO 6: ELIMINAR BASE DE DATOS DISTRIBUTION
-- ============================================================
PRINT '';
PRINT 'PASO 6: Eliminando base de datos distribution...';
GO

USE master;
GO

IF DB_ID('distribution') IS NOT NULL
BEGIN
    -- Forzar cierre de conexiones
    ALTER DATABASE distribution SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    -- Eliminar la base de datos
    DROP DATABASE distribution;
    
    PRINT '✓ Base de datos distribution eliminada';
END
ELSE
BEGIN
    PRINT '  (Base de datos distribution no existe)';
END
GO

-- ============================================================
-- PASO 7: ELIMINAR LINKED SERVERS
-- ============================================================
PRINT '';
PRINT 'PASO 7: Eliminando linked servers...';
GO

USE master;
GO

-- En SanJose: Eliminar linked server a CORP
IF @@SERVERNAME = 'sql_sj'
BEGIN
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'sql_corp')
    BEGIN
        EXEC sp_dropserver @server = N'sql_corp', @droplogins = 'droplogins';
        PRINT '  Linked server sql_corp eliminado';
    END
END
GO

-- En Corporativo: Eliminar linked servers a SanJose y Limon
IF @@SERVERNAME = 'sql_corp'
BEGIN
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'sql_sj')
    BEGIN
        EXEC sp_dropserver @server = N'sql_sj', @droplogins = 'droplogins';
        PRINT '  Linked server sql_sj eliminado';
    END
    
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'sql_limon')
    BEGIN
        EXEC sp_dropserver @server = N'sql_limon', @droplogins = 'droplogins';
        PRINT '  Linked server sql_limon eliminado';
    END
END
GO

-- En Limon: Eliminar linked server a CORP
IF @@SERVERNAME = 'sql_limon'
BEGIN
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'sql_corp')
    BEGIN
        EXEC sp_dropserver @server = N'sql_corp', @droplogins = 'droplogins';
        PRINT '  Linked server sql_corp eliminado';
    END
END
GO

PRINT '✓ Linked servers eliminados';
GO

-- ============================================================
-- PASO 8: LIMPIAR JOBS HUÉRFANOS
-- ============================================================
PRINT '';
PRINT 'PASO 8: Eliminando jobs de replicación...';
GO

USE msdb;
GO

DECLARE @job_name_del NVARCHAR(256);
DECLARE @job_id_del UNIQUEIDENTIFIER;

DECLARE job_del_cursor CURSOR FOR
SELECT job_id, name 
FROM msdb.dbo.sysjobs
WHERE name LIKE '%Productos%' 
   OR name LIKE '%snapshot%' 
   OR name LIKE '%logreader%' 
   OR name LIKE '%distribution%'
   OR name LIKE '%Pub_%'
   OR name LIKE '%WWI_%';

OPEN job_del_cursor;
FETCH NEXT FROM job_del_cursor INTO @job_id_del, @job_name_del;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        PRINT '  Eliminando job: ' + @job_name_del;
        EXEC msdb.dbo.sp_delete_job @job_id = @job_id_del;
    END TRY
    BEGIN CATCH
        PRINT '  Error eliminando job: ' + @job_name_del;
        PRINT '  ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM job_del_cursor INTO @job_id_del, @job_name_del;
END

CLOSE job_del_cursor;
DEALLOCATE job_del_cursor;
GO

PRINT '✓ Jobs eliminados';
GO

-- ============================================================
-- PASO 9: ELIMINAR LOGIN distributor_admin
-- ============================================================
PRINT '';
PRINT 'PASO 9: Eliminando login distributor_admin...';
GO

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'distributor_admin')
BEGIN
    DROP LOGIN distributor_admin;
    PRINT '✓ Login distributor_admin eliminado';
END
ELSE
BEGIN
    PRINT '  (Login distributor_admin no existe)';
END
GO

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================
PRINT '';
PRINT '========================================';
PRINT 'VERIFICACIÓN FINAL';
PRINT '========================================';
GO

-- Verificar publicaciones
DECLARE @pub_count INT;
SELECT @pub_count = COUNT(*) FROM master.sys.databases db
JOIN sys.syspublications pub ON db.database_id = DB_ID(db.name)
WHERE db.name IN ('WWI_SanJose', 'WWI_Corporativo', 'WWI_Limon');

PRINT 'Publicaciones restantes: ' + CAST(@pub_count AS VARCHAR(10));
GO

-- Verificar distribuidor
IF EXISTS (SELECT * FROM sys.servers WHERE is_distributor = 1)
    PRINT '⚠️  ADVERTENCIA: Distribuidor aún existe';
ELSE
    PRINT '✓ Distribuidor eliminado correctamente';
GO

-- Verificar base distribution
IF DB_ID('distribution') IS NOT NULL
    PRINT '⚠️  ADVERTENCIA: Base distribution aún existe';
ELSE
    PRINT '✓ Base distribution eliminada correctamente';
GO

-- Verificar jobs
DECLARE @job_count INT;
SELECT @job_count = COUNT(*)
FROM msdb.dbo.sysjobs
WHERE name LIKE '%Productos%' 
   OR name LIKE '%snapshot%' 
   OR name LIKE '%logreader%' 
   OR name LIKE '%distribution%'
   OR name LIKE '%Pub_%';

PRINT 'Jobs de replicación restantes: ' + CAST(@job_count AS VARCHAR(10));
GO

-- Verificar linked servers (solo los de replicación)
DECLARE @linked_count INT;
SELECT @linked_count = COUNT(*)
FROM sys.servers
WHERE name IN ('sql_sj', 'sql_corp', 'sql_limon')
  AND server_id != 0; -- Excluir el servidor local

PRINT 'Linked servers de replicación restantes: ' + CAST(@linked_count AS VARCHAR(10));
GO

PRINT '';
PRINT '========================================';
PRINT '✓ LIMPIEZA COMPLETA FINALIZADA';
PRINT 'Servidor: ' + @@SERVERNAME;
PRINT '========================================';
PRINT '';
PRINT 'Ahora puedes ejecutar Rep_Productos.sql de nuevo';
PRINT '';
GO
