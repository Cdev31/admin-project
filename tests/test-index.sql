USE Gym_DB;
GO

/* -------------------------------------------------------------------
   1. PRUEBAS ANTES DE LOS ÍNDICES
   ------------------------------------------------------------------- */

PRINT '--- PRUEBA 1: CONSULTA LENTA (ANTES DE ÍNDICES) ---';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    cs.class_schedule_id,
    cs.start_datetime,
    COUNT(r.reservation_id) AS TotalReservas
FROM reservation r
JOIN class_schedule cs ON cs.class_schedule_id = r.class_schedule_id
GROUP BY cs.class_schedule_id, cs.start_datetime
ORDER BY TotalReservas DESC;
GO

PRINT '--- PRUEBA 2: PAGOS POR MIEMBRO (ANTES DE ÍNDICES) ---';

SELECT 
    m.member_id,
    m.first_name,
    SUM(p.amount) AS TotalPagado
FROM payment p
JOIN member m ON m.member_id = p.member_id
GROUP BY m.member_id, m.first_name;
GO

PRINT '--- PRUEBA 3: FUNCIONES VENTANA (ANTES DE ÍNDICES) ---';

SELECT
    p.member_id,
    p.payment_date,
    p.amount,
    LAG(p.amount, 1, 0) OVER(PARTITION BY p.member_id ORDER BY p.payment_date) AS PagoAnterior,
    SUM(p.amount) OVER(PARTITION BY p.member_id) AS TotalMember
FROM payment p;
GO

PRINT '--- FRAGMENTACIÓN ANTES DE ÍNDICES ---';

SELECT 
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS Fragmentation,
    ips.page_count AS Pages
FROM sys.dm_db_index_physical_stats(DB_ID('Gym_DB'), NULL, NULL, NULL, NULL) ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
ORDER BY Fragmentation DESC;
GO



/* -------------------------------------------------------------------
   2. PRUEBAS DESPUÉS DE ÍNDICES
   ------------------------------------------------------------------- */

PRINT '--- PRUEBA 1: CONSULTA LENTA (DESPUÉS DE ÍNDICES) ---';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    cs.class_schedule_id,
    cs.start_datetime,
    COUNT(r.reservation_id) AS TotalReservas
FROM reservation r
JOIN class_schedule cs ON cs.class_schedule_id = r.class_schedule_id
GROUP BY cs.class_schedule_id, cs.start_datetime
ORDER BY TotalReservas DESC;
GO

PRINT '--- PRUEBA 2: PAGOS POR MIEMBRO (DESPUÉS DE ÍNDICES) ---';

SELECT 
    m.member_id,
    m.first_name,
    SUM(p.amount) AS TotalPagado
FROM payment p
JOIN member m ON m.member_id = p.member_id
GROUP BY m.member_id, m.first_name;
GO

PRINT '--- PRUEBA 3: FUNCIONES VENTANA (DESPUÉS DE ÍNDICES) ---';

SELECT
    p.member_id,
    p.payment_date,
    p.amount,
    LAG(p.amount, 1, 0) OVER(PARTITION BY p.member_id ORDER BY p.payment_date) AS PagoAnterior,
    SUM(p.amount) OVER(PARTITION BY p.member_id) AS TotalMember
FROM payment p;
GO

PRINT '--- FRAGMENTACIÓN DESPUÉS DE ÍNDICES ---';

SELECT 
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS Fragmentation,
    ips.page_count AS Pages
FROM sys.dm_db_index_physical_stats(DB_ID('Gym_DB'), NULL, NULL, NULL, NULL) ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
ORDER BY Fragmentation DESC;
GO