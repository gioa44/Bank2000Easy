SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[acc_show_turn] (
  @acc_id int,
  @start_date smalldatetime,
  @end_date	smalldatetime,
  @equ bit = 0,
  @shadow_level smallint = -1)
RETURNS @tbl TABLE (SALDO_START money, DBO money, CRO money, SALDO_END money)
AS
BEGIN

	DECLARE
		@dt smalldatetime,
		@rec_state smallint

	SET @dt = dbo.bank_open_date()

	IF @end_date < @dt 
		SET @shadow_level = -1

	IF @shadow_level <= 0
	  SET @rec_state = 0
	ELSE
	IF @shadow_level = 1
	  SET @rec_state = 10
	ELSE
	IF @shadow_level >= 2
	  SET @rec_state = 20

	DECLARE 
		@start_balance money,
		--@last_op_date smalldatetime,
		@iso TISO

	SET @start_balance = dbo.acc_get_balance (@acc_id, @start_date, 1, 0, @shadow_level)

	IF @equ <> 0
	BEGIN
		SET @iso = dbo.acc_get_ccy(@acc_id)
		IF @iso = 'GEL'
			SET @equ = 0
	END

--	IF @start_date > dbo.bank_open_date()
--		SET @start_date = dbo.bank_open_date()
--
--	SELECT @last_op_date = MAX(B.DT) 
--	FROM dbo.SALDOS B (NOLOCK) 
--	WHERE B.ACC_ID = @acc_id AND B.DT < @start_date
--
--	IF @last_op_date IS NOT NULL
--	BEGIN
--		SELECT @start_balance = A.SALDO
--		FROM dbo.SALDOS A (NOLOCK)
--		WHERE A.ACC_ID = @acc_id AND A.DT = @last_op_date
--	END
--	ELSE
--	  SET @last_op_date = @start_date

	DECLARE @tmp TABLE (DBO money, CRO money, SALDO money)

	IF @equ = 0
	BEGIN
		INSERT INTO @tmp (DBO, CRO)
		SELECT SUM(DBO), SUM(CRO)
		FROM dbo.SALDOS
		WHERE ACC_ID = @acc_id AND DT BETWEEN @start_date AND @end_date AND (DBO <> $0.0000 OR CRO <> $0.0000)

		IF @shadow_level >= 0
		BEGIN
			INSERT INTO @tmp (DBO, CRO)
			SELECT 
				SUM(CASE @acc_id WHEN D.DEBIT_ID  THEN D.AMOUNT ELSE NULL END),
				SUM(CASE @acc_id WHEN D.CREDIT_ID THEN D.AMOUNT ELSE NULL END)
			FROM dbo.OPS_HELPER_0000 S(NOLOCK) 
				INNER JOIN dbo.OPS_0000 D(NOLOCK) ON D.REC_ID = S.REC_ID AND (D.DOC_DATE BETWEEN @start_date AND @end_date) AND D.REC_STATE >= @rec_state 			WHERE S.ACC_ID = @acc_id AND S.DT <= @end_date
			GROUP BY S.DT
		END
	END
	ELSE
	BEGIN
		SET @start_balance = dbo.get_equ(@start_balance, @iso, @start_date - 1)

		INSERT INTO @tmp (DBO, CRO, SALDO)
		SELECT SUM(dbo.get_equ(DBO, @iso, DT)), SUM(dbo.get_equ(CRO, @iso, DT)), $0.0000
		FROM dbo.SALDOS
		WHERE ACC_ID = @acc_id AND DT BETWEEN @start_date AND @end_date AND (DBO <> $0.0000 OR CRO <> $0.0000)

		IF @shadow_level >= 0
		BEGIN
			INSERT INTO @tmp (DBO, CRO, SALDO)
			SELECT 
				SUM(CASE @acc_id WHEN D.DEBIT_ID  THEN dbo.get_equ(D.AMOUNT, @iso, S.DT) ELSE NULL END),
				SUM(CASE @acc_id WHEN D.CREDIT_ID THEN dbo.get_equ(D.AMOUNT, @iso, S.DT) ELSE NULL END),
				$0.0000 AS SALDO
			FROM dbo.OPS_HELPER_0000 S(NOLOCK) 
				INNER JOIN dbo.OPS_0000 D(NOLOCK) ON D.REC_ID = S.REC_ID AND (D.DOC_DATE BETWEEN @start_date AND @end_date) AND D.REC_STATE >= @rec_state 			WHERE S.ACC_ID = @acc_id AND S.DT <= @end_date
			GROUP BY S.DT
		END


		DECLARE @rates TABLE (
			[ID] int IDENTITY (1,1) NOT NULL,
			DT smalldatetime, 
			RATE decimal(32,12), 
			PRIMARY KEY CLUSTERED([ID])
		)

		DECLARE @prev_rate_date smalldatetime
		SELECT @prev_rate_date = MAX(DT) FROM dbo.VAL_RATES (NOLOCK) WHERE ISO = @iso AND DT < @start_date
		IF @prev_rate_date IS NULL
			SET @prev_rate_date = @start_date

		INSERT INTO @rates
		SELECT DT, CONVERT(decimal(32,12), AMOUNT) / ITEMS
		FROM dbo.VAL_RATES (NOLOCK)
		WHERE DT BETWEEN @prev_rate_date AND @end_date AND ISO = @iso
		ORDER BY DT

		INSERT INTO @tmp (DBO, CRO)
		SELECT CASE WHEN TURN > 0 THEN A.TURN ELSE $0.00 END, CASE WHEN TURN < 0 THEN -A.TURN ELSE $0.00 END
		FROM ( 
			SELECT 
				ROUND((A.RATE - B.RATE) * ISNULL(dbo.acc_get_balance(@acc_id, A.DT, 1, 0, @shadow_level), $0.00), 4) AS TURN
			FROM @rates A
				INNER JOIN @rates B ON B.ID = A.ID - 1
			WHERE A.RATE <> B.RATE
		) A
		WHERE A.TURN <> $0.00

--		INSERT INTO @tmp (DBO, CRO)
--			SELECT CASE WHEN (A.RATE - B.RATE) * dbo.acc_get_balance(@acc_id, A.DT, 1, 0, @shadow_level) > 0 THEN ISNULL((A.RATE - B.RATE) * dbo.acc_get_balance(@acc_id, A.DT, 1, 0, @shadow_level), $0.0000) ELSE $0.0000 END,
--				CASE WHEN (A.RATE - B.RATE) * dbo.acc_get_balance(@acc_id, A.DT, 1, 0, @shadow_level) > 0 THEN $0.0000 ELSE -ISNULL((A.RATE - B.RATE) * dbo.acc_get_balance(@acc_id, A.DT, 1, 0, @shadow_level), $0.0000) END
--		FROM @rates A
--			INNER JOIN @rates B ON B.ID = A.ID - 1
--		WHERE A.RATE <> B.RATE AND dbo.acc_get_balance(@acc_id, A.DT, 1, 0, @shadow_level) <> 0
	END

	INSERT INTO @tbl (SALDO_START, DBO, CRO, SALDO_END)
	SELECT @start_balance, SUM(DBO), SUM(CRO), @start_balance + ISNULL(SUM(DBO), $0.0000) - ISNULL(SUM(CRO), $0.0000)
	FROM @tmp

	RETURN
END
GO
