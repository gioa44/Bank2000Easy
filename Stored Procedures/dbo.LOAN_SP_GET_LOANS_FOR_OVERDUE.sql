SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOANS_FOR_OVERDUE]
	@user_id int,
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL,
	@date smalldatetime,
	@loan_id int = NULL,
	@distinct bit = 0
AS
SET NOCOUNT ON

DECLARE 
	@r int,
	@e int

CREATE TABLE #tbl1 (
	LOAN_ID int NOT NULL PRIMARY KEY,
	OVERDUE_DELAY bit NOT NULL,
	OVERDUE_AMOUNT money,
	OVERDUE_PRINCIPAL money,
	OVERDUE_PERCENT money,
	OVERDUE_INSURANCE money,
	OVERDUE_SERVICE_FEE money
)

CREATE TABLE #tbl_late(
	LOAN_ID			int NOT NULL,
	LATE_DATE			smalldatetime NOT NULL,
	LATE_OP_ID		int NOT NULL,
	LATE_PRINCIPAL	money NULL,
	LATE_PERCENT		money NULL 
	PRIMARY KEY (LOAN_ID, LATE_DATE)
)

CREATE TABLE #tbl_overdue(
	LOAN_ID			int NOT NULL,
	OVERDUE_DATE		smalldatetime NOT NULL,	
	LATE_OP_ID		int NULL,
	OVERDUE_OP_ID		int NOT NULL,
	OVERDUE_PRINCIPAL int NULL,
	OVERDUE_PERCENT	int NULL 
	PRIMARY KEY (LOAN_ID, OVERDUE_DATE)
)

CREATE TABLE #tbl (LOAN_ID INT PRIMARY KEY)

DECLARE 
	@bank_open_date smalldatetime,
	@loan_open_date smalldatetime,
	@l_late_days int
 
SET @bank_open_date  = dbo.bank_open_date()
SET @loan_open_date = dbo.loan_open_date()
EXEC dbo.GET_SETTING_INT 'L_LATE_DAYS', @l_late_days OUTPUT

IF @date < @loan_open_date
BEGIN
	RAISERROR ('<ERR>ÓÀÓÄÓáÏ ÌÏÃÖËÉ ÀÌ ÈÀÒÉÙÉÓÈÅÉÓ ÃÀáÖÒÖËÉÀ!</ERR>', 16, 1)
	SELECT * FROM #tbl1 A
		INNER JOIN dbo.LOAN_VW_LOANS L ON A.LOAN_ID = L.LOAN_ID
	RETURN (1)
END

IF @date < @bank_open_date
BEGIN
	RAISERROR ('<ERR>ÁÀÍÊÉÓ ÓÀÏÐÄÒÀÝÉÏ ÃÙÄ ÀÌ ÈÀÒÉÙÉÓÈÅÉÓ ÃÀáÖÒÖËÉÀ!</ERR>', 16, 1)
	SELECT * FROM #tbl1 A
		INNER JOIN dbo.LOAN_VW_LOANS L ON A.LOAN_ID = L.LOAN_ID
	RETURN (1)
END

