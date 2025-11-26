USE master;
GO

IF DB_ID(N'Gym_DB') IS NOT NULL
BEGIN
    PRINT 'Reiniciando la base de datos';
    ALTER DATABASE Gym_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Gym_DB;
END
GO

PRINT 'Verificando y limpiando Logins del servidor';

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'admin_general_lg')
    DROP LOGIN admin_general_lg;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'manager_membership_lg')
    DROP LOGIN manager_membership_lg;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'manager_payments_lg')
    DROP LOGIN manager_payments_lg;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'manager_trainers_lg')
    DROP LOGIN manager_trainers_lg;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'manager_receptionist_lg')
    DROP LOGIN manager_receptionist_lg;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'manager_auditor_lg')
    DROP LOGIN manager_auditor_lg;
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
