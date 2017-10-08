SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[calc_accrual_amount]
  @acc_id int,
  @start_date smalldatetime,
  @end_date	smalldatetime,
  @formula	varchar(512),
  @is_debit	bit,
  @amount money OUTPUT,
  @month_eq_30 bit = 0,
  @is_real bit = 0,
  @days_in_year int,
  @tax_rate money = $0.00,
  @recalc_option tinyint = 0	-- 0x00 - Auto
								-- 0x01 - Calc as usual (last accrual)
								-- 0x02 - Recalc from last realize date
								-- 0x04 - Recalc from beginning
AS

SET NOCOUNT ON

DECLARE
  @closed_dt smalldatetime

SET @closed_dt = dbo.bank_open_date() - 1

DECLARE @opt_saldo_start int

EXEC dbo.GET_SETTING_INT 'OPT_PERC_SALDO_TYPE', @opt_saldo_start OUTPUT
IF @opt_saldo_start <> 0
  SET @opt_saldo_start = 1

SET @start_date = @start_date - @opt_saldo_start
SET @end_date = @end_date - @opt_saldo_start

DECLARE @sql nvarchar(2000)

DECLARE
	@dt smalldatetime,
	@total money

SET @total = $0.00

CREATE TABLE #saldos (DT smalldatetime NOT NULL, AMOUNT money NULL, REC_ID int identity (1,1) PRIMARY KEY CLUSTERED)

SET @dt = @start_date

WHILE @dt <= @end_date
BEGIN
  INSERT INTO #saldos (DT) VALUES (@dt)
  SET @dt = @dt + 1
END

IF @month_eq_30 <> 0
BEGIN
  DELETE FROM #saldos
  WHERE DAY(DT + @opt_saldo_start) = 31

  INSERT INTO #saldos (DT)
  SELECT DISTINCT DT 
  FROM #saldos A
  WHERE MONTH(DT + @opt_saldo_start) = 2 AND DAY(DT + @opt_saldo_start) = 28 AND DAY(DT + @opt_saldo_start+1) <> 29
     AND (@is_real = 0 OR (SELECT COUNT(*) FROM #saldos) % 30 in (28,29))

  INSERT INTO #saldos (DT)
  SELECT DISTINCT DT 
  FROM #saldos A
  WHERE MONTH(DT + @opt_saldo_start) = 2 AND DAY(DT + @opt_saldo_start) = 28 AND DAY(DT + @opt_saldo_start+1) <> 29
    AND (@is_real = 0 OR (SELECT COUNT(*) FROM #saldos) % 30 in (28,29))

  INSERT INTO #saldos (DT)
  SELECT DISTINCT DT 
  FROM #saldos A
  WHERE MONTH(DT + @opt_saldo_start) = 2 AND DAY(DT + @opt_saldo_start) = 29
    AND (@is_real = 0 OR (SELECT COUNT(*) FROM #saldos) % 30 in (28,29))

  INSERT INTO #saldos (DT)
  SELECT DISTINCT DT 
  FROM #saldos A
  WHERE MONTH(DT + @opt_saldo_start) = 3 AND DAY(DT + @opt_saldo_start) = 1 
    AND (@is_real=1 AND (SELECT COUNT(*) FROM #saldos) % 30 in (28,29))

  INSERT INTO #saldos (DT)
  SELECT DISTINCT DT 
  FROM #saldos A
  WHERE MONTH(DT + @opt_saldo_start) = 3 AND DAY(DT + @opt_saldo_start) = 1 
    AND (@is_real=1 AND (SELECT COUNT(*) FROM #saldos) % 30 in (28,29))
END   

UPDATE #saldos
SET AMOUNT = A.SALDO
FROM #saldos S
	INNER JOIN dbo.SALDOS A ON A.ACC_ID = @acc_id AND A.DT = S.DT

IF EXISTS(SELECT * FROM #saldos WHERE DT = @start_date AND AMOUNT IS NULL)
	UPDATE #saldos
	SET AMOUNT = dbo.acc_get_balance (@acc_id, @start_date, 0, 0, 0)
	WHERE DT = @start_date

SET @amount = NULL

UPDATE #saldos
SET @amount = AMOUNT = ISNULL(AMOUNT, @amount)
FROM #saldos

UPDATE #saldos
SET AMOUNT = dbo.acc_get_balance (@acc_id, DT, 0, 0, 0)
WHERE DT > @closed_dt

IF @recalc_option = 0x04 -- Recalc from beginning
BEGIN
	DECLARE @tbl TABLE (DT smalldatetime, CALC_DATE smalldatetime PRIMARY KEY, AMOUNT money NOT NULL)
	DECLARE @calc_date smalldatetime

	INSERT INTO @tbl
	SELECT DOC_DATE, DOC_DATE_IN_DOC, SUM(CASE WHEN DEBIT_ID = @acc_id THEN AMOUNT ELSE - AMOUNT END)
	FROM dbo.OPS_FULL (NOLOCK)
	WHERE DOC_TYPE = 30 and ACCOUNT_EXTRA = @acc_id AND	(DEBIT_ID = @acc_id OR CREDIT_ID = @acc_id)
	GROUP BY DOC_DATE, DOC_DATE_IN_DOC

	IF NOT EXISTS(SELECT * FROM @tbl) GOTO CALCULATE

	DECLARE cc CURSOR READ_ONLY LOCAL FORWARD_ONLY
	FOR SELECT * FROM @tbl ORDER BY CALC_DATE

	OPEN cc
	FETCH NEXT FROM cc INTO @dt, @calc_date, @amount

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE #saldos
		SET AMOUNT = AMOUNT - @amount
		WHERE DT >= @dt

		DECLARE @amount_new money
		SET @amount_new  = $0.00

		SET @sql = 'SELECT @A=SUM(' + @formula + ') FROM #saldos WHERE DT <= @dt'
		EXEC sp_executesql @sql, N'@A money output, @acc_id int, @dt smalldatetime', @amount_new OUTPUT, @acc_id, @calc_date

		SET @amount_new = ROUND(ISNULL(@amount_new, $0.0000) / (@days_in_year * $100.00), 4)
		SET @total = @total + @amount_new 

		SET @amount_new = @amount_new - (@amount_new * @tax_rate / $100.00) -- ვაკლებთ, რადგან მოხდებოდა სარგებლის დაბეგვრა რომელიც გააკლდება ნაშთს

		UPDATE #saldos
		SET AMOUNT = AMOUNT - @amount_new
		WHERE DT > @dt

		DELETE FROM #saldos
		WHERE DT <= @dt

		FETCH NEXT FROM cc INTO @dt, @calc_date, @amount
	END	

	CLOSE cc
	DEALLOCATE cc
END

CALCULATE:

SET @sql = 'SELECT @A=SUM(' + @formula + ') FROM #saldos'
SET @amount = $0.00
EXEC sp_executesql @sql, N'@A money output, @acc_id int', @amount OUTPUT, @acc_id

SET @amount = ROUND(ISNULL(@amount, $0.0000) / (@days_in_year * $100.00), 4) + @total 

DROP TABLE #saldos
RETURN (0)
GO
