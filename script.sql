IF DB_ID(N'Gym_DB') IS NULL
BEGIN 
    PRINT 'Creating database...';

    CREATE DATABASE Gym_DB
    ON PRIMARY(
        NAME = gym_db_data,
        FILENAME = '$(system_data_path)\gym_db_data.mdf',
        SIZE = 50MB,
        MAXSIZE = 500MB,
        FILEGROWTH = 100MB
    )
    LOG ON (
        NAME = gym_db_logs,
        FILENAME = '$(system_log_path)\gym_db_logs.ldf',
        SIZE = 50MB,
        MAXSIZE = 500MB,
        FILEGROWTH = 100MB
    );
END
GO

USE Gym_DB;
GO

--Creacion de tabla de socio
IF OBJECT_ID('member', 'U') IS NULL
BEGIN
    CREATE TABLE member (
        member_id INT IDENTITY(1,1) PRIMARY KEY,
        member_code VARCHAR(15) NOT NULL UNIQUE,
        first_name NVARCHAR(50) NOT NULL,
        last_name NVARCHAR(50) NOT NULL,
        identity_document VARCHAR(15) NULL,
        birth_date DATE NULL,
        phone VARCHAR(15) NULL,
        email VARCHAR(80) NULL,
        registration_date DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
        is_active BIT NOT NULL DEFAULT 1
    );
END
GO

--Creacion de tabla de tipo de membresia
IF OBJECT_ID('membership_type', 'U') IS NULL
BEGIN
    CREATE TABLE membership_type (
        membership_type_id TINYINT IDENTITY(1,1) PRIMARY KEY,
        type_name VARCHAR(40) NOT NULL,
        description VARCHAR(150) NULL,
        duration_months TINYINT NOT NULL,
        monthly_price DECIMAL(8,2) NOT NULL,
        is_unlimited BIT NOT NULL DEFAULT 0,
        is_active BIT NOT NULL DEFAULT 1
    );
END
GO

--Creacion de tabla que asocia la membresia con el socio
IF OBJECT_ID('member_membership', 'U') IS NULL
BEGIN
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
END
GO

--Creacion de tabla de entrenador
IF OBJECT_ID('trainer', 'U') IS NULL
BEGIN
    CREATE TABLE trainer (
        trainer_id INT IDENTITY(1,1) PRIMARY KEY,
        first_name NVARCHAR(50) NOT NULL,
        last_name NVARCHAR(50) NOT NULL,
        specialty NVARCHAR(80) NULL,
        phone VARCHAR(15) NULL,
        email VARCHAR(80) NULL,
        is_active BIT NOT NULL DEFAULT 1
    );
END
GO

--Creacion de tabla sala(para entrenamiento)
IF OBJECT_ID('room', 'U') IS NULL
BEGIN
    CREATE TABLE room (
        room_id INT IDENTITY(1,1) PRIMARY KEY,
        room_name VARCHAR(40) NOT NULL,
        capacity SMALLINT NOT NULL,
        is_active BIT NOT NULL DEFAULT 1
    );
END
GO

--Creacion de tabla de clase(entrenamiento)
IF OBJECT_ID('class', 'U') IS NULL
BEGIN
    CREATE TABLE class (
        class_id INT IDENTITY(1,1) PRIMARY KEY,
        class_name VARCHAR(60) NOT NULL,
        description VARCHAR(150) NULL,
        class_type VARCHAR(15) NOT NULL, -- Group / Personal
        duration_minutes SMALLINT NOT NULL,
        max_capacity SMALLINT NULL
    );
END
GO

--Creacion de tabla de horario de clases(entrenamiento)
IF OBJECT_ID('class_schedule', 'U') IS NULL
BEGIN
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
END
GO

--Creacion de tabla de disponibilidad de un entrenador(horarios de trabajo)
IF OBJECT_ID('availability_trainer', 'U') IS NULL
BEGIN
    CREATE TABLE availability_trainer (
        availability_id INT IDENTITY(1,1) PRIMARY KEY,
        trainer_id INT NOT NULL,
        day_of_week TINYINT NOT NULL, 
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        CONSTRAINT fk_availability_trainer FOREIGN KEY (trainer_id) REFERENCES trainer(trainer_id)
    );
END
GO

--Creacion de tabla de reservacion de clase para un socio
IF OBJECT_ID('reservation', 'U') IS NULL
BEGIN
    CREATE TABLE reservation (
        reservation_id INT IDENTITY(1,1) PRIMARY KEY,
        member_id INT NOT NULL,
        class_schedule_id INT NOT NULL,
        reservation_date DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
        reservation_status VARCHAR(15) NOT NULL DEFAULT 'Reserved', -- Reserved / Cancelled
        attended BIT NOT NULL DEFAULT 0,
        CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) REFERENCES member(member_id),
        CONSTRAINT fk_reservation_class_schedule FOREIGN KEY (class_schedule_id) REFERENCES class_schedule(class_schedule_id),
        CONSTRAINT uq_reservation_member_schedule UNIQUE (member_id, class_schedule_id)
    );
