USE master;
GO

-- Cambiar al modelo de recuperaci�n COMPLETO (Full Recovery Model)
-- Esto es OBLIGATORIO para poder hacer backups de logs de transacciones
ALTER DATABASE Gym_DB 
SET RECOVERY FULL;
GO

-- Definici�n de variables para el nombre din�mico del archivo
DECLARE @fecha VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), ':', '');
DECLARE @nombreArchivo VARCHAR(255) = 'C:\SQL_Backups\GymDB_FULL_' + @fecha + '.bak';
DECLARE @nombreBackup VARCHAR(255) = 'Gym_DB Database Backup';

BACKUP DATABASE Gym_DB 
TO DISK = @nombreArchivo
WITH 
    FORMAT, -- Formatea el medio (asegura que sea un backup limpio)
    COMPRESSION, -- Comprime el backup (ahorra espacio en disco)
    CHECKSUM, -- Verifica la integridad de los datos mientras hace el backup
    NAME = @nombreBackup, 
    STATS = 10; -- Muestra el progreso cada 10%
GO

-- Variables de fecha y nombre
DECLARE @fecha VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), ':', '');
DECLARE @nombreArchivo VARCHAR(255) = 'C:\SQL_Backups\GymDB_DIFF_' + @fecha + '.bak';
DECLARE @nombreBackup VARCHAR(255) = 'Gym_DB-Differential Database Backup';

BACKUP DATABASE Gym_DB
TO DISK = @nombreArchivo
WITH 
    DIFFERENTIAL,
    COMPRESSION,
    CHECKSUM,
    NAME = @nombreBackup,
    STATS = 10;
GO

-- Variables de fecha y nombre
DECLARE @fecha VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), ':', '');
DECLARE @nombreArchivo VARCHAR(255) = 'C:\SQL_Backups\Gym_DB_LOG_' + @fecha + '.trn'; 
DECLARE @nombreBackup VARCHAR(255) = 'Gym_DB-Transaction Log Backup';

BACKUP LOG Gym_DB
TO DISK = @nombreArchivo
WITH 
    COMPRESSION,
    NO_TRUNCATE, -- Asegura que se guarde el log incluso si la BD est� da�ada
    NAME = @nombreBackup,
    STATS = 10;
GO