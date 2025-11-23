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
