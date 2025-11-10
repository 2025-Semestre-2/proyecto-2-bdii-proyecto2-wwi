-- ============================================================
-- MASTER SCRIPT - CONFIGURACIÓN COMPLETA DE REPLICACIÓN
-- ============================================================
-- 📋 INSTRUCCIONES DE USO:
--
-- Este script es una GUÍA del orden de ejecución.
-- NO ejecutar todo de una vez. Seguir el orden indicado.
--
-- PREREQUISITOS:
--   1. Docker containers corriendo (sql_corp, sql_sj, sql_limon)
--   2. Bases de datos creadas:
--      • BD_Corporativo.sql ejecutado en 127.0.0.1,1436
--      • BD_SanJose.sql ejecutado en 127.0.0.1,1437
--      • BD_Limon.sql ejecutado en 127.0.0.1,1435
--   3. Migraciones ejecutadas:
--      • Migracion_Corporativo.sql ejecutado en 127.0.0.1,1436
--      • Migracion_SanJose.sql ejecutado en 127.0.0.1,1437
--      • Migracion_Limon.sql ejecutado en 127.0.0.1,1435
--
-- ============================================================
-- ORDEN DE EJECUCIÓN
-- ============================================================
--
-- PASO 0: LIMPIEZA (si necesitas reiniciar)
-- -----------------------------------------
-- Ejecutar en 127.0.0.1,1436 (CORPORATIVO):
--   script: CLEANUP_Full_Replication.sql
--
-- Ejecutar en 127.0.0.1,1437 (SANJOSE):
--   script: CLEANUP_Full_Replication.sql
--
-- Ejecutar en 127.0.0.1,1435 (LIMON):
--   script: CLEANUP_Full_Replication.sql
--
-- ⚠️  Después de cleanup, recrear las bases de datos (BD_*.sql)
--     y ejecutar las migraciones (Migracion_*.sql)
--
-- ============================================================
--
-- PASO 1: REPLICACIÓN DE PRODUCTOS (Bidireccional Hub-and-Spoke)
-- ---------------------------------------------------------------
-- Ejecutar en 127.0.0.1,1437 (SANJOSE):
--   script: 1_SanJose_Productos.sql
--   • Configura distribuidor
--   • Crea publicación Pub_Productos_SJ_to_CORP
--   • Registra linked server a CORP
--   • Crea suscripción para CORP
--
-- Ejecutar en 127.0.0.1,1436 (CORPORATIVO):
--   script: 2_Corporativo_Productos.sql
--   • Configura distribuidor
--   • Crea publicaciones:
--     - Pub_Productos_CORP_to_Limon
--     - Pub_Productos_CORP_to_SJ
--   • Registra linked servers a SJ y Limon
--   • Crea suscripciones para Limon y SJ
--
-- Ejecutar en 127.0.0.1,1435 (LIMON):
--   script: 3_Limon_Productos.sql
--   • Configura distribuidor
--   • Crea publicación Pub_Productos_Limon_to_CORP
--   • Registra linked server a CORP
--   • Crea suscripción para CORP
--
-- VERIFICACIÓN:
--   Insertar producto en SanJose y verificar en CORP y Limon
--   Insertar producto en Limon y verificar en CORP y SanJose
--
-- ============================================================
--
-- PASO 2: REPLICACIÓN OPERACIONAL (Unidireccional Sucursal→CORP)
-- ----------------------------------------------------------------
-- Ejecutar en 127.0.0.1,1437 (SANJOSE):
--   script: 4_SanJose_PropiasSuc.sql
--   • Crea publicación Pub_PropiasSJ_to_CORP
--   • Artículos:
--     - Holdings_SJ
--     - StockItemTransactions_SJ
--     - Invoices_SJ
--     - InvoiceLines_SJ
--     - PurchaseOrders_SJ
--     - PurchaseOrderLines_SJ
--   • Crea suscripción para CORP
--
-- Ejecutar en 127.0.0.1,1435 (LIMON):
--   script: 5_Limon_PropiasSuc.sql
--   • Crea publicación Pub_PropiasLimon_to_CORP
--   • Artículos:
--     - Holdings_Limon
--     - StockItemTransactions_Limon
--     - Invoices_Limon
--     - InvoiceLines_Limon
--     - PurchaseOrders_Limon
--     - PurchaseOrderLines_Limon
--   • Crea suscripción para CORP
--
-- ============================================================
--
-- PASO 3: ⚠️  FIX CRITICAL - IDENTITY INSERT (OBLIGATORIO)
-- ---------------------------------------------------------
-- Ejecutar en 127.0.0.1,1436 (CORPORATIVO):
--   script: 6_Fix_Identity_SPs_ALWAYS.sql
--   
--   • Modifica 10 stored procedures auto-generados
--   • Agrega SET IDENTITY_INSERT ON/OFF
--   • Afecta tablas con columnas IDENTITY:
--     - StockItemTransactions (SJ y Limon)
--     - Invoices (SJ y Limon)
--     - InvoiceLines (SJ y Limon)
--     - PurchaseOrders (SJ y Limon)
--     - PurchaseOrderLines (SJ y Limon)
--
-- ⚠️  CRÍTICO: Este paso es OBLIGATORIO cada vez que configures
--     la replicación desde cero. SQL Server no incluye
--     SET IDENTITY_INSERT en los SPs auto-generados cuando
--     usas @sync_type = 'replication support only'.
--
-- ============================================================
--
-- PASO 4: REINICIAR DISTRIBUTION AGENTS
-- --------------------------------------
-- Ejecutar en 127.0.0.1,1436 (CORPORATIVO):
--
-- Para SanJose:
-- EXEC msdb.dbo.sp_start_job 
--   @job_name = N'sql_sj-WWI_SanJose-Pub_PropiasSJ_to_CORP-sql_corp-2';
--
-- Para Limon:
-- EXEC msdb.dbo.sp_start_job 
--   @job_name = N'sql_limon-WWI_Limon-Pub_PropiasLimon_to_C-sql_corp-2';
--
-- ============================================================
--
-- PASO 5: VERIFICACIÓN COMPLETA
-- ------------------------------
-- 
-- A. Productos (bidireccional):
--    • Insertar en SanJose → verificar en CORP y Limon
--    • Insertar en Limon → verificar en CORP y SanJose
--
-- B. Holdings (sin IDENTITY):
--    • Insertar en SanJose → verificar en CORP
--    • Actualizar en SanJose → verificar en CORP
--    • Insertar en Limon → verificar en CORP
--
-- C. Transacciones (con IDENTITY):
--    • Insertar en SanJose con ID explícito → verificar en CORP
--    • Insertar en Limon con ID explícito → verificar en CORP
--
-- D. Facturas (con IDENTITY):
--    • Insertar Invoice+Lines en SanJose → verificar en CORP
--    • Insertar Invoice+Lines en Limon → verificar en CORP
--
-- E. Órdenes de Compra (con IDENTITY):
--    • Insertar PO+Lines en SanJose → verificar en CORP
--    • Insertar PO+Lines en Limon → verificar en CORP
--
-- ============================================================
--
-- COMANDOS ÚTILES DE DIAGNÓSTICO
-- ===============================
--
-- Ver jobs de replicación:
USE msdb;
SELECT job_id, name, enabled, date_created
FROM dbo.sysjobs
WHERE name LIKE '%Pub_%'
ORDER BY name;
GO

