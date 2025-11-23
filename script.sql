-- EJECUTAR PRIMERO datagen.py PARA GENERAR DATOS!!!

USE master;
GO

IF DB_ID(N'Gym_DB') IS NOT NULL
BEGIN
    ALTER DATABASE Gym_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Gym_DB;
    DROP LOGIN admin_general_lg;
    DROP LOGIN manager_membership_lg;
    DROP LOGIN manager_payments_lg;
    DROP LOGIN manager_trainers_lg;
    DROP LOGIN manager_receptionist_lg;
    DROP LOGIN manager_auditor_lg;
END
GO

PRINT 'Creando base de datos...';

CREATE DATABASE Gym_DB
ON PRIMARY(
    NAME = gym_db_data,
    FILENAME = 'C:\SQL_Backups\gym_db_data.mdf',
    SIZE = 50MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 100MB
)
LOG ON (
    NAME = gym_db_logs,
    FILENAME = 'C:\SQL_Backups\gym_db_logs.ldf',
    SIZE = 50MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 100MB
);
GO

USE Gym_DB;
GO

-- CREACION DE TABLAS

-- Creacion de tabla de socio
CREATE TABLE member (
    member_id INT IDENTITY(1,1) PRIMARY KEY,
    member_code VARCHAR(15) NOT NULL UNIQUE,
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    identity_document VARCHAR(15) NULL UNIQUE,
    birth_date DATE NULL,
    phone VARCHAR(15) NULL,
    email VARCHAR(80) NULL,
    registration_date DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Creacion de tabla de tipo de membresia
CREATE TABLE membership_type (
    membership_type_id TINYINT IDENTITY(1,1) PRIMARY KEY,
    type_name VARCHAR(40) NOT NULL,
    description VARCHAR(150) NULL,
    duration_months TINYINT NOT NULL,
    price DECIMAL(8,2) NOT NULL,
    is_unlimited BIT NOT NULL DEFAULT 0,
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Creacion de tabla que asocia la membresia con el socio
CREATE TABLE member_membership (
    member_membership_id INT IDENTITY(1,1) PRIMARY KEY,
    member_id INT NOT NULL,
    membership_type_id TINYINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT fk_member_membership_member FOREIGN KEY (member_id) REFERENCES member(member_id),
    CONSTRAINT fk_member_membership_membership_type FOREIGN KEY (membership_type_id) REFERENCES membership_type(membership_type_id)
);
GO

-- Creacion de tabla de entrenador
CREATE TABLE trainer (
    trainer_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    specialty NVARCHAR(80) NULL,
    phone VARCHAR(15) NULL,
    email VARCHAR(80) NULL,
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Creacion de tabla sala
CREATE TABLE room (
    room_id INT IDENTITY(1,1) PRIMARY KEY,
    room_name VARCHAR(40) NOT NULL,
    capacity SMALLINT NOT NULL,
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Creacion de tabla de clase
CREATE TABLE class (
    class_id INT IDENTITY(1,1) PRIMARY KEY,
    class_name VARCHAR(60) NOT NULL,
    description VARCHAR(150) NULL,
    class_type VARCHAR(15) NOT NULL, -- Group / Personal
    duration_minutes SMALLINT NOT NULL,
    max_capacity SMALLINT NULL
);
GO

-- Creacion de tabla de horario de clases
CREATE TABLE class_schedule (
    class_schedule_id INT IDENTITY(1,1) PRIMARY KEY,
    class_id INT NOT NULL,
    trainer_id INT NOT NULL,
    room_id INT NOT NULL,
    start_datetime DATETIME2 NOT NULL,
    end_datetime DATETIME2 NOT NULL,
    max_capacity SMALLINT NULL,
    CONSTRAINT fk_class_schedule_class FOREIGN KEY (class_id) REFERENCES class(class_id),
    CONSTRAINT fk_class_schedule_trainer FOREIGN KEY (trainer_id) REFERENCES trainer(trainer_id),
    CONSTRAINT fk_class_schedule_room FOREIGN KEY (room_id) REFERENCES room(room_id)
);
GO

-- Creacion de tabla de disponibilidad de un entrenador
CREATE TABLE availability_trainer (
    availability_id INT IDENTITY(1,1) PRIMARY KEY,
    trainer_id INT NOT NULL,
    day_of_week TINYINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT fk_availability_trainer FOREIGN KEY (trainer_id) REFERENCES trainer(trainer_id)
);
GO

-- Creacion de tabla de reservacion
CREATE TABLE reservation (
    reservation_id INT IDENTITY(1,1) PRIMARY KEY,
    member_id INT NOT NULL,
    class_schedule_id INT NOT NULL,
    reservation_date DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    reservation_status VARCHAR(15) NOT NULL DEFAULT 'Reserved', 
    attended BIT NOT NULL DEFAULT 0,
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) REFERENCES member(member_id),
    CONSTRAINT fk_reservation_class_schedule FOREIGN KEY (class_schedule_id) REFERENCES class_schedule(class_schedule_id),
    CONSTRAINT uq_reservation_member_schedule UNIQUE (member_id, class_schedule_id)
);
GO

-- Creacion de tabla de metodos de pago
CREATE TABLE payment_method (
    payment_method_id TINYINT IDENTITY(1,1) PRIMARY KEY,
    method_name VARCHAR(25) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1
);
GO

-- Creacion de tabla pagos
CREATE TABLE payment (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    member_id INT NOT NULL,
    member_membership_id INT NULL,
    payment_method_id TINYINT NOT NULL,
    payment_date DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    amount DECIMAL(8,2) NOT NULL,
    period_start DATE NULL,
    period_end DATE NULL,
    reference VARCHAR(80) NULL,
    CONSTRAINT fk_payment_member FOREIGN KEY (member_id) REFERENCES member(member_id),
    CONSTRAINT fk_payment_member_membership FOREIGN KEY (member_membership_id) REFERENCES member_membership(member_membership_id),
    CONSTRAINT fk_payment_payment_method FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id)
);
GO

-- CREACION DE LOGINS, USUARIOS Y ROLES

PRINT 'Configurando seguridad...';

-- Creacion de logins
-- 1-Administrador general de la DB.
-- 2-Login para manejador socios.
-- 3-login para manejador de entrenadores.
-- 4-login para manejador de pagos.
-- 5-login para manejador de reservas de clases.
-- 6-login para manejador de auditorias.
CREATE LOGIN admin_general_lg WITH PASSWORD = 'admin_1234!', CHECK_POLICY = ON;
CREATE LOGIN manager_membership_lg WITH PASSWORD = 'manager_1234!', CHECK_POLICY = ON;
CREATE LOGIN manager_payments_lg WITH PASSWORD = 'manager_1234!', CHECK_POLICY = ON;
CREATE LOGIN manager_trainers_lg WITH PASSWORD = 'manager_1234!', CHECK_POLICY = ON;
CREATE LOGIN manager_receptionist_lg WITH PASSWORD = 'manager_1234!', CHECK_POLICY = ON;
CREATE LOGIN manager_auditor_lg WITH PASSWORD = 'manager_1234!', CHECK_POLICY = ON;

--Roles del sistema:
-- 1-Administrador general. 
-- 2-Encargado de socios.
-- 3-Encargado de pagos
-- 4-Encargado de entrenadores
-- 5-Recepcionista (ver informacion de reservas de clases)
-- 6-Auditor
CREATE ROLE general_manager_rol;
CREATE ROLE membership_manager_rol;
CREATE ROLE payment_manager_rol;
CREATE ROLE trainer_manager_rol;
CREATE ROLE receptionist_rol;
CREATE ROLE auditor_rol;

-- Creacion de usuarios
CREATE USER admin_general_gym_user FOR LOGIN admin_general_lg;
CREATE USER membership_manager_user FOR LOGIN manager_membership_lg;
CREATE USER payment_manager_user FOR LOGIN manager_payments_lg;
CREATE USER trainer_manager_user FOR LOGIN manager_trainers_lg;
CREATE USER receptionist_manager_user FOR LOGIN manager_receptionist_lg;
CREATE USER auditor_user FOR LOGIN manager_auditor_lg;

-- Asignacion de usuarios a roles
ALTER ROLE general_manager_rol ADD MEMBER admin_general_gym_user;
ALTER ROLE membership_manager_rol ADD MEMBER membership_manager_user;
ALTER ROLE payment_manager_rol ADD MEMBER payment_manager_user;
ALTER ROLE trainer_manager_rol ADD MEMBER trainer_manager_user;
ALTER ROLE receptionist_rol ADD MEMBER receptionist_manager_user;
ALTER ROLE auditor_rol ADD MEMBER auditor_user;

-- ASIGNACION DE PERMISOS

-- Admin
GRANT CONTROL ON DATABASE::Gym_DB TO general_manager_rol;

-- Membership Manager
GRANT SELECT, INSERT, UPDATE ON dbo.member TO membership_manager_rol;
GRANT SELECT, INSERT, UPDATE ON dbo.member_membership TO membership_manager_rol;
GRANT SELECT ON dbo.membership_type TO membership_manager_rol;

-- Payment Manager
GRANT SELECT, INSERT, UPDATE ON dbo.payment TO payment_manager_rol;
GRANT SELECT ON dbo.payment_method TO payment_manager_rol;

-- Trainer Manager
GRANT SELECT ON dbo.class TO trainer_manager_rol;
GRANT SELECT ON dbo.class_schedule TO trainer_manager_rol;
GRANT SELECT ON dbo.member TO trainer_manager_rol;
GRANT SELECT, UPDATE ON dbo.reservation TO trainer_manager_rol; 

-- Receptionist
GRANT SELECT ON dbo.member TO receptionist_rol;
GRANT SELECT ON dbo.class TO receptionist_rol;
GRANT SELECT ON dbo.class_schedule TO receptionist_rol;
GRANT SELECT ON dbo.room TO receptionist_rol;
GRANT INSERT, UPDATE ON dbo.reservation TO receptionist_rol;

-- Auditor
GRANT SELECT ON SCHEMA::dbo TO auditor_rol;
-- IMPORTACIÓN DE DATOS

PRINT 'Preparando entorno de migración...';
USE Gym_DB;
GO

CREATE OR ALTER PROCEDURE usp_ImportarCSV
    @Tabla NVARCHAR(128),
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Identity NVARCHAR(100) = '';
    
    -- Verificar si la tabla tiene columna IDENTITY
    IF EXISTS (
        SELECT 1 
        FROM sys.identity_columns 
        WHERE object_id = OBJECT_ID(@Tabla)
    )
    BEGIN
        SET @Identity = ', KEEPIDENTITY';
    END

    BEGIN TRY
        PRINT 'Iniciando importación para la tabla: ' + @Tabla;
        -- Construir el BULK INSERT
        SET @SQL = 
            'BULK INSERT ' + @Tabla + 
            ' FROM ''' + @RutaArchivo + ''' ' +
            ' WITH (
                FORMAT = ''CSV'', 
                FIELDTERMINATOR = '','', 
                ROWTERMINATOR = ''0x0a'', 
                FIRSTROW = 2,
                CODEPAGE = ''65001''' + -- UTF-8 para manejar acentos y eñes
                @Identity +
            ' );';

        -- Ejecutar la consulta dinámica
        EXEC sp_executesql @SQL;

        PRINT 'Importación completada exitosamente para: ' + @Tabla;
        
    END TRY
    BEGIN CATCH
        PRINT 'Error al importar la tabla ' + @Tabla;
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

PRINT '
INICIANDO CARGA MASIVA DE DATOS
';

-- Orden de importación importante por las FK

-- Tablas independientes
EXEC usp_ImportarCSV @Tabla = 'membership_type', @RutaArchivo = 'C:\SQL_Backups\DataImport\membership_type.csv';
EXEC usp_ImportarCSV @Tabla = 'payment_method', @RutaArchivo = 'C:\SQL_Backups\DataImport\payment_method.csv';
EXEC usp_ImportarCSV @Tabla = 'room', @RutaArchivo = 'C:\SQL_Backups\DataImport\room.csv';
EXEC usp_ImportarCSV @Tabla = 'trainer', @RutaArchivo = 'C:\SQL_Backups\DataImport\trainer.csv';
EXEC usp_ImportarCSV @Tabla = 'class', @RutaArchivo = 'C:\SQL_Backups\DataImport\class.csv';
EXEC usp_ImportarCSV @Tabla = 'member', @RutaArchivo = 'C:\SQL_Backups\DataImport\member.csv';

-- Tablas dependientes
EXEC usp_ImportarCSV @Tabla = 'member_membership', @RutaArchivo = 'C:\SQL_Backups\DataImport\member_membership.csv';
EXEC usp_ImportarCSV @Tabla = 'class_schedule', @RutaArchivo = 'C:\SQL_Backups\DataImport\class_schedule.csv';
EXEC usp_ImportarCSV @Tabla = 'reservation', @RutaArchivo = 'C:\SQL_Backups\DataImport\reservation.csv';
EXEC usp_ImportarCSV @Tabla = 'payment', @RutaArchivo = 'C:\SQL_Backups\DataImport\payment.csv';

PRINT '
CARGA FINALIZADA
';
GO