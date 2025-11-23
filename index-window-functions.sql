--indices
-- 1. indice para busquedas por nombre de miembro
CREATE NONCLUSTERED INDEX IX_member_name
ON member (first_name, last_name);
GO

-- 2. indice UNIQUE filtrado para evitar los documentos repetidos
CREATE UNIQUE NONCLUSTERED INDEX IX_member_identity_document
ON member(identity_document)
WHERE identity_document IS NOT NULL;
GO

-- 3. indice para acelerar JOIN en pagos
CREATE NONCLUSTERED INDEX IX_payment_member
ON payment(member_id);
GO

-- 4. indice para acelerar consultas de clases por entrenador y fecha
CREATE NONCLUSTERED INDEX IX_class_schedule_trainer_date
ON class_schedule (trainer_id, start_datetime);
GO

-- 5. indice filtrado para reservas activas
CREATE NONCLUSTERED INDEX IX_reservation_active
ON reservation (member_id, reservation_date)
WHERE reservation_status = 'Reserved';
GO

-- 6. indice para la asistencia por clase
CREATE NONCLUSTERED INDEX IX_reservation_class_attended
ON reservation (class_schedule_id, attended);
GO

--ventana
-- 1. muestra los miembros que mas pagan
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

-- 2. muestra el total pagado por mes de cada miembro
SELECT
    m.member_id,
    FORMAT(p.payment_date, 'yyyy-MM') AS Mes,
    SUM(p.amount) OVER(PARTITION BY m.member_id, FORMAT(p.payment_date,'yyyy-MM')) AS TotalMes,
    p.amount,
    p.payment_date
FROM payment p
JOIN member m ON m.member_id = p.member_id;
GO

-- 3. compara los pagos consecutivos
SELECT
    p.member_id,
    p.payment_date,
    p.amount,
    LAG(p.amount, 1, 0) OVER(PARTITION BY p.member_id ORDER BY p.payment_date) AS PagoAnterior,
    p.amount - LAG(p.amount, 1, 0) OVER(PARTITION BY p.member_id ORDER BY p.payment_date) AS Diferencia
FROM payment p;
GO

-- 4. muestra las clases más reservadas
SELECT
    cs.class_schedule_id,
    COUNT(r.reservation_id) AS TotalReservas,
    DENSE_RANK() OVER(ORDER BY COUNT(r.reservation_id) DESC) AS Ranking
FROM reservation r
JOIN class_schedule cs ON cs.class_schedule_id = r.class_schedule_id
GROUP BY cs.class_schedule_id;
GO

-- 5. muestra miembros duplicados 
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

--secuencias
-- 1. crear un numero de recibo 
CREATE SEQUENCE Seq_ReceiptNumber
    AS INT
    START WITH 100000
    INCREMENT BY 1;
GO

-- 2.agregr columna para numero de recibo 
IF COL_LENGTH('payment', 'receipt_number') IS NULL
BEGIN
    ALTER TABLE payment
    ADD receipt_number INT NULL;
END
GO

-- 3. rellena los pagos
UPDATE payment
SET receipt_number = NEXT VALUE FOR Seq_ReceiptNumber
WHERE receipt_number IS NULL;
GO

-- 4. inserción usando la secuencia
INSERT INTO payment (member_id, member_membership_id, payment_method_id, amount, receipt_number)
VALUES (1, NULL, 1, 25.00, NEXT VALUE FOR Seq_ReceiptNumber);
GO