-- Ver historial de un job:
SELECT TOP 20
    sj.name AS JobName,
    h.run_date,
    h.run_time,
    h.step_id,
    h.step_name,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
    END AS Status,
    h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs sj ON h.job_id = sj.job_id
WHERE sj.name LIKE '%Pub_%'
ORDER BY h.run_date DESC, h.run_time DESC;
GO

-- Ver publicaciones:
USE WWI_SanJose; -- o WWI_Corporativo, WWI_Limon
EXEC sp_helppublication;
GO

-- Ver suscripciones:
USE WWI_Corporativo; -- o WWI_SanJose, WWI_Limon
EXEC sp_helpsubscription;
GO

-- Ver artículos de una publicación:
USE WWI_SanJose; -- o WWI_Corporativo, WWI_Limon
EXEC sp_helparticle @publication = N'Pub_Productos_SJ_to_CORP'; -- cambiar nombre
GO

-- Ver linked servers:
SELECT name, data_source, provider
FROM sys.servers
WHERE is_linked = 1;
GO

-- Ver stored procedures de replicación:
USE WWI_Corporativo;
SELECT 
    name,
    create_date,
    modify_date,
    CASE 
        WHEN OBJECT_DEFINITION(object_id) LIKE '%SET IDENTITY_INSERT%ON%' 
        THEN 'Has IDENTITY_INSERT'
        ELSE 'No IDENTITY_INSERT'
    END AS IdentityStatus
