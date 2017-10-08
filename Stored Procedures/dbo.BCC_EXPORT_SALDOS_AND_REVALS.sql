SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[BCC_EXPORT_SALDOS_AND_REVALS] (
  @acc_id int,
  @start_date datetime
)
AS

IF @start_date IS NULL OR @start_date < dbo.bank_first_date()
	SET @start_date = dbo.bank_first_date()

DECLARE @statement TABLE (DT smalldatetime NOT NULL, DBO_REVAL money, CRO_REVAL money, SALDO money, SALDO_EQU money)

DECLARE
	@dt_open smalldatetime

SET @dt_open = dbo.bank_open_date()
IF @start_date > @dt_open
BEGIN
	SELECT * FROM @statement
	RETURN 
END

DECLARE 
	@start_balance money,
	@last_op_date smalldatetime

SET @start_balance = $0.0000

SELECT @last_op_date = MAX(B.DT) 
FROM dbo.SALDOS B (NOLOCK) 
WHERE B.ACC_ID = @acc_id AND B.DT < @start_date

IF @last_op_date IS NOT NULL
BEGIN
	SELECT @start_balance = A.SALDO
	FROM dbo.SALDOS A (NOLOCK)
	WHERE A.ACC_ID = @acc_id AND A.DT = @last_op_date
END
ELSE
  SET @last_op_date = @start_date


DECLARE @tbl TABLE (DT smalldatetime NOT NULL, REC_TYPE smallint, DBO money, DBO_EQU money, CRO money, CRO_EQU money, SALDO money, SALDO_EQU money, RATE_DIFF decimal(32,12) NULL,
			PRIMARY KEY CLUSTERED (DT, REC_TYPE))
		

INSERT INTO @tbl(DT, REC_TYPE, SALDO)
VALUES (@last_op_date, -2, @start_balance)

DECLARE @iso TISO
SET @iso = dbo.acc_get_account_ccy (@acc_id)

INSERT INTO @tbl (DT, REC_TYPE, DBO, CRO, SALDO, SALDO_EQU)
SELECT S.DT, 0, DBO, CRO, $0.0000 AS SALDO, $0.0000 AS SALDO_EQU
FROM dbo.SALDOS S (NOLOCK) 
WHERE S.ACC_ID = @acc_id AND S.DT >= @start_date
ORDER BY S.DT

IF @iso <> 'GEL'
BEGIN
	DECLARE @rates TABLE (
		[ID] int IDENTITY (1,1) NOT NULL,
		DT smalldatetime, 
		RATE decimal(32,12), 
		PRIMARY KEY CLUSTERED([ID])
	)

	INSERT INTO @rates
	SELECT DT, AMOUNT / ITEMS
	FROM dbo.VAL_RATES (NOLOCK)
	WHERE DT BETWEEN ISNULL(@last_op_date, @start_date) AND @dt_open AND ISO = @iso
	ORDER BY DT

	INSERT INTO @tbl(DT, REC_TYPE, RATE_DIFF)
	SELECT A.DT, -1, NULL
	FROM @rates A
		INNER JOIN @rates B ON B.ID = A.ID -1
	WHERE A.RATE <> B.RATE AND NOT EXISTS(SELECT * FROM @tbl T WHERE T.DT = A.DT)

	UPDATE @tbl
	SET RATE_DIFF = A.RATE - B.RATE
	FROM @tbl T
		INNER JOIN @rates A ON A.DT = T.DT
		INNER JOIN @rates B ON B.ID = A.ID -1
	WHERE A.RATE <> B.RATE
END

DECLARE 
	@start_balance_equ money,
	@old_balance money
	
UPDATE @tbl
SET 
	@old_balance = @start_balance ,
	DBO_EQU = CASE WHEN RATE_DIFF * @old_balance > 0 THEN ISNULL(RATE_DIFF * @old_balance, $0.0000) ELSE $0.0000 END,
	CRO_EQU = CASE WHEN RATE_DIFF * @old_balance > 0 THEN $0.0000 ELSE -ISNULL(RATE_DIFF * @old_balance, $0.0000) END,
	@start_balance = @old_balance + ISNULL(DBO, $0.0000) - ISNULL(CRO, $0.0000),
	SALDO = @start_balance,
	@start_balance_equ = CASE WHEN @iso = 'GEL' THEN @start_balance ELSE dbo.get_equ(@start_balance, @iso, DT) END,
	SALDO_EQU = @start_balance_equ


--INSERT INTO @tbl(REC_TYPE, DT, DBO, DBO_EQU, CRO, CRO_EQU, SALDO, SALDO_EQU)
--SELECT 2, @dt_open, SUM(DBO), SUM(DBO_EQU), SUM(CRO), SUM(CRO_EQU), @start_balance, @start_balance_equ
--FROM @tbl	

UPDATE @tbl
SET DBO_EQU = ROUND(DBO_EQU, 2), CRO_EQU = ROUND(CRO_EQU, 2), SALDO_EQU = ROUND(SALDO_EQU, 2)

INSERT INTO @statement
SELECT T.DT, SUM(T.DBO_EQU), SUM(T.CRO_EQU), SUM(T.SALDO), SUM(T.SALDO_EQU)
FROM @tbl T
WHERE REC_TYPE IN (0,-1) AND DT >= @start_date
GROUP BY DT


SELECT * FROM @statement	
--
RETURN
GO
