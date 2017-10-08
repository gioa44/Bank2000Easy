SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  FUNCTION [dbo].[acc_show_statement] (
	@acc_id int,
	@equ bit = 0,
	@start_date smalldatetime,
	@end_date	smalldatetime,
	@shadow_level smallint = -1,
	@show_subsums bit = 0,
	@show_extra_info bit = 0
  )

RETURNS @statement TABLE (REC_ID int, DOC_TYPE smallint, DT smalldatetime NOT NULL, ACCOUNT decimal(15,0) NULL, ACC_ID int, DESCRIP varchar(150), EXTRA_INFO varchar(150),
							DOC_NUM int, OP_CODE varchar(5), REC_STATE tinyint, PARENT_REC_ID int, ACCOUNT_EXTRA decimal(15,0) NULL, DOC_DATE_IN_DOC smalldatetime NULL, 
							IS_ARC bit, DBO money, DBO_EQU money, CRO money, CRO_EQU money, SALDO money, SALDO_EQU money,
							SORT_ID int,
							PRIMARY KEY CLUSTERED (DT,REC_ID))
AS
BEGIN
	DECLARE
		@iso TISO,
		@dt_open smalldatetime,
		@rec_state smallint

	SET @dt_open = dbo.bank_open_date()

	IF @end_date < @dt_open 
		SET @shadow_level = -1

	IF @shadow_level <= 0
	  SET @rec_state = 0
	ELSE
	IF @shadow_level = 1
	  SET @rec_state = 10
	ELSE
	IF @shadow_level >= 2
	  SET @rec_state = 20

	SET @iso = dbo.acc_get_ccy(@acc_id)
	IF @iso = 'GEL'
		SET @equ = 0

	DECLARE 
		@start_balance money,
		@start_balance_equ money,
		@saldo money,
		@saldo_equ money,
		@last_op_date smalldatetime

	SET @start_balance = $0.0000

	DECLARE @start_date0 smalldatetime
	SET @start_date0 = @start_date
	IF @start_date > @dt_open
		SET @start_date = @dt_open

	SELECT @last_op_date = MAX(B.DT) 
	FROM dbo.SALDOS B (NOLOCK) 
	WHERE B.ACC_ID = @acc_id AND B.DT < @start_date

	IF @last_op_date IS NOT NULL
	BEGIN
		SELECT @start_balance = A.SALDO
		FROM dbo.SALDOS A (NOLOCK)
		WHERE A.ACC_ID = @acc_id AND A.DT = @last_op_date
	END
	
	-- @start_balance–ში არის დახურული დღის ნაშთი
	-- @last_op_date-ში არის დახურული დღის ბოლო ოპერაციის თარიღი

	DECLARE @tbl TABLE (REC_ID int, DOC_TYPE smallint, DT smalldatetime NOT NULL, ACC_ID int, 
			DOC_NUM int, OP_CODE varchar(5), DESCRIP varchar(150), REC_STATE tinyint, PARENT_REC_ID int, ACCOUNT_EXTRA decimal(15,0) NULL, DOC_DATE_IN_DOC smalldatetime NULL,
			IS_ARC bit, DBO money, DBO_EQU money, CRO money, CRO_EQU money, SALDO money, SALDO_EQU money, RATE_DIFF decimal(32,12) NULL,
			PRIMARY KEY CLUSTERED (DT,REC_ID))
		
	-- Last Real Operation
	SET @start_balance_equ = $0.0000
	IF @equ <> 0 AND @last_op_date IS NOT NULL
		SET @start_balance_equ = ROUND(dbo.get_equ(@start_balance, @iso, @last_op_date),2)
	-- @start_balance_equ–ში არის დახურული დღის ნაშთი

	-- Last Real Operation
	INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, ACC_ID, SALDO, SALDO_EQU)
	VALUES (-3, -300, CASE WHEN @last_op_date IS NULL THEN '01/01/1990' ELSE @last_op_date END, NULL, @start_balance, @start_balance_equ)

	-- Last Operation
	IF @equ = 0	
		INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, ACC_ID, SALDO, SALDO_EQU)
		SELECT -2, -200, CASE WHEN @last_op_date IS NULL THEN '01/01/1990' ELSE @last_op_date END, NULL, @start_balance, null

	INSERT INTO @tbl (REC_ID, DOC_TYPE, DT, ACC_ID, DOC_NUM, OP_CODE, DESCRIP, REC_STATE, PARENT_REC_ID, ACCOUNT_EXTRA,	DOC_DATE_IN_DOC, IS_ARC, DBO, DBO_EQU, CRO, CRO_EQU, SALDO, SALDO_EQU)
	SELECT D.REC_ID, D.DOC_TYPE, S.DT,
		CASE @acc_id WHEN D.DEBIT_ID  THEN D.CREDIT_ID ELSE D.DEBIT_ID END as ACC_ID, 
		D.DOC_NUM, D.OP_CODE, D.DESCRIP, D.REC_STATE, D.PARENT_REC_ID, D.ACCOUNT_EXTRA, D.DOC_DATE_IN_DOC,
		CASE WHEN S.DT >= @dt_open THEN 0 ELSE 1 END AS IS_ARC,
		CASE @acc_id WHEN D.DEBIT_ID  THEN D.AMOUNT ELSE NULL END as DBO,
		CASE @acc_id WHEN D.DEBIT_ID  THEN D.AMOUNT_EQU ELSE NULL END as DBO_EQU,
		CASE @acc_id WHEN D.CREDIT_ID THEN D.AMOUNT ELSE NULL END as CRO,
		CASE @acc_id WHEN D.CREDIT_ID THEN D.AMOUNT_EQU ELSE NULL END as CRO_EQU,
		$0.0000 AS SALDO,
		$0.0000 AS SALDO_EQU
	FROM dbo.OPS_HELPER_FULL S(NOLOCK) 
		INNER JOIN dbo.OPS_FULL D(NOLOCK) ON D.REC_ID = S.REC_ID AND (D.DOC_DATE BETWEEN @start_date AND @end_date) AND D.REC_STATE >= @rec_state 	WHERE S.ACC_ID = @acc_id AND S.DT BETWEEN @start_date AND @end_date
	ORDER BY S.DT, S.REC_ID

	IF @equ <> 0
	BEGIN
		DECLARE @prev_rate_date smalldatetime
		SELECT @prev_rate_date = MAX(DT) FROM dbo.VAL_RATES (NOLOCK) WHERE ISO = @iso AND DT < @start_date
		IF @prev_rate_date IS NULL
			SET @prev_rate_date = @start_date
		
		SET @saldo_equ = ROUND(dbo.get_equ(@start_balance, @iso, @prev_rate_date),2)
		SET @start_balance_equ = @saldo_equ 

		INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, ACC_ID, SALDO, SALDO_EQU)
		SELECT -2, -200, CASE WHEN @prev_rate_date < @last_op_date THEN @last_op_date ELSE @prev_rate_date END, NULL, @start_balance, @start_balance_equ

		DECLARE @rates TABLE (
			[ID] int IDENTITY (1,1) NOT NULL,
			DT smalldatetime, 
			RATE decimal(32,12), 
			PRIMARY KEY CLUSTERED([ID])
		)

		INSERT INTO @rates
		SELECT DT, CONVERT(decimal(32,12), AMOUNT) / ITEMS
		FROM dbo.VAL_RATES (NOLOCK)
		WHERE DT BETWEEN @prev_rate_date AND @end_date AND ISO = @iso
		ORDER BY DT

		INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, ACC_ID, OP_CODE, DESCRIP, RATE_DIFF)
		SELECT -1, -1, A.DT, NULL, '*R' + @iso, 'ÂÀÃÀ×ÀÓÄÁÀ', (A.RATE - B.RATE)
		FROM @rates A
			INNER JOIN @rates B ON B.ID = A.ID -1
		WHERE A.RATE <> B.RATE
	END

	DECLARE 
		@old_balance money

	SET @saldo = @start_balance
	UPDATE @tbl
	SET 
		@old_balance = @saldo,
		DBO_EQU = ROUND( NULLIF (ISNULL(DBO_EQU, $0.0000) + CASE WHEN RATE_DIFF * @old_balance > 0 THEN ISNULL(RATE_DIFF * @old_balance, $0.0000) ELSE $0.0000 END, $0.0000), 2),
		CRO_EQU = ROUND( NULLIF (ISNULL(CRO_EQU, $0.0000) + CASE WHEN RATE_DIFF * @old_balance > 0 THEN $0.0000 ELSE -ISNULL(RATE_DIFF * @old_balance, $0.0000) END, $0.0000), 2),
		@saldo = @old_balance + ISNULL(DBO, $0.0000) - ISNULL(CRO, $0.0000), 
		SALDO = @saldo
	WHERE REC_ID > -2

	IF @equ <> 0
	BEGIN
		DELETE FROM @tbl
		WHERE DOC_TYPE = -1 AND (SALDO = $0.0000 OR DBO_EQU = $0.0000 OR CRO_EQU = $0.0000)

		SET @saldo_equ = @start_balance_equ
		UPDATE @tbl
		SET 
			@saldo_equ = CASE WHEN @equ = 0 THEN NULL ELSE @saldo_equ + ISNULL(DBO_EQU, $0.0000) - ISNULL(CRO_EQU, $0.0000) END,
			SALDO_EQU = @saldo_equ 
		WHERE REC_ID > -2

		DECLARE @end_saldos TABLE (DT smalldatetime PRIMARY KEY, SALDO money, SALDO_EQU money)

		INSERT INTO @end_saldos
		SELECT A.DT, A.SALDO, A.SALDO_EQU
		FROM @tbl A
		WHERE A.REC_ID > -2 AND A.REC_ID = (SELECT MAX(B.REC_ID) FROM @tbl B WHERE B.DT = A.DT)

		DECLARE
			@delta money,
			@saldo_delta money,
			@dt smalldatetime
			
		SET @delta = $0.0000
		SET @saldo_delta = $0.0000

		DECLARE cc CURSOR LOCAL FAST_FORWARD 
		FOR
		SELECT * FROM @end_saldos
		ORDER BY DT

		OPEN cc
		FETCH NEXT FROM cc INTO @dt, @saldo, @saldo_equ
		WHILE @@fetch_status = 0
		BEGIN
			SET @delta = ROUND(dbo.get_equ(@saldo, @iso, @dt), 2) - @saldo_equ - @saldo_delta
			IF @delta <> $0.0000
			BEGIN
				INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, OP_CODE, DESCRIP, ACC_ID, DBO, DBO_EQU, CRO, CRO_EQU, SALDO, SALDO_EQU)
				SELECT 1999999998, -1, @dt, '*RND', 'ÃÀÌÒÂÅÀËÄÁÀ', NULL, 
					$0.0000, CASE WHEN @delta > $0.00 THEN @delta ELSE NULL END, 
					$0.0000, CASE WHEN @delta < $0.00 THEN -@delta ELSE NULL END, 
					@saldo, NULL

				SET @saldo_delta = @saldo_delta + @delta
			END

			FETCH NEXT FROM cc INTO @dt, @saldo, @saldo_equ
		END
		CLOSE cc
		DEALLOCATE cc
	END

	INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, ACC_ID, OP_CODE, DBO, CRO, DBO_EQU, CRO_EQU)
	SELECT 1999999999, -150, A.DT, NULL, NULL, SUM(DBO), SUM(CRO), SUM(DBO_EQU), SUM(CRO_EQU)
	FROM @tbl A
	WHERE A.REC_ID > -2
	GROUP BY A.DT

	SET @saldo_equ = @start_balance_equ
	SET @saldo = @start_balance
	UPDATE @tbl
	SET 
		@saldo = CASE WHEN DOC_TYPE = -150 THEN @saldo ELSE @saldo + ISNULL(DBO, $0.0000) - ISNULL(CRO, $0.0000) END,
		@saldo_equ = CASE WHEN @equ = 0 THEN NULL ELSE CASE WHEN DOC_TYPE = -150 THEN @saldo_equ ELSE @saldo_equ + ISNULL(DBO_EQU, $0.0000) - ISNULL(CRO_EQU, $0.0000) END END,
		SALDO = @saldo,
		SALDO_EQU = @saldo_equ
	WHERE REC_ID > -2

	IF @start_date0 > @start_date
	BEGIN
		DECLARE 
			@_dt1 smalldatetime,
			@_dt2 smalldatetime,
			@_saldo_equ money

		SELECT @_dt1 = DT, @_saldo_equ = SALDO_EQU
		FROM @tbl
		WHERE DT = (SELECT MAX(DT) FROM @tbl WHERE DT < @start_date0 AND DOC_TYPE <> -1)

		SELECT @_dt2 = DT, @start_balance = SALDO, @start_balance_equ = SALDO_EQU
		FROM @tbl
		WHERE DT = (SELECT MAX(DT) FROM @tbl WHERE DT < @start_date0 AND REC_ID = 1999999999 AND DOC_TYPE = -150)

		IF @_dt2 IS NULL OR @_dt2 < @_dt1
			SET @_dt2 = @_dt1

		DELETE FROM @tbl
		WHERE DT < @start_date0

		INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, ACC_ID, SALDO, SALDO_EQU)
		VALUES (-3, -300, @_dt1, NULL, @start_balance, @_saldo_equ)

		INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, ACC_ID, SALDO, SALDO_EQU)
		VALUES (-2, -200, @_dt2, NULL, @start_balance, @start_balance_equ)
	END

	IF @show_subsums = 0
	BEGIN
		DELETE FROM @tbl
		WHERE REC_ID = 1999999999 AND DOC_TYPE = -150
	END

		
	INSERT INTO @tbl(REC_ID, DOC_TYPE, DT, ACC_ID, DBO, DBO_EQU, CRO, CRO_EQU, SALDO, SALDO_EQU)
	SELECT 2000000000, -100, @end_date, NULL, SUM(DBO), SUM(DBO_EQU), SUM(CRO), SUM(CRO_EQU), @saldo, @saldo_equ
	FROM @tbl
	WHERE DOC_TYPE <> -150

	INSERT INTO @statement
	SELECT T.REC_ID, T.DOC_TYPE, T.DT, A.ACCOUNT, A.ACC_ID, T.DESCRIP, 
		CASE WHEN @show_extra_info <> 0 THEN dbo.ops_get_extra_info(T.REC_ID, A.ACC_ID, T.DOC_TYPE, CASE WHEN T.DBO > $0 THEN 1 ELSE 0 END, T.IS_ARC) ELSE NULL END AS EXTRA_INFO,
		T.DOC_NUM, T.OP_CODE, T.REC_STATE, T.PARENT_REC_ID, T.ACCOUNT_EXTRA, T.DOC_DATE_IN_DOC, T.IS_ARC,
		T.DBO, T.DBO_EQU, T.CRO, T.CRO_EQU, T.SALDO, T.SALDO_EQU,
		CASE WHEN T.REC_ID < 0 THEN T.REC_ID WHEN T.REC_ID >= 1999999998 THEN T.REC_ID - 1999999997 ELSE 0 END
	FROM @tbl T
		LEFT JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = T.ACC_ID
	
	RETURN
END
GO
