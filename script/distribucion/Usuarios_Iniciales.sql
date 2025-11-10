-- ============================================================
-- DATOS INICIALES DE USUARIOS DEL SISTEMA
-- ============================================================
-- Este script inserta usuarios iniciales en Application.Users
-- 
-- ROLES:
--   • administrador: Usuario de sucursal (SanJose o Limon)
--   • corporativo:   Usuario del servidor Corporativo
--
-- 🔐 CIFRADO DE CONTRASEÑAS:
--     Se utiliza HASHBYTES('SHA2_512', password) nativo de SQL Server
--     SHA2_512 produce un hash de 64 bytes (irreversible)
--
-- EJECUTAR EN: Los 3 servidores (SanJose, Limon, Corporativo)
-- ============================================================

-- APARTADO SAN JOSE 

USE WWI_SanJose;
GO

CREATE TABLE Application.Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL,      -- SHA2_512 produce 64 bytes
    FullName NVARCHAR(100) NOT NULL,
    Active BIT NOT NULL DEFAULT 1,
    Rol NVARCHAR(20) NOT NULL CHECK (Rol IN ('administrador', 'corporativo')),
    Email NVARCHAR(100) NOT NULL,
    HireDate DATE NOT NULL DEFAULT GETDATE(),
    LastEditedBy INT NOT NULL DEFAULT 1,
    LastEditedWhen DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

PRINT 'Creando usuarios de San José...';
GO

-- Insertar usuarios con contraseñas hasheadas usando SHA2_512
-- Insertar usuarios con contraseñas hasheadas usando SHA2_512
INSERT INTO Application.Users 
(Username, PasswordHash, FullName, Active, Rol, Email, HireDate)
VALUES 
    ('admin.sj', HASHBYTES('SHA2_512', N'prueba1234!'), 'Administrador San José', 1, 'administrador', 'admin.sj@wwi.com', '2023-01-20'),
    ('gerente.sj', HASHBYTES('SHA2_512', N'prueba1234!'), 'Gerente San José', 1, 'administrador', 'gerente.sj@wwi.com', '2023-02-15'),
    ('vendedor1.sj', HASHBYTES('SHA2_512', N'prueba1234!'), 'Vendedor 1 San José', 1, 'administrador', 'vendedor1.sj@wwi.com', '2023-04-01'),
    ('vendedor2.sj', HASHBYTES('SHA2_512', N'prueba1234!'), 'Vendedor 2 San José', 1, 'administrador', 'vendedor2.sj@wwi.com', '2023-05-10');
GO


IF OBJECT_ID('Application.sp_Login') IS NOT NULL
    DROP PROCEDURE Application.sp_Login;
GO

CREATE PROCEDURE Application.sp_Login 
    @Username NVARCHAR(50),
    @Password NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar existencia y estado activo del usuario
    IF NOT EXISTS (
        SELECT 1 
        FROM Application.Users 
        WHERE Username = @Username AND Active = 1
    )
    BEGIN
        THROW 50001, 'Usuario no existe o está inactivo.', 1;
    END

    -- Verificar usuario y contraseña
    IF NOT EXISTS (
        SELECT 1 
        FROM Application.Users 
        WHERE Username = @Username 
          AND PasswordHash = HASHBYTES('SHA2_512', @Password)
          AND Active = 1
    )
    BEGIN
        THROW 50002, 'Contraseña incorrecta.', 1;
    END

    -- Devolver información del usuario autenticado
    SELECT 
        UserID, 
        Username, 
        FullName, 
        Rol
    FROM Application.Users
    WHERE Username = @Username;
END
GO


-- APARTADO LIMON

USE WWI_Limon;
GO

CREATE TABLE Application.Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL,      -- SHA2_512 produce 64 bytes
    FullName NVARCHAR(100) NOT NULL,
    Active BIT NOT NULL DEFAULT 1,
    Rol NVARCHAR(20) NOT NULL CHECK (Rol IN ('administrador', 'corporativo')),
    Email NVARCHAR(100) NOT NULL,
    HireDate DATE NOT NULL DEFAULT GETDATE(),
    LastEditedBy INT NOT NULL DEFAULT 1,
    LastEditedWhen DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

