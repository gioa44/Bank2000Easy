SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_formula_month_min]
	@acc_id int,
	@date smalldatetime,
	@intrate money,
	@spend_intrate money,
	@schema_start_date smalldatetime,
	@schema_end_date smalldatetime,
	@month_eq_30 bit = 0,
	@is_real bit = 0,
	@formula varchar(512) OUTPUT
AS

SET NOCOUNT ON;

DECLARE
	@day int,
	@start_date smalldatetime,
	@end_date	smalldatetime,
	@closed_dt smalldatetime
	
SET @day = DATEPART(DAY, @date) - 1

SET @start_date = DATEADD(DAY, -@day, @date)
SET @end_date = DATEADD(DAY, -1, DATEADD(MONTH, 1, @start_date))

IF @start_date < @schema_start_date
	SET @start_date = @schema_start_date
	
IF @end_date > @schema_end_date
	SET @end_date = @schema_end_date

SET @closed_dt = dbo.bank_open_date() - 1

DECLARE
	@opt_saldo_start int

EXEC dbo.GET_SETTING_INT 'OPT_PERC_SALDO_TYPE', @opt_saldo_start OUTPUT
IF @opt_saldo_start <> 0
  SET @opt_saldo_start = 1

SET @start_date = @start_date - @opt_saldo_start
SET @end_date = @end_date - @opt_saldo_start

DECLARE @sql nvarchar(2000)

DECLARE
	@dt smalldatetime,
	@amount money,
	@min money,
	@min_str varchar(50)
	
SET @amount = NULL
SET @min = $0.00

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

UPDATE #saldos
SET @amount = AMOUNT = ISNULL(AMOUNT, @amount)
FROM #saldos

UPDATE #saldos
SET AMOUNT = dbo.acc_get_balance (@acc_id, DT, 0, 0, 0)
WHERE DT > @closed_dt

UPDATE #saldos
SET AMOUNT = $0.00
WHERE AMOUNT > $0.00

SET @sql = 'SELECT @A=MAX(AMOUNT) FROM #saldos'-- WHERE AMOUNT<$0.00'
SET @amount = $0.00
EXEC sp_executesql @sql, N'@A money output, @acc_id int', @min OUTPUT, @acc_id
DROP TABLE #saldos

SET @min_str = CONVERT(varchar(50), @min)
SET @formula = 'CASE WHEN AMOUNT>' + @min_str + ' THEN $0.00 ELSE ' + @min_str + '*-' + CONVERT(varchar(20), @intrate) + ' + (AMOUNT-(' + @min_str + ')) *-' + CONVERT(varchar(20), @spend_intrate) + ' END'


RETURN (0)

GO
