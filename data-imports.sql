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