DECLARE --სესხის დეტალები
	@calc_date smalldatetime,
	@prev_step smalldatetime,
	@late_date smalldatetime,
	@overdue_date smalldatetime,
	@calloff_date smalldatetime,
	@writeoff_date smalldatetime,
	@nu_principal money,
	@nu_principal_ money,
	@nu_principal_payed money,
	@nu_interest money,
	@nu_interest_ money,
	@nu_interest_payed money,
	@principal money,
	@principal_ money,
	@principal_payed money,
	@interest money,
	@interest_ money,
	@interest_payed money,

	@late_principal money,
	@late_principal_ money,
	@late_principal_payed money,	
	@late_percent money,
	@late_percent_ money,
	@late_percent_payed money,
	@overdue_principal money,
	@overdue_principal_ money,
	@overdue_principal_payed money,
	@overdue_principal_interest money,
	@overdue_principal_interest_ money,
	@overdue_principal_interest_payed money,
	@overdue_principal_penalty money,
	@overdue_principal_penalty_ money,
	@overdue_principal_penalty_payed money,
	@overdue_percent money,
	@overdue_percent_ money,
	@overdue_percent_payed money,
	@overdue_percent_penalty money,
	@overdue_percent_penalty_ money,
	@overdue_percent_penalty_payed money,
	@calloff_principal money,
	@calloff_principal_ money,
	@calloff_principal_payed money,
	@calloff_principal_interest money,
	@calloff_principal_interest_ money,
	@calloff_principal_interest_payed money,
	@calloff_principal_penalty money,
	@calloff_principal_penalty_ money,
	@calloff_principal_penalty_payed money,
	@calloff_percent money,
	@calloff_percent_ money,
	@calloff_percent_payed money,
	@calloff_percent_penalty money,
	@calloff_percent_penalty_ money,
	@calloff_percent_penalty_payed money,
	@calloff_penalty money,       
	@calloff_penalty_ money,
	@calloff_penalty_payed money,
	@writeoff_principal money,
	@writeoff_principal_ money,
	@writeoff_principal_payed money,	
	@writeoff_principal_penalty money,
	@writeoff_principal_penalty_ money, 
	@writeoff_principal_penalty_payed money,
	@writeoff_percent money,
	@writeoff_percent_ money,
	@writeoff_percent_payed money,
	@writeoff_percent_penalty money,
	@writeoff_percent_penalty_ money,
	@writeoff_percent_penalty_payed money,
	@writeoff_penalty money,
	@writeoff_penalty_ money,
	@writeoff_penalty_payed money,
	@immediate_penalty money,
	@immediate_penalty_ money,
	@immediate_penalty_payed money,
	@fine money,
	@fine_ money,
	@fine_payed money,
	@schedule_insurance_payed money,
	@schedule_service_fee_payed money,

	@schedule_defered_interest			money,
	@schedule_defered_overdue_interest	money,
	@schedule_defered_penalty			money,
	@schedule_defered_fine				money,
	@schedule_defered_interest_			money,
	@schedule_defered_overdue_interest_	money,
	@schedule_defered_penalty_			money,
	@schedule_defered_fine_				money,
	@schedule_defered_interest_payed			money,
	@schedule_defered_overdue_interest_payed	money,
	@schedule_defered_penalty_payed				money,
	@schedule_defered_fine_payed				money,

	@overdue_insurance_ money,
	@overdue_service_fee_ money,
	@overdue_insurance_payed money,
	@overdue_service_fee_payed money,

	@deferable_interest money, 
	@deferable_overdue_interest money, 
	@deferable_penalty money,
	@deferable_fine money

DECLARE
	@schedule_date				smalldatetime,
	@schedule_interest_date		smalldatetime,
	@schedule_principal			money,
	@schedule_interest			money,
	@schedule_nu_interest		money,
	@schedule_balance			money,
	@schedule_pay_interest		bit,
	@schedule_principal_		money,
	@schedule_interest_			money,
	@schedule_nu_interest_		money,
	@schedule_insurance			money,
	@schedule_service_fee		money,
	@schedule_insurance_		money,
	@schedule_service_fee_		money


DECLARE
	@overdue_insurance money,
	@overdue_service_fee money


DECLARE
	@agreement_no			varchar(100),
	@branch_id				int,
	@dept_no				int,
	@client_no				int,
	@client_amount			money,
	@debt_amount			money,
	@client_amount_			money,
	@iso					TISO,
	@disburse_type			int,
	@guarantee				bit,
	@state					tinyint,
	@acc_id					int

DECLARE
	@parent_op_id int,
	@child_op_id int,
	@op_commit bit,
	@late_op_id int
DECLARE
	@step_late_date smalldatetime,
	@step_late_percent money,
	@step_late_principal money
DECLARE
	@step_overdue_date smalldatetime,
	@step_overdue_percent money,
	@step_overdue_principal money,
	@step_overdue_insurance money,
	@step_overdue_service_fee money,
	@step_defered_interest money

DECLARE
	@overdue_amount money,
	@op_details xml


INSERT INTO #tbl
EXEC dbo.loan_show_loans
	@user_id = @user_id,
	@right_name = 'ÍÀáÅÀ',
	@field_list = 'L.LOAN_ID',
	@view_name = 'dbo.LOANS',
	@where_sql1 = @where_sql1,
	@where_sql2 = @where_sql2,
	@where_sql3 = @where_sql3,
	@join_sql = @join_sql,
	@distinct = @distinct

 
