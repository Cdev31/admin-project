------------------------------------------------------------------------
-- Creacion de Usuarios, roles, permisos y politicas de privacidad -----
------------------------------------------------------------------------

USE Gym_DB;
GO

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