END
GO

--Creacion de tabla de metodos de pago
IF OBJECT_ID('payment_method', 'U') IS NULL
BEGIN
    CREATE TABLE payment_method (
        payment_method_id TINYINT IDENTITY(1,1) PRIMARY KEY,
        method_name VARCHAR(25) NOT NULL,
        is_active BIT NOT NULL DEFAULT 1
    );
END
GO
--Creacion de tabla pagos
IF OBJECT_ID('payment', 'U') IS NULL
BEGIN 
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
END
GO

------------------------------------------------------------------------
-- Creacion de Usuarios, roles, permisos y politicas de privacidad -----
------------------------------------------------------------------------

-- Creacion de logins
-- 1-Administrador general de la DB.
-- 2-Login para manejador socios.
-- 3-login para manejador de entrenadores.
-- 4-login para manejador de pagos.
-- 5-login para manejador de reservas de clases.
-- 6-login para manejador de auditorias.
CREATE LOGIN admin_general_lg WITH PASSWORD = 'admin_1234!', CHECK_POLICY = ON;
CREATE LOGIN manager_membership_lg WITH PASSWORD = '', CHECK_POLICY = ON;
CREATE LOGIN manager_payments_lg WITH PASSWORD = '', CHECK_POLICY = ON;
CREATE LOGIN manager_trainers_lg WITH PASSWORD = '', CHECK_POLICY = ON;
CREATE LOGIN manager_receptionist_lg WITH PASSWORD = '', CHECK_POLICY = ON;
CREATE LOGIN manager_auditor_lg WITH PASSWORD = '', CHECK_POLICY = ON;

--Roles del sistema:
-- 1-Administrador general. 
-- 2-Encargado de socios.
-- 3-Encargado de pagos
-- 4-Encargado de entrenadores
-- 5-Recepcionista (ver informacion de reservas de clases)
-- 6-Auditor
CREATE ROLE general_manager_rol; -- 1.
CREATE ROLE membership_manager_rol; -- 2.
CREATE ROLE payment_manager_rol; -- 3.
CREATE ROLE trainer_manager_rol; -- 4.
CREATE ROLE receptionist_rol; -- 5.
CREATE ROLE auditor_rol; -- 6.

--Creacion de usuarios
CREATE USER admin_general_gym_user FOR admin_general_lg;
CREATE USER membership_manager_user FOR manager_membership_lg;
CREATE USER payment_manager_user FOR manager_payments_lg;
CREATE USER trainer_manager_user FOR manager_trainers_lg;
CREATE USER receptionist_manager_user FOR manager_receptionist_lg;
CREATE USER auditor_user FOR manager_auditor_lg;

-- Asignacion de usuarios a sus roles
EXEC sp_addrolemember 'general_manager_rol', 'admin_general_gym_user';
EXEC sp_addrolemember 'membership_manager_rol','membership_manager_user';
EXEC sp_addrolemember 'payment_manager_rol','payment_manager_user';
EXEC sp_addrolemember 'trainer_manager_rol','trainer_manager_user';
EXEC sp_addrolemember 'receptionist_rol','receptionist_manager_user';
EXEC sp_addrolemember 'auditor_rol','auditor_user';

--Asignacion de roles para superusuarios(administradores)
GRANT CONTROL ON DATABASE::Gym_DB TO general_manager_rol;

--Asignacion de permisos a roles de socios, membresias
GRANT SELECT, INSERT, UPDATE ON dbo.member TO membership_manager_rol;
GRANT SELECT, INSERT, UPDATE ON dbo.member_membership TO membership_manager_rol;
GRANT SELECT ON dbo.membership_type TO membership_manager_rol;

--Asignacion de permisos a roles de manejo de pagos
GRANT SELECT, INSERT, UPDATE ON dbo.payments TO payment_manager_rol;
GRANT SELECT ON dbo.payment_method TO payment_manager_rol;

--Asignacion de permisos a roles de manejo de clases, socios inscritos, asistencias de reservacion
GRANT SELECT ON dbo.class TO trainer_manager_rol;
GRANT SELECT ON dbo.class_schedule TO trainer_manager_rol;
GRANT SELECT ON dbo.member TO trainer_manager_rol;
GRANT SELECT, UPDATE ON dbo.reservation TO trainer_manager_rol; 

-- Asignacion de permisos a roles para crear,modificar reservas y ver informacion basica
GRANT SELECT ON dbo.member, dbo.class, dbo.class_schedule, dbo.room TO receptionist_manager_user;
GRANT INSERT, UPDATE ON dbo.reservation TO receptionist_manager_user;

--Asignacion de permiso de auditoria para rol de auditor
GRANT SELECT ON SCHEMA:dbo TO auditor_rol;