DECLARE cr CURSOR FAST_FORWARD LOCAL FOR
SELECT L.LOAN_ID, L.AGREEMENT_NO, L.BRANCH_ID, L.DEPT_NO, L.CLIENT_NO, L.ISO, L.DISBURSE_TYPE, L.STATE, 
	D.CALC_DATE, D.PREV_STEP, ISNULL(D.NU_PRINCIPAL,$0.00), ISNULL(D.NU_INTEREST,$0.00), ISNULL(D.PRINCIPAL,$0.00), ISNULL(D.INTEREST,$0.00),
	D.LATE_DATE, ISNULL(D.LATE_PRINCIPAL,$0.00), ISNULL(D.LATE_PERCENT,$0.00),
	D.OVERDUE_DATE, ISNULL(D.OVERDUE_PRINCIPAL,$0.00), ISNULL(D.OVERDUE_PRINCIPAL_INTEREST,$0.00), ISNULL(D.OVERDUE_PRINCIPAL_PENALTY,$0.00),
	ISNULL(D.OVERDUE_PERCENT,$0.00), ISNULL(D.OVERDUE_PERCENT_PENALTY,$0.00),
	L.CALLOFF_DATE, ISNULL(D.CALLOFF_PRINCIPAL,$0.00), ISNULL(D.CALLOFF_PRINCIPAL_INTEREST,$0.00), ISNULL(D.CALLOFF_PRINCIPAL_PENALTY,$0.00),
	ISNULL(D.CALLOFF_PERCENT,$0.00), ISNULL(D.CALLOFF_PERCENT_PENALTY,$0.00), ISNULL(D.CALLOFF_PENALTY,$0.00),
	L.WRITEOFF_DATE, ISNULL(D.WRITEOFF_PRINCIPAL,$0.00), ISNULL(D.WRITEOFF_PRINCIPAL_PENALTY,$0.00),
	ISNULL(D.WRITEOFF_PERCENT,$0.00), ISNULL(D.WRITEOFF_PERCENT_PENALTY,$0.00), ISNULL(D.WRITEOFF_PENALTY,$0.00),
	ISNULL(D.IMMEDIATE_PENALTY,$0.00), ISNULL(D.FINE,$0.00),
	ISNULL(D.OVERDUE_INSURANCE,$0.00), ISNULL(D.OVERDUE_SERVICE_FEE,$0.00),
	ISNULL(D.DEFERABLE_INTEREST, $0.00), ISNULL(D.DEFERABLE_OVERDUE_INTEREST, $0.00), ISNULL(D.DEFERABLE_PENALTY, $0.00), 
	ISNULL(D.DEFERABLE_FINE, $0.00), L.GUARANTEE
FROM #tbl tbl 
	INNER JOIN dbo.LOANS L ON tbl.LOAN_ID = L.LOAN_ID
	INNER JOIN dbo.LOAN_DETAILS D ON D.LOAN_ID = L.LOAN_ID
WHERE (@loan_id IS NULL OR L.LOAN_ID = @loan_id) AND (D.CALC_DATE = @date)

OPEN cr
FETCH NEXT FROM cr
INTO @loan_id, @agreement_no,  @branch_id, @dept_no, @client_no, @iso, @disburse_type, @state, 
	@calc_date, @prev_step, @nu_principal, @nu_interest, @principal, @interest,
	@late_date, @late_principal, @late_percent, 
	@overdue_date, @overdue_principal, @overdue_principal_interest, @overdue_principal_penalty,
	@overdue_percent, @overdue_percent_penalty,
	@calloff_date, @calloff_principal, @calloff_principal_interest, @calloff_principal_penalty,
	@calloff_percent, @calloff_percent_penalty, @calloff_penalty,
	@writeoff_date, @writeoff_principal, @writeoff_principal_penalty,
	@writeoff_percent, @writeoff_percent_penalty, @writeoff_penalty,
	@immediate_penalty, @fine, @overdue_insurance, @overdue_service_fee,
	@deferable_interest, @deferable_overdue_interest, @deferable_penalty, @deferable_fine, @guarantee


