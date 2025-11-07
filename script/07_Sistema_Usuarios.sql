-- ============================================================
-- SCRIPT: SISTEMA DE USUARIOS (SIMPLE)
-- ============================================================
-- Tabla de usuarios centralizada en BD_Corporativo
-- Login básico
-- ============================================================

USE BD_Corporativo;
GO
PRINT '=================================================';
PRINT 'CREANDO SISTEMA DE USUARIOS';
PRINT '=================================================';
PRINT '';

-- ============================================================
-- TABLA DE USUARIOS
-- ============================================================

CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    Active BIT NOT NULL DEFAULT 1,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Administrador', 'Corporativo')),
    HireDate DATE NOT NULL DEFAULT GETDATE()
);
GO

PRINT 'Tabla Users creada exitosamente';
GO

-- ============================================================
-- STORED PROCEDURE: LOGIN
-- ============================================================

CREATE PROCEDURE SP_Login
    @Username NVARCHAR(50),
    @Password NVARCHAR(255),
    @Branch NVARCHAR(20) = NULL  -- 'SanJose', 'Limon', 'Corporativo'
AS
BEGIN
    if not exists (
        select 1 from Users 
        where Username = @Username 
          and Password = @Password
          and Active = 1
    ) begin
        raiserror('Credenciales inválidas o usuario inactivo.', 16, 1);
        return;
    end

    -- Retornar información del usuario
    select 
        UserID,
        Username,
        FullName,
        Email,
        Role,
        HireDate
    from Users
    where Username = @Username and Password = @Password and Active = 1;
END;

PRINT 'Procedimiento SP_Login creado exitosamente';
GO

-- ============================================================
-- STORED PROCEDURE: OBTENER TODOS LOS USUARIOS
-- ============================================================

CREATE PROCEDURE SP_GetAllUsers
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        UserID,
        Username,
        FullName,
        Email,
        Active,
        Role,
        HireDate
    FROM Users
    ORDER BY FullName;
END;
GO

PRINT 'Procedimiento SP_GetAllUsers creado exitosamente';
GO

-- ============================================================
-- STORED PROCEDURE: OBTENER USUARIO POR ID
-- ============================================================

CREATE PROCEDURE SP_GetUserByID
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        UserID,
        Username,
        FullName,
        Email,
        Active,
        Role,
        HireDate
    FROM Users
    WHERE UserID = @UserID;
END;
GO

PRINT 'Procedimiento SP_GetUserByID creado exitosamente';
GO

-- ============================================================
-- DATOS DE EJEMPLO
-- ============================================================

INSERT INTO Users (Username, Password, FullName, Email, Role, HireDate)
VALUES 
    ('admin.sj', '1234', 'Admin San José', 'admin.sj@empresa.com', 'Administrador', '2024-02-01'),
    ('admin.limon', '1234', 'Admin Limón', 'admin.limon@empresa.com', 'Administrador', '2024-02-01'),
    ('corporativo', '1234', 'Usuario Corporativo', 'corporativo@empresa.com', 'Corporativo', '2024-01-15'),
    ('gerencia', '1234', 'Gerencia General', 'gerencia@empresa.com', 'Corporativo', '2024-01-01');

PRINT '';
PRINT 'Usuarios de ejemplo insertados:';
PRINT '  - admin.sj / 1234 (Administrador San José)';
PRINT '  - admin.limon / 1234 (Administrador Limón)';
PRINT '  - corporativo / 1234 (Corporativo)';
PRINT '  - gerencia / 1234 (Corporativo)';
GO

PRINT '=================================================';
PRINT 'SISTEMA DE USUARIOS CONFIGURADO EXITOSAMENTE';
PRINT '=================================================';