FROM sys.procedures
WHERE name LIKE 'sp_MSins_%'
ORDER BY name;
GO

-- ============================================================
-- TROUBLESHOOTING
-- ===============
--
-- ❌ Error: "Cannot insert explicit value for identity column"
-- Solución: Ejecutar 6_Fix_Identity_SPs_ALWAYS.sql
--
-- ❌ Error: "Could not find stored procedure 'sp_MSins_...'"
-- Solución: La publicación no se creó correctamente. Revisar
--           paso 2 (4_SanJose_PropiasSuc.sql o 5_Limon_PropiasSuc.sql)
--
-- ❌ Error: "The subscription does not exist"
-- Solución: Recrear la suscripción desde el script correspondiente
--
-- ❌ Error: "Could not connect to server 'sql_corp'"
-- Solución: Verificar linked servers con:
--           SELECT * FROM sys.servers WHERE is_linked = 1;
--           Recrear linked server si es necesario
--
-- ❌ Replicación lenta o no funciona
-- Solución 1: Verificar que SQL Server Agent está corriendo:
--             EXEC msdb.dbo.sp_help_jobactivity;
-- Solución 2: Reiniciar distribution agents (ver PASO 4)
-- Solución 3: Revisar logs de los jobs (comando arriba)
--
-- ❌ Necesito limpiar TODO y empezar de nuevo
-- Solución: 
--   1. Ejecutar CLEANUP_Full_Replication.sql en los 3 servers
--   2. Recrear bases de datos (BD_*.sql en los 3 servers)
--   3. Ejecutar migraciones (Migracion_*.sql en los 3 servers)
--   4. Seguir ORDEN DE EJECUCIÓN desde PASO 1
--
-- ============================================================
-- DOCUMENTACIÓN TÉCNICA
-- ======================
--
-- 🔧 sync_type = 'replication support only'
--    • NO crea snapshots iniciales
--    • Requiere datos IDÉNTICOS en publisher y subscriber
--    • Replica solo cambios FUTUROS (INSERT/UPDATE/DELETE)
--    • Ventaja: No bloquea tablas ni consume espacio en disco
--    • Desventaja: SQL Server no genera SET IDENTITY_INSERT
--
-- 🔧 schema_option = 0x0000000008835DFF
--    • Incluye bit 0x08 para replicar columnas IDENTITY
--    • Incluye índices, constraints, triggers, etc.
--    • PERO: No fuerza SET IDENTITY_INSERT en los SPs
--
-- 🔧 pre_creation_cmd
--    • 'truncate': Para replicación bidireccional (productos)
--    • 'drop': Para replicación unidireccional (operacional)
--
-- 🔧 Linked Servers
--    • Usan hostnames de Docker: sql_corp, sql_sj, sql_limon
--    • IPs: 172.18.0.2 (corp), 172.18.0.4 (sj), 172.18.0.3 (limon)
--    • Necesarios para que replicación funcione correctamente
--
-- ============================================================
-- FIN DEL MASTER SCRIPT
-- ============================================================

PRINT '════════════════════════════════════════════════════════';
PRINT '📚 MASTER SCRIPT - GUÍA DE CONFIGURACIÓN';
PRINT '════════════════════════════════════════════════════════';
PRINT '';
PRINT 'Este es un script de REFERENCIA.';
PRINT 'Lee los comentarios y ejecuta los scripts en el ORDEN indicado.';
PRINT '';
PRINT '✅ RESUMEN DEL PROCESO:';
PRINT '   0. Cleanup (si reinicia)';
PRINT '   1-3. Configurar replicación de productos (bidireccional)';
PRINT '   4-5. Configurar replicación operacional (unidireccional)';
PRINT '   6. ⚠️  FIX OBLIGATORIO de IDENTITY SPs';
PRINT '   7. Reiniciar distribution agents';
PRINT '   8. Verificar funcionamiento';
PRINT '';
PRINT '📖 Lee los comentarios completos arriba para detalles.';
PRINT '════════════════════════════════════════════════════════';
GO