WHILE @@FETCH_STATUS = 0
BEGIN
	SET @overdue_amount = $0.00

	SET @schedule_date = NULL
	SET @schedule_interest_date = NULL
	SET @schedule_principal = NULL
	SET @schedule_interest = NULL
	SET @schedule_balance = NULL
	SET @schedule_pay_interest = NULL


	SET @nu_principal_					= @nu_principal
	SET @nu_interest_					= @nu_interest
	SET @principal_						= @principal
	SET @interest_						= @interest
	SET @late_principal_				= @late_principal
	SET @late_percent_					= @late_percent
	SET @overdue_principal_				= @overdue_principal
	SET @overdue_principal_interest_	= @overdue_principal_interest
	SET @overdue_principal_penalty_		= @overdue_principal_penalty
	SET @overdue_percent_				= @overdue_percent
	SET @overdue_percent_penalty_		= @overdue_percent_penalty
	SET @calloff_principal_				= @calloff_principal
	SET @calloff_principal_interest_	= @calloff_principal_interest
	SET @calloff_principal_penalty_		= @calloff_principal_penalty
	SET @calloff_percent_				= @calloff_percent
	SET @calloff_percent_penalty_		= @calloff_percent_penalty
	SET @calloff_penalty_				= @calloff_penalty
	SET @writeoff_principal_			= @writeoff_principal
	SET @writeoff_principal_penalty_	= @writeoff_principal_penalty
	SET @writeoff_percent_				= @writeoff_percent
	SET @writeoff_percent_penalty_		= @writeoff_percent_penalty
	SET @writeoff_penalty_				= @writeoff_penalty
	SET @immediate_penalty_				= @immediate_penalty
	SET @fine_							= @fine

	SET @schedule_insurance_			= @schedule_insurance
	SET @schedule_service_fee_			= @schedule_service_fee
	SET @overdue_insurance_				= @overdue_insurance
	SET @overdue_service_fee_			= @overdue_service_fee

	SET @schedule_defered_interest_			= @schedule_defered_interest
	SET @schedule_defered_overdue_interest_ = @schedule_defered_overdue_interest
	SET @schedule_defered_penalty_			= @schedule_defered_penalty
	SET @schedule_defered_fine_				= @schedule_defered_fine


	SELECT TOP 1 @schedule_date=SCHEDULE_DATE, @schedule_interest_date=INTEREST_DATE, @schedule_principal=PRINCIPAL, @schedule_interest=INTEREST, @schedule_nu_interest=NU_INTEREST, @schedule_balance=BALANCE, @schedule_pay_interest=PAY_INTEREST
	FROM dbo.LOAN_SCHEDULE
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @date AND ORIGINAL_AMOUNT IS NOT NULL AND (ISNULL(AMOUNT, $0.00) > $0.00 OR  @disburse_type = 4)
	ORDER BY SCHEDULE_DATE

	SELECT TOP 1 @schedule_insurance = INSURANCE, @schedule_service_fee = CASE WHEN @date = SCHEDULE_DATE THEN SERVICE_FEE ELSE $0.00 END,
					@schedule_defered_interest = ISNULL(DEFERED_INTEREST, $0.00), @schedule_defered_overdue_interest = ISNULL(DEFERED_OVERDUE_INTEREST, $0.00),
					@schedule_defered_penalty = ISNULL(DEFERED_PENALTY, $0.00), @schedule_defered_fine = ISNULL(DEFERED_FINE, $0.00)
	FROM dbo.LOAN_SCHEDULE
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @date AND ORIGINAL_AMOUNT IS NOT NULL
	ORDER BY SCHEDULE_DATE

	IF @disburse_type = 4
	BEGIN
		IF @schedule_date = @date
		BEGIN
			SET @schedule_principal = @principal - @schedule_balance
			
			IF @schedule_principal < 0
				SET @schedule_principal = $0.00

			IF @schedule_pay_interest = 0 
			BEGIN
				SET @schedule_nu_interest = $0.00
				SET @schedule_interest = $0.00
			END
			ELSE
			BEGIN
				SET @schedule_nu_interest = @nu_interest
				SET @schedule_interest = @interest
			END
		END
		ELSE
		BEGIN
			SET @schedule_principal = $0.00	
			SET @schedule_interest = $0.00
			SET @schedule_nu_interest = $0.00
		END
	END

	DELETE FROM #tbl_late
	INSERT INTO #tbl_late(LOAN_ID,LATE_DATE,LATE_OP_ID,LATE_PRINCIPAL,LATE_PERCENT) 
	SELECT LOAN_ID,LATE_DATE,LATE_OP_ID,LATE_PRINCIPAL,LATE_PERCENT
	FROM dbo.LOAN_DETAIL_LATE (NOLOCK)
	WHERE LOAN_ID = @loan_id

	DELETE FROM #tbl_overdue
	INSERT INTO #tbl_overdue(LOAN_ID,OVERDUE_DATE,LATE_OP_ID,OVERDUE_OP_ID,OVERDUE_PRINCIPAL,OVERDUE_PERCENT)
	SELECT LOAN_ID,OVERDUE_DATE,LATE_OP_ID,OVERDUE_OP_ID,OVERDUE_PRINCIPAL,OVERDUE_PERCENT
	FROM dbo.LOAN_DETAIL_OVERDUE (NOLOCK)
	WHERE LOAN_ID = @loan_id

	SET @debt_amount =
			@late_principal + @late_percent +
			@overdue_principal + @overdue_principal_interest + @overdue_principal_penalty +
			@overdue_percent + @overdue_percent_penalty +
			@calloff_principal + @calloff_principal_interest + @calloff_principal_penalty +
			@calloff_percent + @calloff_percent_penalty + @calloff_penalty +
			@writeoff_principal + @writeoff_principal_penalty + 
			@writeoff_percent + @writeoff_percent_penalty +	@writeoff_penalty +
			@fine + @overdue_insurance + @overdue_service_fee

	IF @schedule_date = @date
		SET @debt_amount = @debt_amount + @schedule_nu_interest + @schedule_principal + @schedule_interest + ISNULL(@schedule_insurance, $0.00) + ISNULL(@schedule_service_fee, $0.00) + 
								ISNULL(@schedule_defered_interest, $0.00) + ISNULL(@schedule_defered_overdue_interest, $0.00) + ISNULL(@schedule_defered_penalty, $0.00) + ISNULL(@schedule_defered_fine, $0.00)

	SELECT @acc_id = L.ACC_ID
	FROM dbo.LOAN_ACCOUNTS L
	WHERE L.LOAN_ID = @loan_id AND L.ACCOUNT_TYPE = 20 -- ÓÄÓáÉÓ ÀÍÂÀÒÉÛÓßÏÒÄÁÉÓ ÀÍÂÀÒÉÛÉ


	SET @client_amount = $0.00
	IF @debt_amount > $0.00 
	BEGIN
		EXEC @r = dbo.LOAN_SP_COLLECTION_CLIENT_AMOUNT
				@user_id = 2,
				@date = @date,
				@loan_id = @loan_id,
				@iso = @iso,
				@acc_id = @acc_id,
				@client_no = @client_no,
				@debt_amount = @debt_amount,
				@simulate = 1,
				@client_amount = @client_amount OUTPUT

		SET @e = @@ERROR
		IF (@r <> 0) OR (@e <> 0) GOTO _ret
	END

	IF @client_amount < $0.00
		SET @client_amount = $0.00

	SET @client_amount_ = @client_amount
	IF @client_amount_ = $0.00 GOTO _skip_payment

	EXEC @r = dbo.loan_process_payment
		@loan_id						= @loan_id,
		@date							= @date,
		@op_commit						= @op_commit OUTPUT,
		@amount							= @client_amount OUTPUT,
		@schedule_date					= @schedule_date,
		@schedule_principal				= @schedule_principal OUTPUT,
		@schedule_interest				= @schedule_interest OUTPUT,
		@schedule_nu_interest			= @schedule_nu_interest OUTPUT,
		@schedule_insurance				= @schedule_insurance OUTPUT,
		@schedule_service_fee			= @schedule_service_fee OUTPUT,
		@schedule_defered_interest			= @schedule_defered_interest OUTPUT,
		@schedule_defered_overdue_interest	= @schedule_defered_overdue_interest OUTPUT,
		@schedule_defered_penalty			= @schedule_defered_penalty OUTPUT,
		@schedule_defered_fine				= @schedule_defered_fine OUTPUT,
		@writeoff_date					= @writeoff_date OUTPUT,
		@writeoff_principal				= @writeoff_principal OUTPUT,
		@writeoff_principal_penalty		= @writeoff_principal_penalty OUTPUT,
		@writeoff_percent				= @writeoff_percent OUTPUT,
		@writeoff_percent_penalty		= @writeoff_percent_penalty OUTPUT,
		@writeoff_penalty				= @writeoff_penalty OUTPUT,
		@calloff_date					= @calloff_date OUTPUT,
		@calloff_principal				= @calloff_principal OUTPUT,
		@calloff_principal_interest		= @calloff_principal_interest OUTPUT,
		@calloff_principal_penalty		= @calloff_principal_penalty OUTPUT,
		@calloff_percent				= @calloff_percent OUTPUT,
		@calloff_percent_penalty		= @calloff_percent_penalty OUTPUT,
		@calloff_penalty				= @calloff_penalty OUTPUT,
		@overdue_date					= @overdue_date OUTPUT,
		@overdue_principal				= @overdue_principal OUTPUT,
		@overdue_principal_interest		= @overdue_principal_interest OUTPUT,
		@overdue_principal_penalty		= @overdue_principal_penalty OUTPUT,
		@overdue_percent				= @overdue_percent OUTPUT,
		@overdue_percent_penalty		= @overdue_percent_penalty OUTPUT,
		@nu_interest					= @nu_interest OUTPUT,
		@interest						= @interest OUTPUT,
		@principal						= @principal OUTPUT,
		@overdue_insurance				= @overdue_insurance OUTPUT,
		@overdue_service_fee				= @overdue_service_fee OUTPUT,
		@deferable_interest					= @deferable_interest OUTPUT,
		@deferable_overdue_interest			= @deferable_overdue_interest OUTPUT,
		@deferable_penalty					= @deferable_penalty OUTPUT,
		@deferable_fine						= @deferable_fine OUTPUT

	SET @e = @@ERROR
	IF @r <> 0 OR @e <> 0 GOTO _ret

	IF @op_commit = 1
	BEGIN
		SET @principal_payed					= @principal - @principal_
		SET @nu_principal_payed					= @nu_principal + @principal_payed
		SET @nu_interest_payed					= @nu_interest - @nu_interest_
		SET @interest_payed						= @interest - @interest_
		SET @late_principal_payed				= @late_principal - @late_principal_
		SET @late_percent_payed					= @late_percent - @late_percent_
		SET @overdue_principal_payed			= @overdue_principal - @overdue_principal_
		SET @overdue_principal_interest_payed	= @overdue_principal_interest - @overdue_principal_interest_
		SET @overdue_principal_penalty_payed	= @overdue_principal_penalty - @overdue_principal_penalty_
		SET @overdue_percent_payed				= @overdue_percent - @overdue_percent_
		SET @overdue_percent_penalty_payed		= @overdue_percent_penalty - @overdue_percent_penalty_
		SET @calloff_principal_payed			= @calloff_principal - @calloff_principal_
		SET @calloff_principal_interest_payed	= @calloff_principal_interest - @calloff_principal_interest_
		SET @calloff_principal_penalty_payed	= @calloff_principal_penalty - @calloff_principal_penalty_
		SET @calloff_percent_payed				= @calloff_percent - @calloff_percent_
		SET @calloff_percent_penalty_payed		= @calloff_percent_penalty - @calloff_percent_penalty_
		SET @calloff_penalty_payed				= @calloff_penalty - @calloff_penalty_
		SET @writeoff_principal_payed			= @writeoff_principal - @writeoff_principal_
		SET @writeoff_principal_penalty_payed	= @writeoff_principal_penalty - @writeoff_principal_penalty_
		SET @writeoff_percent_payed				= @writeoff_percent - @writeoff_percent_
		SET @writeoff_percent_penalty_payed		= @writeoff_percent_penalty - @writeoff_percent_penalty_
		SET @writeoff_penalty_payed				= @writeoff_penalty - @writeoff_penalty_
		SET @immediate_penalty_payed			= @immediate_penalty - @immediate_penalty_
		SET @fine_payed							= @fine - @fine_

		SET @schedule_insurance_payed			= @schedule_insurance_ - @schedule_insurance
		SET @schedule_service_fee_payed			= @schedule_service_fee_ - @schedule_service_fee
		SET @overdue_insurance_payed			= @overdue_insurance_ - @overdue_insurance
		SET @overdue_service_fee_payed			= @overdue_service_fee_ - @overdue_service_fee

		SET @schedule_defered_interest_payed			= @schedule_defered_interest_ - @schedule_defered_interest
		SET @schedule_defered_overdue_interest_payed	= @schedule_defered_overdue_interest_ - @schedule_defered_overdue_interest
		SET @schedule_defered_penalty_payed				= @schedule_defered_penalty_ - @schedule_defered_penalty
		SET @schedule_defered_fine_payed				= @schedule_defered_fine_ - @schedule_defered_fine

	END	

