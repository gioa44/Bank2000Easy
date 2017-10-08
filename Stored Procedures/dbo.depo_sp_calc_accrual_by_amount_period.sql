SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_calc_accrual_by_amount_period]
	@depo_id int,
	@accrual_date smalldatetime,
	@accrual_amount money = NULL OUTPUT,
	@result_type tinyint
AS
BEGIN	
SET NOCOUNT ON;

SET @accrual_amount = $0.00

DECLARE
	@pfDontIncludeStartDate int,
	@pfDontIncludeEndDate int

SET @pfDontIncludeStartDate = 1
SET @pfDontIncludeEndDate = 2
 
DECLARE @T_IN TABLE(
	OP_ID int NOT NULL,
	DATE smalldatetime NOT NULL,
	OP_DATE smalldatetime,
	OP_AMOUNT money NOT NULL,
	AMOUNT money NOT NULL,
	INTRATE money NULL,
	PERIOD int NULL,
	PERIOD_DAYS int NOT NULL,	
	DAYS int NOT NULL,
	IS_OUT bit NOT NULL,
	ACCRUAL float NULL)

DECLARE @T_OUT TABLE(
	DATE smalldatetime NOT NULL,
	OP_ID int NOT NULL,
	AMOUNT money NOT NULL)

DECLARE
	@prod_id int,
	@iso char(3),
	@perc_flags int,
	@depo_start_date smalldatetime,
	@depo_end_date smalldatetime,
	@date_type tinyint,
	@days_in_year int,
	@depo_acc_id int

SELECT @prod_id = PROD_ID, @iso = ISO, @perc_flags = PERC_FLAGS, @depo_start_date = [START_DATE], @depo_end_date = END_DATE, @date_type = DATE_TYPE, @days_in_year = DAYS_IN_YEAR, @depo_acc_id = DEPO_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

SELECT @depo_start_date = [START_DATE]
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @depo_acc_id

INSERT INTO @T_IN(OP_ID, DATE, OP_DATE, OP_AMOUNT, AMOUNT, PERIOD_DAYS, DAYS, IS_OUT)
SELECT O.REC_ID, O.DOC_DATE, O.DOC_DATE, O.AMOUNT, O.AMOUNT, DATEDIFF(day, O.DOC_DATE, @depo_end_date), DATEDIFF(day, O.DOC_DATE, @accrual_date), 0
FROM dbo.OPS_FULL O (NOLOCK)
	INNER JOIN dbo.OPS_HELPER_FULL H (NOLOCK) ON O.REC_ID = H.REC_ID AND O.CREDIT_ID = H.ACC_ID
WHERE H.ACC_ID = @depo_acc_id AND H.DT BETWEEN @depo_start_date AND @accrual_date AND ISNULL(O.OP_CODE, '') <> '*RL%*'

IF @date_type = 1
	UPDATE @T_IN
	SET PERIOD = DATEDIFF(day, DATE, @depo_end_date)
ELSE
BEGIN
	UPDATE @T_IN
	SET PERIOD = DATEDIFF(month, DATE, @depo_end_date)

	UPDATE @T_IN
	SET PERIOD = PERIOD - CASE WHEN DATEADD(month, PERIOD, DATE) > @depo_end_date THEN 1 ELSE 0 END 
END;


INSERT INTO @T_OUT(DATE, OP_ID, AMOUNT)
SELECT O.DOC_DATE, O.REC_ID, O.AMOUNT
FROM dbo.OPS_FULL O (NOLOCK)
	INNER JOIN dbo.OPS_HELPER_FULL H (NOLOCK) ON O.REC_ID = H.REC_ID AND O.DEBIT_ID = H.ACC_ID
WHERE H.ACC_ID = @depo_acc_id AND H.DT BETWEEN @depo_start_date AND @accrual_date AND ISNULL(O.OP_CODE, '') <> '*%TX*'

DECLARE
	@date smalldatetime,
	@amount money

DECLARE
	@op_id int,
	@op_id_out int,
	@in_date smalldatetime,
	@in_amount money

DECLARE
	@op_amount money,
	@days int,
	@period int,
	@intrate money

DECLARE cc CURSOR FOR
SELECT DATE, OP_ID, AMOUNT FROM @T_OUT
OPEN cc

