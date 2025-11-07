-- ============================================================
-- SCRIPT 1: CREACIÓN DE LAS 3 BASES DE DATOS
-- ============================================================
-- Base del proyecto: WideWorldImporters
-- 
-- ARQUITECTURA DISTRIBUIDA:
-- 1. BD_Corporativo: Plaza Roble, Escazú (Datos sensibles + Catálogos maestros)
-- 2. BD_SanJose: Sucursal San José (Inventario + Ventas propias)
-- 3. BD_Limon: Sucursal Limón (Inventario + Ventas propias)
-- ============================================================

USE master;
GO

-- Eliminar bases de datos si existen (para desarrollo)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BD_Corporativo')
BEGIN
    ALTER DATABASE BD_Corporativo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_Corporativo;
END
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BD_SanJose')
BEGIN
    ALTER DATABASE BD_SanJose SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_SanJose;
END
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BD_Limon')
BEGIN
    ALTER DATABASE BD_Limon SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_Limon;
END
GO

-- Crear Base de Datos Corporativa
CREATE DATABASE BD_Corporativo;
GO

PRINT 'Base de datos BD_Corporativo creada exitosamente';
GO

-- Crear Base de Datos Sucursal San José
CREATE DATABASE BD_SanJose;
GO

PRINT 'Base de datos BD_SanJose creada exitosamente';
GO

-- Crear Base de Datos Sucursal Limón
CREATE DATABASE BD_Limon;
GO

PRINT 'Base de datos BD_Limon creada exitosamente';
GO

PRINT '=================================================';
PRINT 'TODAS LAS BASES DE DATOS CREADAS EXITOSAMENTE';
PRINT '=================================================';
