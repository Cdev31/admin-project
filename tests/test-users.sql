USE Gym_DB;
GO

PRINT '          INICIANDO PRUEBAS DE SEGURIDAD';
PRINT '--------------------------------------------------';
GO

-- PRUEBA 1: Membership Manager
PRINT '>>> TEST 1: Rol Membership Manager (membership_manager_user)';

EXECUTE AS USER = 'membership_manager_user';
BEGIN TRY
    -- Intento Permitido: Leer socios
    DECLARE @CountSocios INT;
    SELECT @CountSocios = COUNT(*) FROM dbo.member;
    PRINT '  [EXITO] Lectura de tabla member permitida. Registros: ' + CAST(@CountSocios AS VARCHAR);
    
    -- Intento Prohibido: Leer Pagos
    DECLARE @CountPagos INT;
    SELECT @CountPagos = COUNT(*) FROM dbo.payment;
    PRINT '  [FALLO DE SEGURIDAD] ¡El usuario pudo leer la tabla payment!'; -- Fallo de seguridad si se alcanza esto
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 229
        PRINT '  [EXITO] Acceso denegado correctamente a la tabla payment.';
    ELSE
        PRINT '  [ERROR] Ocurrió un error inesperado: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
PRINT '--------------------------------------------------';


-- PRUEBA 2: Payment Manager
PRINT '>>> TEST 2: Rol Payment Manager (payment_manager_user)';

EXECUTE AS USER = 'payment_manager_user';
BEGIN TRY
    -- Intento Permitido: Leer métodos de pago
    DECLARE @CountMetodos INT;
    SELECT @CountMetodos = COUNT(*) FROM dbo.payment_method;
    PRINT '  [EXITO] Lectura de payment_method permitida.';

    -- Intento Prohibido: Leer Clases
    DECLARE @CountClases INT;
    SELECT @CountClases = COUNT(*) FROM dbo.class;
    
    PRINT '  [FALLO DE SEGURIDAD] ¡El usuario pudo leer la tabla class!';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 229
        PRINT '  [EXITO] Acceso denegado correctamente a la tabla class.';
    ELSE
        PRINT '  [ERROR] Error inesperado: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
PRINT '--------------------------------------------------';


-- PRUEBA 3: Receptionist
PRINT '>>> TEST 3: Rol Receptionist (receptionist_manager_user)';

EXECUTE AS USER = 'receptionist_manager_user';
BEGIN TRY
    -- Intento Permitido: Insertar una reserva
    DECLARE @MemberID INT, @ScheduleID INT;
    SELECT TOP 1 @MemberID = member_id FROM dbo.member;
    SELECT TOP 1 @ScheduleID = class_schedule_id FROM dbo.class_schedule;

    IF @MemberID IS NOT NULL AND @ScheduleID IS NOT NULL
    BEGIN
        -- Transacción para no ensuciar la DB real
        BEGIN TRANSACTION;
            INSERT INTO dbo.reservation (member_id, class_schedule_id, reservation_date, reservation_status, attended)
            VALUES (@MemberID, @ScheduleID, SYSDATETIME(), 'Reserved', 0);
            PRINT '  [EXITO] Inserción en reservation permitida.';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT '  [INFO] No se pudo probar INSERT por falta de datos en tablas padres.';
    END

    -- 2. Intento Prohibido: Borrar un socio
    DELETE FROM dbo.member WHERE member_id = @MemberID;
    
    PRINT '  [FALLO DE SEGURIDAD] ¡El usuario pudo eliminar un registro de member!';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 229
        PRINT '  [EXITO] Acceso denegado correctamente al intentar DELETE en member.';
    ELSE
        PRINT '  [ERROR] Error inesperado: ' + ERROR_MESSAGE();
    -- Asegurar rollback si falló dentro de la transacción
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
REVERT;
PRINT '--------------------------------------------------';

-- PRUEBA 4: Auditor
PRINT '>>> TEST 4: Rol Auditor (auditor_user)';

EXECUTE AS USER = 'auditor_user';
BEGIN TRY
    -- 1. Intento Permitido: Leer de tabla de Pagos
    DECLARE @CheckAudit INT;
    SELECT @CheckAudit = COUNT(*) FROM dbo.payment;
    PRINT '  [EXITO] El auditor puede leer la tabla payment.';

    -- 2. Intento Prohibido: Actualizar una sala
    UPDATE dbo.room SET capacity = 100 WHERE room_id = 1;
    
    PRINT '  [FALLO DE SEGURIDAD] ¡El auditor pudo modificar datos!';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 229
        PRINT '  [EXITO] Acceso denegado correctamente al intentar UPDATE (Solo lectura).';
    ELSE
        PRINT '  [ERROR] Error inesperado: ' + ERROR_MESSAGE();
END CATCH;
REVERT;

PRINT '--------------------------------------------------';
PRINT '          FIN DE PRUEBAS DE SEGURIDAD';
GO