FETCH NEXT FROM cc INTO	@date, @op_id_out, @amount

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @op_amount = -@amount
	WHILE @amount > $0.00
	BEGIN
		SET @op_id = NULL
		SET @in_date = NULL
		SET @in_amount = NULL

		SELECT TOP 1 @op_id = OP_ID, @in_date = DATE, @in_amount = AMOUNT
		FROM @T_IN
		WHERE AMOUNT > $0.00 AND IS_OUT = 0
		ORDER BY DATE ASC, OP_ID ASC 

		IF @op_id IS NULL BREAK;

		IF @in_amount >= @amount
		BEGIN
			UPDATE @T_IN
			SET AMOUNT = AMOUNT - @amount
			WHERE OP_ID = @op_id

			IF @date_type = 1
				SET @period = DATEDIFF(DAY, @in_date, @date) 
			ELSE
			BEGIN
				SET @period = DATEDIFF(MONTH, @in_date, @date) 
				SET @period = @period - CASE WHEN (@period > 0) AND (DATEADD(MONTH, @period, @in_date) > @date) THEN 1 ELSE 0 END
			END

			SET @days = DATEDIFF(day, @in_date, @date) 
			
			INSERT INTO @T_IN(OP_ID, DATE, OP_DATE, OP_AMOUNT, AMOUNT, PERIOD, PERIOD_DAYS, DAYS, IS_OUT)
			VALUES(@op_id_out, @in_date, @date, @op_amount, @amount, @period, @days, @days, 1)
			
			SET @amount = @amount - @in_amount 
		END
		ELSE
		BEGIN
			UPDATE @T_IN
			SET AMOUNT = $0.00
			WHERE OP_ID = @op_id

			SET @amount = @amount - @in_amount

			IF @date_type = 1
				SET @period = DATEDIFF(DAY, @in_date, @date) 
			ELSE
			BEGIN
				SET @period = DATEDIFF(MONTH, @in_date, @date) 
				SET @period = @period - CASE WHEN (@period > 0) AND (DATEADD(MONTH, @period, @in_date) > @date) THEN 1 ELSE 0 END
			END
			SET @days = DATEDIFF(day, @in_date, @date) 

			INSERT INTO @T_IN(OP_ID, DATE, OP_DATE, OP_AMOUNT, AMOUNT, PERIOD, PERIOD_DAYS, DAYS, IS_OUT)
			VALUES(@op_id_out, @in_date, @date, @op_amount, @in_amount, @period, @days, @days, 1)
			
		END
	END

	FETCH NEXT FROM cc INTO	@date, @op_id_out, @amount
END
CLOSE cc
DEALLOCATE cc

IF @accrual_date = @depo_end_date
BEGIN
	UPDATE @T_IN
	SET DAYS = DAYS - 1
	WHERE IS_OUT = 0 AND AMOUNT > $0.00

	IF @perc_flags & @pfDontIncludeStartDate = 0
		UPDATE @T_IN
		SET DAYS = DAYS + 1
		WHERE IS_OUT = 0 AND AMOUNT > $0.00
		
	IF @perc_flags & @pfDontIncludeEndDate = 0
		UPDATE @T_IN
		SET DAYS = DAYS + 1
		WHERE IS_OUT = 0 AND AMOUNT > $0.00
		
	UPDATE @T_IN
	SET DAYS = 0
	WHERE DAYS < 0
END

DECLARE cc2 CURSOR FOR
SELECT PERIOD FROM @T_IN
FOR UPDATE OF INTRATE, ACCRUAL
OPEN cc2

FETCH NEXT FROM cc2 INTO @period

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC dbo.[depo_sp_get_deposit_intrate]
		@prod_id = @prod_id,
		@iso = @iso,
		@period = @period,
		@intrate = @intrate OUTPUT,
		@show_result = 0
	
	UPDATE @T_IN
	SET INTRATE = @intrate, ACCRUAL = AMOUNT * @intrate / @days_in_year / 100.00 * DAYS
	WHERE CURRENT OF cc2 
	
	FETCH NEXT FROM cc2 INTO @period
END

CLOSE cc2
DEALLOCATE cc2

SELECT @accrual_amount = ROUND(SUM(ACCRUAL), 2)
FROM @T_IN
WHERE AMOUNT > $0.00

IF @result_type = 1
	SELECT * FROM @T_IN
END

GO