PRINT 'Creando usuarios de Limón...';
GO
-- Insertar usuarios con contraseñas hasheadas usando SHA2_512
INSERT INTO Application.Users
(Username, PasswordHash, FullName, Active, Rol, Email, HireDate)
VALUES 
    ('admin.lm', HASHBYTES('SHA2_512', N'prueba1234!'), 'Administrador Limón', 1, 'administrador', 'admin.lm@wwi.com', '2023-01-20'),
    ('gerente.lm', HASHBYTES('SHA2_512', N'prueba1234!'), 'Gerente Limón', 1, 'administrador', 'gerente.lm@wwi.com', '2023-02-15'),
    ('vendedor1.lm', HASHBYTES('SHA2_512', N'prueba1234!'), 'Vendedor 1 Limón', 1, 'administrador', 'vendedor1.lm@wwi.com', '2023-04-01'),
    ('vendedor2.lm', HASHBYTES('SHA2_512', N'prueba1234!'), 'Vendedor 2 Limón', 1, 'administrador', 'vendedor2.lm@wwi.com', '2023-05-10');
GO

IF OBJECT_ID('Application.sp_Login') IS NOT NULL
    DROP PROCEDURE Application.sp_Login;

GO

CREATE PROCEDURE Application.sp_Login 
    @Username NVARCHAR(50),
    @Password NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar existencia y estado activo del usuario
    IF NOT EXISTS (
        SELECT 1 
        FROM Application.Users 
        WHERE Username = @Username AND Active = 1
    )
    BEGIN
        THROW 50001, 'Usuario no existe o está inactivo.', 1;
    END

    -- Verificar usuario y contraseña
    IF NOT EXISTS (
        SELECT 1 
        FROM Application.Users 
        WHERE Username = @Username 
          AND PasswordHash = HASHBYTES('SHA2_512', @Password)
          AND Active = 1
    )
    BEGIN
        THROW 50002, 'Contraseña incorrecta.', 1;
    END

    -- Devolver información del usuario autenticado
    SELECT 
        UserID, 
        Username, 
        FullName, 
        Rol
    FROM Application.Users
    WHERE Username = @Username;
END
GO

-- APARTADO CORPORATIVO
USE WWI_Corporativo;
GO

CREATE TABLE Application.Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL,      -- SHA2_512 produce 64 bytes
    FullName NVARCHAR(100) NOT NULL,
    Active BIT NOT NULL DEFAULT 1,
    Rol NVARCHAR(20) NOT NULL CHECK (Rol IN ('administrador', 'corporativo')),
    Email NVARCHAR(100) NOT NULL,
    HireDate DATE NOT NULL DEFAULT GETDATE(),
    LastEditedBy INT NOT NULL DEFAULT 1,
    LastEditedWhen DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

PRINT 'Creando usuarios de Corporativo...';
GO
-- Insertar usuarios con contraseñas hasheadas usando SHA2_512
INSERT INTO Application.Users
(Username, PasswordHash, FullName, Active, Rol, Email, HireDate)
VALUES 
    ('admin.corp', HASHBYTES('SHA2_512', N'prueba1234!'), 'Administrador Corporativo', 1, 'corporativo', 'admin.corp@wwi.com', '2023-01-20'),
    ('gerente.corp', HASHBYTES('SHA2_512', N'prueba1234!'), 'Gerente Corporativo', 1, 'corporativo', 'gerente.corp@wwi.com', '2023-02-15'),
    ('analista1.corp', HASHBYTES('SHA2_512', N'prueba1234!'), 'Analista 1 Corporativo', 1, 'corporativo', 'analista1.corp@wwi.com', '2023-03-10');
GO

IF OBJECT_ID('Application.sp_Login') IS NOT NULL
    DROP PROCEDURE Application.sp_Login;
GO

CREATE PROCEDURE Application.sp_Login 
    @Username NVARCHAR(50),
    @Password NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar existencia y estado activo del usuario
    IF NOT EXISTS (
        SELECT 1 
        FROM Application.Users 
        WHERE Username = @Username AND Active = 1
    )
    BEGIN
        THROW 50001, 'Usuario no existe o está inactivo.', 1;
    END

    -- Verificar usuario y contraseña
    IF NOT EXISTS (
        SELECT 1 
        FROM Application.Users 
        WHERE Username = @Username 
          AND PasswordHash = HASHBYTES('SHA2_512', @Password)
          AND Active = 1
    )
    BEGIN
        THROW 50002, 'Contraseña incorrecta.', 1;
    END

    -- Devolver información del usuario autenticado
    SELECT 
        UserID, 
        Username, 
        FullName, 
        Rol
    FROM Application.Users
    WHERE Username = @Username;
END
GO


EXEC Application.sp_Login 
    @Username = 'admin.lm', 
    @Password = N'prueba1234!';
GO

-- ❌ Usuario inactivo o inexistente
EXEC Application.sp_Login 
    @Username = 'noexiste', 
    @Password = N'prueba1234!';
GO

-- ❌ Contraseña incorrecta
EXEC Application.sp_Login 
    @Username = 'admin.lm', 
    @Password = N'malapass';
GO