_skip_payment:
	EXEC @r = dbo.loan_process_overdue
		@loan_id					= @loan_id,
		@date						= @date,
		@op_commit					= @op_commit OUTPUT,
		@schedule_date				= @schedule_date,
		@schedule_nu_interest		= @schedule_nu_interest OUTPUT,
		@schedule_interest			= @schedule_interest OUTPUT,
		@schedule_principal			= @schedule_principal OUTPUT,
		@schedule_insurance			= @schedule_insurance OUTPUT,
		@schedule_service_fee		= @schedule_service_fee OUTPUT,
		@schedule_defered_interest	= @schedule_defered_interest OUTPUT,
		@nu_interest				= @nu_interest OUTPUT,
		@interest					= @interest OUTPUT,
		@principal					= @principal OUTPUT,
		@deferable_interest			= @deferable_interest OUTPUT,
		@overdue_percent			= @overdue_percent OUTPUT,
		@overdue_principal			= @overdue_principal OUTPUT,
		@step_overdue_percent		= @step_overdue_percent OUTPUT,
		@step_overdue_principal		= @step_overdue_principal OUTPUT,
		@overdue_insurance			= @overdue_insurance OUTPUT,
		@overdue_service_fee		= @overdue_service_fee OUTPUT,
		@step_overdue_insurance		= @step_overdue_insurance OUTPUT,
		@step_overdue_service_fee	= @step_overdue_service_fee OUTPUT,
		@step_defered_interest		= @step_defered_interest OUTPUT,
		@op_details					= @op_details OUTPUT

	SET @e = @@ERROR
	IF @r <> 0 OR @e <> 0 GOTO _ret


	IF @op_commit = 1
	BEGIN
		SET @overdue_amount = @step_overdue_percent + @step_overdue_principal + @step_overdue_insurance + @step_overdue_service_fee + @step_defered_interest
	END

	IF @overdue_amount > $0.00
	BEGIN
