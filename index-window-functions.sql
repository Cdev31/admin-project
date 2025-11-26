-- Indices y Funciones de Ventana

USE Gym_DB;
GO

-- 1. Indice para busquedas por nombre de miembro
CREATE NONCLUSTERED INDEX IX_member_name
ON member (first_name, last_name)
ON Gym_History_FG; 
GO

-- 2. Indice UNIQUE filtrado para evitar documentos repetidos
CREATE UNIQUE NONCLUSTERED INDEX IX_member_identity_document
ON member(identity_document)
WHERE identity_document IS NOT NULL
ON Gym_History_FG;
GO

-- 3. Indice para acelerar JOIN en pagos
CREATE NONCLUSTERED INDEX IX_payment_member
ON payment(member_id)
ON Gym_History_FG;
GO

-- 4. Indice para acelerar consultas de clases por entrenador y fecha
CREATE NONCLUSTERED INDEX IX_class_schedule_trainer_date
ON class_schedule (trainer_id, start_datetime)
ON Gym_History_FG;
GO

-- 5. Indice filtrado para reservas activas
CREATE NONCLUSTERED INDEX IX_reservation_active
ON reservation (member_id, reservation_date)
WHERE reservation_status = 'Reserved'
ON Gym_History_FG;
GO

-- 6. Indice para la asistencia por clase
CREATE NONCLUSTERED INDEX IX_reservation_class_attended
ON reservation (class_schedule_id, attended)
ON Gym_History_FG;
GO

-- Funciones de ventana

-- 1. Muestra los miembros que mas pagan
SELECT TOP 10
    m.member_id,
    m.first_name + ' ' + m.last_name AS MemberName,
    SUM(p.amount) AS TotalPagado,
    RANK() OVER(ORDER BY SUM(p.amount) DESC) AS RankingGlobal
FROM payment p
JOIN member m ON m.member_id = p.member_id
GROUP BY m.member_id, m.first_name, m.last_name
ORDER BY TotalPagado DESC;
GO

-- 2. Muestra el total pagado por mes de cada miembro
SELECT
    m.member_id,
    FORMAT(p.payment_date, 'yyyy-MM') AS Mes,
    SUM(p.amount) OVER(PARTITION BY m.member_id, FORMAT(p.payment_date,'yyyy-MM')) AS TotalMes,
    p.amount,
    p.payment_date
FROM payment p
JOIN member m ON m.member_id = p.member_id;
GO

-- 3. Compara pagos consecutivos
SELECT
    p.member_id,
    p.payment_date,
    p.amount,
    LAG(p.amount, 1, 0) OVER(PARTITION BY p.member_id ORDER BY p.payment_date) AS PagoAnterior,
    p.amount - LAG(p.amount, 1, 0) OVER(PARTITION BY p.member_id ORDER BY p.payment_date) AS Diferencia
FROM payment p;
GO

-- 4. Muestra las clases más reservadas
SELECT
    cs.class_schedule_id,
    COUNT(r.reservation_id) AS TotalReservas,
    DENSE_RANK() OVER(ORDER BY COUNT(r.reservation_id) DESC) AS Ranking
FROM reservation r
JOIN class_schedule cs ON cs.class_schedule_id = r.class_schedule_id
GROUP BY cs.class_schedule_id;
GO

-- 5. Detectar duplicados
WITH DuplicateEmails AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY member_id) AS rn
    FROM member
)
SELECT *
FROM DuplicateEmails
WHERE rn > 1;
GO

-- Secuencias

-- 1. Crear un numero de recibo
IF NOT EXISTS(SELECT * FROM sys.sequences WHERE name = 'Seq_ReceiptNumber')
BEGIN
    CREATE SEQUENCE Seq_ReceiptNumber
        AS INT
        START WITH 100000
        INCREMENT BY 1;
END
GO

-- 2. Agregar columna para numero de recibo si no existe
IF COL_LENGTH('payment', 'receipt_number') IS NULL
BEGIN
    ALTER TABLE payment
    ADD receipt_number INT NULL;
END
GO

-- 3. Rellenar los pagos existentes usando la secuencia
UPDATE payment
SET receipt_number = NEXT VALUE FOR Seq_ReceiptNumber
WHERE receipt_number IS NULL;
GO

-- 4. Inserción usando la secuencia
INSERT INTO payment (member_id, member_membership_id, payment_method_id, amount, receipt_number)
VALUES (1, NULL, 1, 25.00, NEXT VALUE FOR Seq_ReceiptNumber);
GO