--		INSERT INTO #tbl1 (LOAN_ID, OVERDUE_DELAY, BRANCH_ID, DEPT_NO,	STATE, CLIENT_NO, AGREEMENT_NO, ISO, GUARANTEE, OVERDUE_AMOUNT, OVERDUE_PRINCIPAL, OVERDUE_PERCENT, OVERDUE_INSURANCE, OVERDUE_SERVICE_FEE)
--		VALUES(@loan_id, 0,  @branch_id, @dept_no, @state, @client_no, @agreement_no, @iso, @guarantee, @overdue_amount, @step_overdue_principal, @step_overdue_percent, @step_overdue_insurance, @step_overdue_service_fee)
		INSERT INTO #tbl1 (LOAN_ID, OVERDUE_DELAY, OVERDUE_AMOUNT, OVERDUE_PRINCIPAL, OVERDUE_PERCENT, OVERDUE_INSURANCE, OVERDUE_SERVICE_FEE)
		VALUES(@loan_id, 0,  @overdue_amount, @step_overdue_principal, @step_overdue_percent, @step_overdue_insurance, @step_overdue_service_fee)
	END

	FETCH NEXT FROM cr
	INTO @loan_id, @agreement_no,  @branch_id, @dept_no, @client_no, @iso, @disburse_type, @state,
		@calc_date, @prev_step, @nu_principal, @nu_interest, @principal, @interest,  
		@late_date, @late_principal, @late_percent, 
		@overdue_date, @overdue_principal, @overdue_principal_interest, @overdue_principal_penalty,
		@overdue_percent, @overdue_percent_penalty,
		@calloff_date, @calloff_principal, @calloff_principal_interest, @calloff_principal_penalty,
		@calloff_percent, @calloff_percent_penalty, @calloff_penalty,
		@writeoff_date, @writeoff_principal, @writeoff_principal_penalty,
		@writeoff_percent, @writeoff_percent_penalty, @writeoff_penalty,
		@immediate_penalty, @fine, @overdue_insurance, @overdue_service_fee,
		@deferable_interest, @deferable_overdue_interest, @deferable_penalty, @deferable_fine, @guarantee
END

_ret:
CLOSE cr
DEALLOCATE cr
DROP TABLE #tbl_late
DROP TABLE #tbl_overdue

UPDATE #tbl1
SET OVERDUE_DELAY = 1
FROM #tbl1 T
	INNER JOIN dbo.LOAN_OVERDUE_DELAY D ON T.LOAN_ID = D.LOAN_ID
WHERE D.DELAY_DATE = @date


SELECT * FROM #tbl1 A
	INNER JOIN dbo.LOAN_VW_LOANS L ON A.LOAN_ID = L.LOAN_ID

DROP TABLE #tbl1

RETURN 0
GO
