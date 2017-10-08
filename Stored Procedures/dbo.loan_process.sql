SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[loan_process]
	@date smalldatetime,
	@user_id int,
	@loan_id int
AS

SET NOCOUNT ON;

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

CREATE TABLE #tbl_overdue(
	[LOAN_ID]			int NOT NULL,
	[OVERDUE_DATE]		smalldatetime NOT NULL,	
	[LATE_OP_ID]		int NULL,
	[OVERDUE_OP_ID]		int NOT NULL,
	[OVERDUE_PRINCIPAL] money NULL,
	[OVERDUE_PERCENT]	money NULL 
	PRIMARY KEY ([LOAN_ID], [OVERDUE_DATE])
)

DECLARE
	@_date smalldatetime,
	@r int,
	@doc_rec_id int,
	@acc_id int

DECLARE
	@debt_amount money,
	@debt_amount_without_rate_diff money,
	@prepay_penalty money,
	@illegal_debt money,
	@penalty_debt money

DECLARE --სესხის დეტალები
	@calc_date smalldatetime,
	@prev_step smalldatetime,
	@overdue_date smalldatetime,
	@calloff_date smalldatetime,
	@writeoff_date smalldatetime,
	@linked_ccy TISO,
	@indexed_rate money,
	@rate_diff money,
	@rate_change_ratio money,

	@nu_principal money,
	@nu_principal_ money,
	@nu_principal_payed money,
	@nu_interest money,
	@nu_interest_daily money,
	@nu_interest_fraction TFRACTION,
	@nu_interest_ money,
	@nu_interest_payed money,
	@principal money,
	@principal_ money,
	@principal_payed money,
	@interest money,
	@interest_daily money,
	@interest_fraction TFRACTION,
	@interest_ money,
	@interest_payed money,

	@overdue_principal money,
	@overdue_principal_ money,
	@overdue_principal_payed money,
	@overdue_principal_interest money,
	@overdue_principal_interest_ money,
	@overdue_principal_interest_payed money,
	@overdue_principal_interest_daily money,
	@overdue_principal_interest_fraction TFRACTION,
	@overdue_principal_penalty money,
	@overdue_principal_penalty_ money,
	@overdue_principal_penalty_payed money,
	@overdue_principal_penalty_daily money,
	@overdue_principal_penalty_fraction TFRACTION,     
	@overdue_percent money,
	@overdue_percent_ money,
	@overdue_percent_payed money,
	@overdue_percent_penalty money,
	@overdue_percent_penalty_ money,
	@overdue_percent_penalty_payed money,
	@overdue_percent_penalty_daily money,
	@overdue_percent_penalty_fraction TFRACTION,
	@calloff_principal money,
	@calloff_principal_ money,
	@calloff_principal_payed money,
	@calloff_principal_interest money,
	@calloff_principal_interest_ money,
	@calloff_principal_interest_payed money,
	@calloff_principal_interest_daily money,
	@calloff_principal_interest_fraction TFRACTION,
	@calloff_principal_penalty money,
	@calloff_principal_penalty_ money,
	@calloff_principal_penalty_payed money,
	@calloff_principal_penalty_daily money,
	@calloff_principal_penalty_fraction TFRACTION,
	@calloff_percent money,
	@calloff_percent_ money,
	@calloff_percent_payed money,
	@calloff_percent_penalty money,
	@calloff_percent_penalty_ money,
	@calloff_percent_penalty_payed money,
	@calloff_percent_penalty_daily money,
	@calloff_percent_penalty_fraction TFRACTION,
	@calloff_penalty money,       
	@calloff_penalty_ money,
	@calloff_penalty_payed money,
	@writeoff_principal money,
	@writeoff_principal_ money,
	@writeoff_principal_payed money,	
	@writeoff_principal_penalty money,
	@writeoff_principal_penalty_ money, 
	@writeoff_principal_penalty_payed money,
	@writeoff_principal_penalty_daily money,
	@writeoff_principal_penalty_fraction TFRACTION,
	@writeoff_percent money,
	@writeoff_percent_ money,
	@writeoff_percent_payed money,
	@writeoff_percent_penalty money,
	@writeoff_percent_penalty_ money,
	@writeoff_percent_penalty_payed money,
	@writeoff_percent_penalty_daily money,
	@writeoff_percent_penalty_fraction TFRACTION,
	@writeoff_penalty money,
	@writeoff_penalty_ money,
	@writeoff_penalty_payed money,
	@immediate_penalty money,
	@immediate_penalty_ money,
	@immediate_penalty_payed money,
	@fine money,
	@fine_ money,
	@fine_payed money,
	@overdue_insurance_ money,
	@overdue_insurance_payed money,
	@overdue_service_fee_ money,
	@overdue_service_fee_payed money,

	@payed_principal money,
	@max_category_level tinyint,
	@category_1 money,
	@category_2 money,
	@category_3 money,           
	@category_4 money,
	@category_5 money,
	@category_6 money,

	@overdue_insurance money, 
	@overdue_service_fee money,

	@deferable_interest money, 
	@deferable_overdue_interest money, 
	@deferable_penalty money,
	@deferable_fine money,
	@remaining_fee money


DECLARE
	@schedule_date						smalldatetime,
	@schedule_interest_date				smalldatetime,
	@schedule_principal					money,
	@schedule_interest					money,
	@schedule_nu_interest				money,
	@schedule_balance					money,
	@schedule_pay_interest				bit,
	@schedule_principal_				money,
	@schedule_interest_					money,
	@schedule_nu_interest_				money,
	@schedule_nu_interest_correction	money,
	@schedule_interest_correction		money,	
	@schedule_insurance					money,
	@schedule_insurance_payed			money,
	@schedule_insurance_				money,
	@schedule_service_fee				money,
	@schedule_service_fee_payed			money,
	@schedule_service_fee_				money,

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

	@defered_debt_payed					money,
	@defered_debt_						money,
	@defered_debt_next_payed			money,
	@defered_debt_next_					money,

	@deferable_interest_ money, 
	@deferable_overdue_interest_ money, 
	@deferable_penalty_ money,
	@deferable_fine_ money,
	
	@step_defered_interest				money

DECLARE
	@state					tinyint,
	@client_no				int,
	@client_amount			money,
	@client_amount_			money,
	@iso					TISO,
	@end_date				smalldatetime,
	@start_date				smalldatetime,
	@disburse_type			int,
	@schedule_type			int,
	@interest_flags			int,
	@penalty_flags			int,
	@nu_intrate				money,
	@intrate				money,
	@penalty_intrate		money,
	@penalty_delta			bit,
	@basis					int

DECLARE
	@parent_op_id int,
	@child_op_id int,
	@op_commit bit

DECLARE
	@step_overdue_date smalldatetime,
	@step_overdue_percent money,
	@step_overdue_principal money,
	@step_overdue_insurance money,
	@step_overdue_service_fee money

DECLARE
	@op_note		varchar(255),	
	@op_amount		money,
	@op_data		XML,
	@op_details		XML,
	@op_ext_xml_1	XML,
	@op_ext_xml_2	XML

DECLARE
	@payment_delay bit

DECLARE 
	@op_count int,
	@before_op_accounting bit,
	@max_debt money,
	@min_debt money,	
	@no_charge_debt money,
	@schedule_control bit,
	@grace_finish_date smalldatetime,
	@guarantee bit

SET @_date = DATEADD(dd, 1, @date)

SELECT 
	@state = L.STATE, @client_no = L.CLIENT_NO, @iso = L.ISO, @disburse_type = L.DISBURSE_TYPE, @schedule_type = L.SCHEDULE_TYPE, @start_date = L.START_DATE,
	@end_date = L.END_DATE, @interest_flags = L.INTEREST_FLAGS, @penalty_flags = L.PENALTY_FLAGS, @nu_intrate = L.NOTUSED_INTRATE, 
	@intrate = L.INTRATE, @penalty_intrate = L.PENALTY_INTRATE, @basis = L.BASIS, @grace_finish_date = L.GRACE_FINISH_DATE,
	@calc_date = D.CALC_DATE, @prev_step = D.PREV_STEP, @nu_principal = ISNULL(D.NU_PRINCIPAL,$0.00), @nu_interest = ISNULL(D.NU_INTEREST,$0.00), 
	@nu_interest_daily = ISNULL(D.NU_INTEREST_DAILY,$0.00), @nu_interest_fraction = ISNULL(D.NU_INTEREST_FRACTION,$0.00), 
	@principal = ISNULL(D.PRINCIPAL,$0.00), @interest = ISNULL(D.INTEREST,$0.00), @interest_daily = ISNULL(D.INTEREST_DAILY,$0.00), @interest_fraction = ISNULL(D.INTEREST_FRACTION,$0.00),
	@overdue_date = D.OVERDUE_DATE, @overdue_principal = ISNULL(D.OVERDUE_PRINCIPAL,$0.00), @overdue_principal_interest = ISNULL(D.OVERDUE_PRINCIPAL_INTEREST,$0.00), 
	@overdue_principal_interest_daily = ISNULL(D.OVERDUE_PRINCIPAL_INTEREST_DAILY,$0.00), @overdue_principal_interest_fraction = ISNULL(D.OVERDUE_PRINCIPAL_INTEREST_FRACTION,$0.00), 
	@overdue_principal_penalty = ISNULL(D.OVERDUE_PRINCIPAL_PENALTY,$0.00), @overdue_principal_penalty_daily = ISNULL(D.OVERDUE_PRINCIPAL_PENALTY_DAILY,$0.00), 
	@overdue_principal_penalty_fraction = ISNULL(D.OVERDUE_PRINCIPAL_PENALTY_FRACTION,$0.00),
	@overdue_percent = ISNULL(D.OVERDUE_PERCENT,$0.00), @overdue_percent_penalty = ISNULL(D.OVERDUE_PERCENT_PENALTY,$0.00), 
	@overdue_percent_penalty_daily = ISNULL(D.OVERDUE_PERCENT_PENALTY_DAILY,$0.00), @overdue_percent_penalty_fraction = ISNULL(D.OVERDUE_PERCENT_PENALTY_FRACTION,$0.00),
	@calloff_date = L.CALLOFF_DATE, @calloff_principal = ISNULL(D.CALLOFF_PRINCIPAL,$0.00), @calloff_principal_interest = ISNULL(D.CALLOFF_PRINCIPAL_INTEREST,$0.00), 
	@calloff_principal_interest_daily = ISNULL(D.CALLOFF_PRINCIPAL_INTEREST_DAILY,$0.00), @calloff_principal_interest_fraction = ISNULL(D.CALLOFF_PRINCIPAL_INTEREST_FRACTION,$0.00), 
	@calloff_principal_penalty = ISNULL(D.CALLOFF_PRINCIPAL_PENALTY,$0.00), @calloff_principal_penalty_daily = ISNULL(D.CALLOFF_PRINCIPAL_PENALTY_DAILY,$0.00), 
	@calloff_principal_penalty_fraction = ISNULL(D.CALLOFF_PRINCIPAL_PENALTY_FRACTION,$0.00),
	@calloff_percent = ISNULL(D.CALLOFF_PERCENT,$0.00), @calloff_percent_penalty = ISNULL(D.CALLOFF_PERCENT_PENALTY,$0.00), 
	@calloff_percent_penalty_daily = ISNULL(D.CALLOFF_PERCENT_PENALTY_DAILY,$0.00), @calloff_percent_penalty_fraction = ISNULL(D.CALLOFF_PERCENT_PENALTY_FRACTION,$0.00), @calloff_penalty = ISNULL(D.CALLOFF_PENALTY,$0.00),
	@writeoff_date = L.WRITEOFF_DATE, @writeoff_principal = ISNULL(D.WRITEOFF_PRINCIPAL,$0.00), @writeoff_principal_penalty = ISNULL(D.WRITEOFF_PRINCIPAL_PENALTY,$0.00), 
	@writeoff_principal_penalty_daily = ISNULL(D.WRITEOFF_PRINCIPAL_PENALTY_DAILY,$0.00), @writeoff_principal_penalty_fraction = ISNULL(D.WRITEOFF_PRINCIPAL_PENALTY_FRACTION,$0.00),
	@writeoff_percent = ISNULL(D.WRITEOFF_PERCENT,$0.00), @writeoff_percent_penalty = ISNULL(D.WRITEOFF_PERCENT_PENALTY,$0.00), 
	@writeoff_percent_penalty_daily = ISNULL(D.WRITEOFF_PERCENT_PENALTY_DAILY,$0.00), @writeoff_percent_penalty_fraction = ISNULL(D.WRITEOFF_PERCENT_PENALTY_FRACTION,$0.00), 
	@writeoff_penalty = ISNULL(D.WRITEOFF_PENALTY,$0.00),
	@immediate_penalty = ISNULL(D.IMMEDIATE_PENALTY,$0.00), @fine = ISNULL(D.FINE,$0.00), @max_category_level = ISNULL(D.MAX_CATEGORY_LEVEL, 1),
	@category_1 = ISNULL(D.CATEGORY_1,$0.00), @category_2 = ISNULL(D.CATEGORY_2,$0.00), @category_3 = ISNULL(D.CATEGORY_3,$0.00), 
	@category_4 = ISNULL(D.CATEGORY_4,$0.00), @category_5 = ISNULL(D.CATEGORY_5,$0.00), @category_6 = ISNULL(D.CATEGORY_6,$0.00),
	@overdue_insurance = ISNULL(D.OVERDUE_INSURANCE,$0.00), @overdue_service_fee = ISNULL(D.OVERDUE_SERVICE_FEE,$0.00), @linked_ccy = L.LINKED_CCY, @indexed_rate = L.INDEXED_RATE,
	@deferable_interest = ISNULL(D.DEFERABLE_INTEREST, $0.00), @deferable_overdue_interest = ISNULL(D.DEFERABLE_OVERDUE_INTEREST, $0.00), @deferable_penalty = ISNULL(D.DEFERABLE_PENALTY, $0.00), @deferable_fine = ISNULL(D.DEFERABLE_FINE, $0.00),
	@guarantee = GUARANTEE, @remaining_fee = ISNULL(D.REMAINING_FEE, $0.00)
FROM dbo.LOANS L (NOLOCK)
	INNER JOIN dbo.LOAN_DETAILS D (NOLOCK) ON D.LOAN_ID = L.LOAN_ID
WHERE L.LOAN_ID = @loan_id AND D.CALC_DATE = @date


SET @before_op_accounting = 0
SET @op_count = 0
SET @schedule_date = NULL
SET @schedule_interest_date = NULL
SET @schedule_principal = NULL
SET @schedule_interest = NULL
SET @schedule_balance = NULL
SET @schedule_pay_interest = NULL
SET @schedule_nu_interest_correction = NULL
SET @schedule_interest_correction = NULL
SET @schedule_insurance = NULL
SET @schedule_service_fee = NULL

SET @principal_payed					= $0.00
SET @nu_principal_payed					= $0.00
SET @nu_interest_payed					= $0.00
SET @interest_payed						= $0.00
SET @overdue_principal_payed			= $0.00
SET @overdue_principal_interest_payed	= $0.00
SET @overdue_principal_penalty_payed	= $0.00
SET @overdue_percent_payed				= $0.00
SET @overdue_percent_penalty_payed		= $0.00
SET @calloff_principal_payed			= $0.00
SET @calloff_principal_interest_payed	= $0.00
SET @calloff_principal_penalty_payed	= $0.00
SET @calloff_percent_payed				= $0.00
SET @calloff_percent_penalty_payed		= $0.00
SET @calloff_penalty_payed				= $0.00
SET @writeoff_principal_payed			= $0.00
SET @writeoff_principal_penalty_payed	= $0.00
SET @writeoff_percent_payed				= $0.00
SET @writeoff_percent_penalty_payed		= $0.00
SET @writeoff_penalty_payed				= $0.00
SET @immediate_penalty_payed			= $0.00
SET @fine_payed							= $0.00
SET @overdue_insurance_payed			= $0.00
SET @overdue_service_fee_payed			= $0.00

SET @rate_diff							= $0.00
SET @penalty_debt						= $0.00


SELECT TOP 1 @schedule_date=SCHEDULE_DATE, @schedule_interest_date=INTEREST_DATE, @schedule_principal=ISNULL(PRINCIPAL, $0.00), @schedule_interest=ISNULL(INTEREST, $0.00), @schedule_nu_interest=ISNULL(NU_INTEREST, $0.00), @schedule_balance=ISNULL(BALANCE, $0.00), @schedule_pay_interest=PAY_INTEREST,
	@schedule_nu_interest_correction = NU_INTEREST_CORRECTION, @schedule_interest_correction = INTEREST_CORRECTION
FROM dbo.LOAN_SCHEDULE
WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @date AND ORIGINAL_AMOUNT IS NOT NULL AND (ISNULL(AMOUNT, $0.00) > $0.00 OR  @disburse_type = 4)
ORDER BY SCHEDULE_DATE

SELECT TOP 1 @schedule_insurance = ISNULL(INSURANCE, $0.00), @schedule_service_fee = CASE WHEN @date = SCHEDULE_DATE THEN SERVICE_FEE ELSE $0.00 END,
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

DELETE FROM #tbl_overdue
INSERT INTO #tbl_overdue([LOAN_ID],[OVERDUE_DATE],[LATE_OP_ID],[OVERDUE_OP_ID],[OVERDUE_PRINCIPAL],[OVERDUE_PERCENT])
SELECT [LOAN_ID],[OVERDUE_DATE],[LATE_OP_ID],[OVERDUE_OP_ID],[OVERDUE_PRINCIPAL],[OVERDUE_PERCENT]
FROM dbo.LOAN_DETAIL_OVERDUE (NOLOCK)
WHERE LOAN_ID = @loan_id


SET @parent_op_id = NULL
SET @child_op_id = NULL
SET @op_commit = 0

SET @step_overdue_date = NULL
SET @step_overdue_percent = NULL
SET @step_overdue_principal = NULL


SET @nu_principal_						= @nu_principal
SET @nu_interest_						= @nu_interest
SET @principal_							= @principal
SET @interest_							= @interest
SET @overdue_principal_					= @overdue_principal
SET @overdue_principal_interest_		= @overdue_principal_interest
SET @overdue_principal_penalty_			= @overdue_principal_penalty
SET @overdue_percent_					= @overdue_percent
SET @overdue_percent_penalty_			= @overdue_percent_penalty
SET @calloff_principal_					= @calloff_principal
SET @calloff_principal_interest_		= @calloff_principal_interest
SET @calloff_principal_penalty_			= @calloff_principal_penalty
SET @calloff_percent_					= @calloff_percent
SET @calloff_percent_penalty_			= @calloff_percent_penalty
SET @calloff_penalty_					= @calloff_penalty
SET @writeoff_principal_				= @writeoff_principal
SET @writeoff_principal_penalty_		= @writeoff_principal_penalty
SET @writeoff_percent_					= @writeoff_percent
SET @writeoff_percent_penalty_			= @writeoff_percent_penalty
SET @writeoff_penalty_					= @writeoff_penalty
SET @immediate_penalty_					= @immediate_penalty
SET @fine_								= @fine

SET	@schedule_principal_				= @schedule_principal
SET	@schedule_interest_					= @schedule_interest
SET	@schedule_nu_interest_				= @schedule_nu_interest

SET	@schedule_insurance_				= @schedule_insurance
SET	@schedule_service_fee_				= @schedule_service_fee
SET	@overdue_insurance_					= @overdue_insurance
SET	@overdue_service_fee_				= @overdue_service_fee

SET	@schedule_defered_interest_			= @schedule_defered_interest
SET	@schedule_defered_overdue_interest_	= @schedule_defered_overdue_interest
SET	@schedule_defered_penalty_			= @schedule_defered_penalty
SET	@schedule_defered_fine_				= @schedule_defered_fine

SET	@deferable_interest_				= @deferable_interest
SET	@deferable_overdue_interest_		= @deferable_overdue_interest
SET	@deferable_penalty_					= @deferable_penalty
SET	@deferable_fine_					= @deferable_fine

SET @debt_amount =
		@overdue_principal + @overdue_principal_interest + @overdue_principal_penalty +
		@overdue_percent + @overdue_percent_penalty +
		@calloff_principal + @calloff_principal_interest + @calloff_principal_penalty +
		@calloff_percent + @calloff_percent_penalty + @calloff_penalty +
		@writeoff_principal + @writeoff_principal_penalty + 
		@writeoff_percent + @writeoff_percent_penalty +	@writeoff_penalty +
		@fine + @overdue_insurance + @overdue_service_fee

IF @schedule_date = @date
	SET @debt_amount = ISNULL(@debt_amount, $0.00) + ISNULL(@schedule_nu_interest, $0.00) + ISNULL(@schedule_interest, $0.00) + ISNULL(@schedule_principal, $0.00) + 
			ISNULL(@schedule_insurance, $0.00) + ISNULL(@schedule_service_fee, $0.00) + ISNULL(@schedule_defered_interest, $0.00) + 
			ISNULL(@schedule_defered_overdue_interest, $0.00) + ISNULL(@schedule_defered_penalty, $0.00) + ISNULL(@schedule_defered_fine, $0.00)

SET @debt_amount_without_rate_diff = @debt_amount

IF (@linked_ccy IS NOT NULL)
BEGIN
	SET @rate_change_ratio = dbo.get_cross_rate(@linked_ccy, @iso, @calc_date) / @indexed_rate - 1

	IF (@rate_change_ratio <= 0)
		SET @rate_change_ratio = 0
	ELSE
	BEGIN
		SET @rate_diff = ROUND(@debt_amount * @rate_change_ratio, 2, 1)

		SET @debt_amount = @debt_amount + @rate_diff
	END
END

SELECT @acc_id = L.ACC_ID
FROM dbo.LOAN_ACCOUNTS L
WHERE L.LOAN_ID = @loan_id AND L.ACCOUNT_TYPE = 20 -- ÓÄÓáÉÓ ÀÍÂÀÒÉÛÓßÏÒÄÁÉÓ ÀÍÂÀÒÉÛÉ

DECLARE
	@non_auto_pay_loan int

SELECT 
	@non_auto_pay_loan = ISNULL(ATTRIB_VALUE, 0)
FROM dbo.CLIENT_ATTRIBUTES (NOLOCK)
WHERE CLIENT_NO = @client_no AND ATTRIB_CODE = 'NON_AUTO_PAY_LOAN'

IF @non_auto_pay_loan = 1 GOTO _skip_payment

SET @client_amount = $0.00

IF @debt_amount > $0.00 
BEGIN
	EXEC @r = dbo.LOAN_SP_COLLECTION_CLIENT_AMOUNT					--		EXEC @r = dbo.LOAN_SP_COLLECT_CLIENT_AMOUNT
		@user_id = @user_id,										--			@date = @date,
		@date = @date,												--			@client_no = @client_no,
		@loan_id = @loan_id,										--			@iso = @iso,
		@iso = @iso,												--			@loan_id = @loan_id,
		@acc_id = @acc_id,											--			@debt_amount = @debt_amount,
		@client_no = @client_no,									--			@user_id = @user_id,
		@debt_amount = @debt_amount,								--			@client_amount = @client_amount OUTPUT
		@simulate = 0,
		@client_amount = @client_amount OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END
END

IF @client_amount < $0.00
	SET @client_amount = $0.00

SET @client_amount_ = @client_amount

IF @client_amount_ = $0.00 GOTO _skip_payment

IF (@linked_ccy IS NOT NULL)
BEGIN
	IF (@client_amount > 0 AND @client_amount < @debt_amount)
	BEGIN
		SET @rate_change_ratio = dbo.get_cross_rate(@linked_ccy, @iso, @calc_date) / @indexed_rate - 1

		IF (@rate_change_ratio > 0)
			SET @rate_diff = ROUND(@client_amount - @client_amount / (1 + @rate_change_ratio), 2, 1)
	END
END

IF (@rate_diff > $0.00)
	SET @client_amount = @client_amount - @rate_diff --ÈÖ ÄÓ ÃÀÅÀËÉÀÍÄÁÀ ßÀÒÌÏÉÛÅÀ, ÌÀÛÉÍ ÚÏÅÄËÈÅÉÓ ÓÒÖËÀÃ ÃÀÉ×ÀÒÄÁÀ

EXEC @r = dbo.loan_process_payment
	@loan_id							= @loan_id,
	@date								= @date,
	@op_commit							= @op_commit OUTPUT,
	@amount								= @client_amount OUTPUT,
	@schedule_date						= @schedule_date,
	@schedule_principal					= @schedule_principal OUTPUT,
	@schedule_interest					= @schedule_interest OUTPUT,
	@schedule_nu_interest				= @schedule_nu_interest OUTPUT,
	@schedule_insurance					= @schedule_insurance OUTPUT,
	@schedule_service_fee				= @schedule_service_fee OUTPUT,
	@schedule_defered_interest			= @schedule_defered_interest OUTPUT,
	@schedule_defered_overdue_interest	= @schedule_defered_overdue_interest OUTPUT,
	@schedule_defered_penalty			= @schedule_defered_penalty OUTPUT,
	@schedule_defered_fine				= @schedule_defered_fine OUTPUT,
	@writeoff_date						= @writeoff_date OUTPUT,
	@writeoff_principal					= @writeoff_principal OUTPUT,
	@writeoff_principal_penalty			= @writeoff_principal_penalty OUTPUT,
	@writeoff_percent					= @writeoff_percent OUTPUT,
	@writeoff_percent_penalty			= @writeoff_percent_penalty OUTPUT,
	@writeoff_penalty					= @writeoff_penalty OUTPUT,
	@calloff_date						= @calloff_date OUTPUT,
	@calloff_principal					= @calloff_principal OUTPUT,
	@calloff_principal_interest			= @calloff_principal_interest OUTPUT,
	@calloff_principal_penalty			= @calloff_principal_penalty OUTPUT,
	@calloff_percent					= @calloff_percent OUTPUT,
	@calloff_percent_penalty			= @calloff_percent_penalty OUTPUT,
	@calloff_penalty					= @calloff_penalty OUTPUT,
	@overdue_date						= @overdue_date OUTPUT,
	@overdue_principal					= @overdue_principal OUTPUT,
	@overdue_principal_interest			= @overdue_principal_interest OUTPUT,
	@overdue_principal_penalty			= @overdue_principal_penalty OUTPUT,
	@overdue_percent					= @overdue_percent OUTPUT,
	@overdue_percent_penalty			= @overdue_percent_penalty OUTPUT,
	@nu_interest						= @nu_interest OUTPUT,
	@interest							= @interest OUTPUT,
	@principal							= @principal OUTPUT,
	@overdue_insurance					= @overdue_insurance OUTPUT,
	@overdue_service_fee				= @overdue_service_fee OUTPUT,
	@deferable_interest					= @deferable_interest OUTPUT,
	@deferable_overdue_interest			= @deferable_overdue_interest OUTPUT,
	@deferable_penalty					= @deferable_penalty OUTPUT,
	@deferable_fine						= @deferable_fine OUTPUT
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

IF @op_commit = 1
BEGIN
	SET @op_count = @op_count + 1

	SET @principal_payed							= @principal_ - @principal
	SET @nu_principal_payed							= @nu_principal_ + @principal_payed
	SET @nu_interest_payed							= @nu_interest_ - @nu_interest
	SET @interest_payed								= @interest_ - @interest
	SET @overdue_principal_payed					= @overdue_principal_ - @overdue_principal
	SET @overdue_principal_interest_payed			= @overdue_principal_interest_ - @overdue_principal_interest
	SET @overdue_principal_penalty_payed			= @overdue_principal_penalty_ - @overdue_principal_penalty
	SET @overdue_percent_payed						= @overdue_percent_ - @overdue_percent
	SET @overdue_percent_penalty_payed				= @overdue_percent_penalty_ - @overdue_percent_penalty
	SET @calloff_principal_payed					= @calloff_principal_ - @calloff_principal
	SET @calloff_principal_interest_payed			= @calloff_principal_interest_ - @calloff_principal_interest
	SET @calloff_principal_penalty_payed			= @calloff_principal_penalty_ - @calloff_principal_penalty
	SET @calloff_percent_payed						= @calloff_percent_ - @calloff_percent
	SET @calloff_percent_penalty_payed				= @calloff_percent_penalty_ - @calloff_percent_penalty
	SET @calloff_penalty_payed						= @calloff_penalty_ - @calloff_penalty
	SET @writeoff_principal_payed					= @writeoff_principal_ - @writeoff_principal
	SET @writeoff_principal_penalty_payed			= @writeoff_principal_penalty_ - @writeoff_principal_penalty
	SET @writeoff_percent_payed						= @writeoff_percent_ - @writeoff_percent
	SET @writeoff_percent_penalty_payed				= @writeoff_percent_penalty_ - @writeoff_percent_penalty
	SET @writeoff_penalty_payed						= @writeoff_penalty_ - @writeoff_penalty
	SET @immediate_penalty_payed					= @immediate_penalty_ - @immediate_penalty
	SET @fine_payed									= @fine_ - @fine

	SET @schedule_insurance_payed					= @schedule_insurance_ - @schedule_insurance
	SET @schedule_service_fee_payed					= @schedule_service_fee_ - @schedule_service_fee
	SET @overdue_insurance_payed					= @overdue_insurance_ - @overdue_insurance
	SET @overdue_service_fee_payed					= @overdue_service_fee_ - @overdue_service_fee

	SET @schedule_defered_interest_payed			= @schedule_defered_interest_ - @schedule_defered_interest
	SET @schedule_defered_overdue_interest_payed	= @schedule_defered_overdue_interest_ - @schedule_defered_overdue_interest
	SET @schedule_defered_penalty_payed				= @schedule_defered_penalty_ - @schedule_defered_penalty
	SET @schedule_defered_fine_payed				= @schedule_defered_fine_ - @schedule_defered_fine


	IF (@disburse_type = 4) --AND (@date < @end_date) --todo:
		SET @nu_principal = @nu_principal_ + @principal_payed + @overdue_principal_payed

	IF @state = dbo.loan_const_state_writedoff()
	BEGIN
		SET @op_data =
			(SELECT
				@writeoff_principal_payed													AS WRITEOFF_PRINCIPAL,
				@writeoff_principal_														AS WRITEOFF_PRINCIPAL_ORG,				
				@writeoff_principal_penalty_payed											AS WRITEOFF_PRINCIPAL_PENALTY,
				@writeoff_principal_penalty_												AS WRITEOFF_PRINCIPAL_PENALTY_ORG,
				@writeoff_percent_payed														AS WRITEOFF_PERCENT,
				@writeoff_percent_															AS WRITEOFF_PERCENT_ORG,
				@writeoff_percent_penalty_payed												AS WRITEOFF_PERCENT_PENALTY,
				@writeoff_percent_penalty_													AS WRITEOFF_PERCENT_PENALTY_ORG,
				@writeoff_penalty_payed														AS WRITEOFF_PENALTY,
				@writeoff_penalty_															AS WRITEOFF_PENALTY_ORG
			FOR XML RAW, TYPE)

		SET @op_amount = @writeoff_principal_payed + @writeoff_principal_penalty_payed +
			@writeoff_percent_payed + @writeoff_percent_penalty_payed + @writeoff_penalty_payed

		INSERT INTO dbo.LOAN_OPS(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, PARENT_OP_ID, AMOUNT, OP_DATA, [OWNER], UPDATE_DATA, UPDATE_SCHEDULE)
		VALUES(@loan_id, @date, dbo.loan_const_op_payment_writedoff(), 0, @parent_op_id, @op_amount, @op_data, @user_id, 0, 0)
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

		IF ISNULL(@writeoff_principal, $0.00) + ISNULL(@writeoff_principal_penalty, $0.00) + ISNULL(@writeoff_percent, $0.00) + ISNULL(@writeoff_percent_penalty, $0.00) + ISNULL(@writeoff_penalty, $0.00) = $0.00
			SET @state = dbo.loan_const_state_current()
	END
	ELSE
	BEGIN
		IF @guarantee = 0
		BEGIN
			SET @defered_debt_payed = @schedule_defered_interest_payed + @schedule_defered_overdue_interest_payed + @schedule_defered_penalty_payed + @schedule_defered_fine_payed
			SET @defered_debt_ = @schedule_defered_interest_ + @schedule_defered_overdue_interest_ + @schedule_defered_penalty_ + @schedule_defered_fine_
			SET @defered_debt_next_payed = $0.00
			SET @defered_debt_next_ = @deferable_interest_ + @deferable_overdue_interest_ + @deferable_penalty_ +  @deferable_fine_ - @defered_debt_

			SET @op_data =
				(SELECT
					@overdue_percent_penalty_payed + @overdue_principal_penalty_payed			AS PENALTY,
					@overdue_percent_penalty_	+ @overdue_principal_penalty_					AS PENALTY_ORG,				
					@overdue_percent_payed														AS OVERDUE_PERCENT,
					@overdue_percent_															AS OVERDUE_PERCENT_ORG,
					@overdue_principal_payed													AS OVERDUE_PRINCIPAL,
					@overdue_principal_															AS OVERDUE_PRINCIPAL_ORG,
					@overdue_principal_interest_payed + @nu_interest_payed + @interest_payed	AS INTEREST,
					@overdue_principal_interest_ + @nu_interest_ + @interest_					AS INTEREST_ORG,
					@principal_payed															AS PRINCIPAL,
					@principal_																	AS PRINCIPAL_ORG,
					@max_debt																	AS MAX_DEBT,
					@min_debt																	AS MIN_DEBT,
					@no_charge_debt																AS NO_CHARGE_DEBT,
					@rate_diff																	AS RATE_DIFF,
					@overdue_insurance_payed + @schedule_insurance_payed						AS INSURANCE,
					@overdue_insurance_ + @schedule_insurance_									AS INSURANCE_ORG,
					@overdue_service_fee_payed + @schedule_service_fee_payed					AS SERVICE_FEE,
					@overdue_service_fee_ + @schedule_service_fee_								AS SERVICE_FEE_ORG,
					@defered_debt_payed															AS DEFERED_DEBT,
					@defered_debt_																AS DEFERED_DEBT_ORG,
					@defered_debt_next_payed													AS DEFERED_DEBT_NEXT,
					@defered_debt_next_															AS DEFERED_DEBT_NEXT_ORG
				FOR XML RAW, TYPE)

			SET @op_details =
				(SELECT
					@overdue_percent_penalty_payed				AS OVERDUE_PERCENT_PENALTY,
					@overdue_principal_penalty_payed			AS OVERDUE_PRINCIPAL_PENALTY,
					@overdue_percent_payed						AS OVERDUE_PERCENT,
					@overdue_principal_payed					AS OVERDUE_PRINCIPAL,
					@overdue_principal_interest_payed			AS OVERDUE_PRINCIPAL_INTEREST,
					@interest_payed								AS INTEREST,
					@nu_interest_payed							AS NU_INTEREST,
					$0.0000										AS PREPAYMENT,
					$0.0000										AS PREPAYMENT_PENALTY,
					@principal_payed							AS PRINCIPAL,
					@state										AS [STATE],
					@rate_diff									AS RATE_DIFF,
					@schedule_insurance_payed					AS INSURANCE,
					@overdue_insurance_payed					AS OVERDUE_INSURANCE,
					@schedule_service_fee_payed					AS SERVICE_FEE,
					@overdue_service_fee_payed					AS OVERDUE_SERVICE_FEE,
					@schedule_defered_interest_payed			AS DEFERED_INTEREST,
					@schedule_defered_overdue_interest_payed	AS DEFERED_OVERDUE_INTEREST,
					@schedule_defered_penalty_payed				AS DEFERED_PENALTY,
					@schedule_defered_fine_payed				AS DEFERED_FINE
				 FOR XML RAW, TYPE)


			SET @op_ext_xml_1 = NULL

			DECLARE
				@tmp_1_1 money,	@tmp_1_2 money,
				@tmp_2_1 money,	@tmp_2_2 money

			SET @op_ext_xml_2 =
				(SELECT [LOAN_ID],[OVERDUE_DATE],[LATE_OP_ID],[OVERDUE_OP_ID],[OVERDUE_PRINCIPAL],[OVERDUE_PERCENT] FROM #tbl_overdue FOR XML RAW, ROOT)

			SET @tmp_1_1 = @overdue_principal_payed
			SET @tmp_2_1 = @overdue_percent_payed

			UPDATE #tbl_overdue
			SET
				@tmp_1_2 = @tmp_1_1,
				@tmp_1_1 = CASE WHEN @tmp_1_1 > OVERDUE_PRINCIPAL THEN @tmp_1_1 - OVERDUE_PRINCIPAL ELSE $0.00 END,
				OVERDUE_PRINCIPAL = CASE WHEN @tmp_1_1 > 0 THEN $0.00 ELSE OVERDUE_PRINCIPAL - @tmp_1_2 END,
				@tmp_2_2 = @tmp_2_1,
				@tmp_2_1 = CASE WHEN @tmp_2_1 > OVERDUE_PERCENT THEN @tmp_2_1 - OVERDUE_PERCENT ELSE $0.00 END,
				OVERDUE_PERCENT = CASE WHEN @tmp_2_1 > 0 THEN $0.00 ELSE OVERDUE_PERCENT - @tmp_2_2 END

			SET @op_amount = @calloff_principal_payed + @calloff_principal_interest_payed + @calloff_principal_penalty_payed +
				@calloff_percent_payed + @calloff_percent_penalty_payed + @calloff_penalty_payed +
				@overdue_principal_payed + @overdue_principal_interest_payed + @overdue_principal_penalty_payed +
				@overdue_percent_payed + @overdue_percent_penalty_payed +
				@nu_interest_payed + @interest_payed + @principal_payed + 
				ISNULL(@schedule_insurance_payed, $0.00) + ISNULL(@overdue_insurance_payed, $0.00) + ISNULL(@schedule_service_fee_payed, $0.00) + 
				ISNULL(@overdue_service_fee_payed, $0.00) + ISNULL(@rate_diff, $0.00) + ISNULL(@defered_debt_payed, $0.00)

			INSERT INTO dbo.LOAN_OPS(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, PARENT_OP_ID, AMOUNT, OP_DATA, OP_DETAILS, OP_EXT_XML_1, OP_EXT_XML_2, [OWNER], UPDATE_DATA, UPDATE_SCHEDULE)
			VALUES(@loan_id, @date, dbo.loan_const_op_payment(), 0, @parent_op_id, @op_amount, @op_data, @op_details, @op_ext_xml_1, @op_ext_xml_2, @user_id, 0, 0)
			IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END			
		END
		ELSE
		BEGIN
			SET @op_data =
				(SELECT
					@overdue_percent_penalty_payed				AS PENALTY,
					@overdue_percent_penalty_					AS PENALTY_ORG,				
					@overdue_percent_payed						AS OVERDUE_PERCENT,
					@overdue_percent_							AS OVERDUE_PERCENT_ORG,
					@interest_payed								AS INTEREST,
					@interest_									AS INTEREST_ORG,
					@state										AS [STATE]
				  FOR XML RAW, TYPE)			

			SET @op_ext_xml_1 = NULL

			SET @op_ext_xml_2 =
				(SELECT [LOAN_ID],[OVERDUE_DATE],[LATE_OP_ID],[OVERDUE_OP_ID],[OVERDUE_PRINCIPAL],[OVERDUE_PERCENT] FROM #tbl_overdue FOR XML RAW, ROOT)

			SET @tmp_2_1 = @overdue_percent_payed

			UPDATE #tbl_overdue
			SET
				@tmp_2_2 = @tmp_2_1,
				@tmp_2_1 = CASE WHEN @tmp_2_1 > OVERDUE_PERCENT THEN @tmp_2_1 - OVERDUE_PERCENT ELSE $0.00 END,
				OVERDUE_PERCENT = CASE WHEN @tmp_2_1 > 0 THEN $0.00 ELSE OVERDUE_PERCENT - @tmp_2_2 END

			SET @op_amount = @overdue_percent_payed + @overdue_percent_penalty_payed + @interest_payed

			INSERT INTO dbo.LOAN_OPS(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, PARENT_OP_ID, AMOUNT, OP_DATA, OP_DETAILS, OP_EXT_XML_1, OP_EXT_XML_2, [OWNER], UPDATE_DATA, UPDATE_SCHEDULE)
			VALUES(@loan_id, @date, dbo.loan_const_op_guar_payment(), 0, @parent_op_id, @op_amount, @op_data, @op_details, @op_ext_xml_1, @op_ext_xml_2, @user_id, 0, 0)
			IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END
		END
	END

	SET @child_op_id =  SCOPE_IDENTITY()

	IF @parent_op_id IS NULL
		SET @parent_op_id = @child_op_id

	EXEC @r = dbo.LOAN_SP_PROCESS_BEFORE_OP_ACCOUNTING
		@doc_rec_id			= @doc_rec_id OUTPUT,
		@op_id				= @child_op_id,
		@user_id			= @user_id,
		@doc_date			= @date,
		@by_processing		= 1,
		@simulate			= 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

	SET @before_op_accounting = 1

	EXEC @r = dbo.LOAN_SP_EXEC_OP
		@doc_rec_id = @doc_rec_id OUTPUT,
		@op_id = @child_op_id,
		@user_id = @user_id,
		@by_processing = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

	SET @penalty_debt = ISNULL(@overdue_principal_penalty, $0.00) + ISNULL(@overdue_percent_penalty, $0.00) + 
		ISNULL(@calloff_principal_penalty, $0.00) + ISNULL(@calloff_percent_penalty, $0.00) + ISNULL(@calloff_penalty, $0.00) + 
		ISNULL(@writeoff_principal_penalty, $0.00) + ISNULL(@writeoff_percent_penalty, $0.00) + ISNULL(@writeoff_penalty, $0.00)


	SET @illegal_debt = @penalty_debt + 
		     ISNULL(@overdue_principal, $0.00) + ISNULL(@overdue_percent, $0.00) + ISNULL(@calloff_principal, $0.00) + 
		     ISNULL(@calloff_principal_interest, $0.00) + ISNULL(@calloff_percent, $0.00) + ISNULL(@writeoff_principal, $0.00) + 
		     ISNULL(@writeoff_percent, $0.00) + ISNULL(@overdue_insurance, $0.00) + ISNULL(@overdue_service_fee, $0.00)

	IF @state = dbo.loan_const_state_overdued() AND @illegal_debt = $0.00
		SET @state = dbo.loan_const_state_current()

	UPDATE dbo.LOANS
	SET [STATE] = @state
	WHERE LOAN_ID = @loan_id AND [STATE] <> @state
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END
END	

_skip_payment:

/* ვადაგადაცილების დაფიქსირება */
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
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

IF @op_commit = 1
BEGIN
	SET @op_count = @op_count + 1
	SET @op_data=
		(SELECT @step_overdue_percent AS OVERDUE_PERCENT, @step_overdue_principal AS OVERDUE_PRINCIPAL, @step_overdue_insurance AS OVERDUE_INSURANCE, @step_overdue_service_fee AS OVERDUE_SERVICE_FEE, @step_defered_interest AS OVERDUE_DEFERED_INTEREST FOR XML RAW, TYPE)

	SET @op_amount = ISNULL(@step_overdue_percent, $0.00) + ISNULL(@step_overdue_principal, $0.00) + ISNULL(@step_overdue_insurance, $0.00) + ISNULL(@step_overdue_service_fee, $0.00) + ISNULL(@step_defered_interest, $0.00)

	INSERT INTO dbo.LOAN_OPS(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, PARENT_OP_ID, AMOUNT, OP_DATA, OP_DETAILS, [OWNER], UPDATE_DATA, UPDATE_SCHEDULE)
	VALUES(@loan_id, @date, dbo.loan_const_op_overdue(), 0, @parent_op_id, @op_amount, @op_data, @op_details, @user_id, 1, 0)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

	SET @child_op_id = SCOPE_IDENTITY()

	UPDATE #tbl_overdue
	SET OVERDUE_OP_ID = @child_op_id
	WHERE LOAN_ID = @loan_id AND OVERDUE_OP_ID = -1

	IF @parent_op_id IS NULL
		SET @parent_op_id = @child_op_id

	IF @before_op_accounting = 0
	BEGIN
		EXEC @r = dbo.LOAN_SP_PROCESS_BEFORE_OP_ACCOUNTING
			@doc_rec_id			= @doc_rec_id OUTPUT,
			@op_id				= @child_op_id,
			@user_id			= @user_id,
			@doc_date			= @date,
			@by_processing		= 1,
			@simulate			= 0
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

		SET @before_op_accounting = 1
	END

	EXEC @r = dbo.LOAN_SP_EXEC_OP
		@doc_rec_id = @doc_rec_id OUTPUT,
		@op_id = @child_op_id,
		@user_id = @user_id,
		@by_processing = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END
END

_skip_overdue:	

IF (@guarantee = 1) AND (@remaining_fee > $0.00) AND (MONTH(@date) = MONTH(@start_date) AND DAY(@date) = dbo.days_per_month(@date))
BEGIN
	SET @op_amount = @remaining_fee
	
	INSERT INTO dbo.LOAN_OPS(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, PARENT_OP_ID, AMOUNT, OP_DATA, OP_NOTE, [OWNER], UPDATE_DATA, UPDATE_SCHEDULE)
	VALUES(@loan_id, @date, dbo.loan_const_op_guar_fee2(), 0, NULL, @op_amount, NULL, NULL, @user_id, 0, 0)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

	SET @child_op_id =  SCOPE_IDENTITY()

	EXEC @r = dbo.LOAN_SP_EXEC_OP
		@doc_rec_id = @doc_rec_id OUTPUT,
		@op_id = @child_op_id,
		@user_id = @user_id,
		@by_processing = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END	
END


--დეტალების გადატანა არქივში

SET @payed_principal = ISNULL(@principal_payed, $0.00) + ISNULL(@overdue_principal_payed, $0.00) + ISNULL(@calloff_principal_payed, $0.00) + ISNULL(@writeoff_principal_payed, $0.00)


IF ISNULL(@category_6, $0.00) > $0.00
BEGIN
	IF ISNULL(@category_6, $0.00) > @payed_principal
	BEGIN
		SET @category_6 = @category_6 - @payed_principal
		SET @payed_principal = $0.00 
	END
	ELSE
	BEGIN
		SET @payed_principal = @payed_principal - @category_6
		SET @category_6 = $0.00
	END
END

IF ISNULL(@category_5, $0.00) > $0.00
BEGIN
	IF ISNULL(@category_5, $0.00) > @payed_principal
	BEGIN
		SET @category_5 = @category_5 - @payed_principal
		SET @payed_principal = $0.00 
	END
	ELSE
	BEGIN
		SET @payed_principal = @payed_principal - @category_5
		SET @category_5 = $0.00
	END
END

IF ISNULL(@category_4, $0.00) > $0.00
BEGIN
	IF ISNULL(@category_4, $0.00) > @payed_principal
	BEGIN
		SET @category_4 = @category_4 - @payed_principal
		SET @payed_principal = $0.00 
	END
	ELSE
	BEGIN
		SET @payed_principal = @payed_principal - @category_4
		SET @category_4 = $0.00 
	END
END 

IF ISNULL(@category_3, $0.00) > $0.00
BEGIN
	IF ISNULL(@category_3, $0.00) > @payed_principal
	BEGIN
		SET @category_3 = @category_3 - @payed_principal
		SET @payed_principal = $0.00 
	END
	ELSE
	BEGIN
		SET @payed_principal = @payed_principal - @category_3
		SET @category_3 = $0.00
	END
END 

IF ISNULL(@category_2, $0.00) > $0.00
BEGIN
	IF ISNULL(@category_2, $0.00) > @payed_principal
	BEGIN
		SET @category_2 = @category_2 - @payed_principal
		SET @payed_principal = $0.00 
	END
	ELSE
	BEGIN
		SET @payed_principal = @payed_principal - @category_2
		SET @category_2 = $0.00
	END
END 

IF ISNULL(@category_1, $0.00) > $0.00
BEGIN
	IF ISNULL(@category_1, $0.00) > @payed_principal
	BEGIN
		SET @category_1 = @category_1 - @payed_principal
		SET @payed_principal = $0.00 
	END
	ELSE
	BEGIN
		SET @payed_principal = @payed_principal - @category_1
		SET @category_1 = $0.00 
	END
END 

SET @max_category_level = 1

IF ISNULL(@category_6, $0.00) > $0.00
	SET @max_category_level = 6
ELSE
IF ISNULL(@category_5, $0.00) > $0.00
	SET @max_category_level = 5
ELSE
IF ISNULL(@category_4, $0.00) > $0.00
	SET @max_category_level = 4
ELSE
IF ISNULL(@category_3, $0.00) > $0.00
	SET @max_category_level = 3
ELSE
IF ISNULL(@category_2, $0.00) > $0.00
	SET @max_category_level = 2

INSERT INTO dbo.LOAN_DETAILS_HISTORY 
	(	LOAN_ID, CALC_DATE, PREV_STEP,
		NU_PRINCIPAL,
		NU_INTEREST,
		NU_INTEREST_DAILY, NU_INTEREST_FRACTION,
		PRINCIPAL,
		INTEREST,
		INTEREST_DAILY, INTEREST_FRACTION,
		LATE_DATE,
		LATE_PRINCIPAL,
		LATE_PERCENT,
		OVERDUE_DATE,
		OVERDUE_PRINCIPAL,
		OVERDUE_PRINCIPAL_INTEREST,
		OVERDUE_PRINCIPAL_INTEREST_DAILY, OVERDUE_PRINCIPAL_INTEREST_FRACTION,
	    OVERDUE_PRINCIPAL_PENALTY,
		OVERDUE_PRINCIPAL_PENALTY_DAILY, OVERDUE_PRINCIPAL_PENALTY_FRACTION,
		OVERDUE_PERCENT,
		OVERDUE_PERCENT_PENALTY,
		OVERDUE_PERCENT_PENALTY_DAILY, OVERDUE_PERCENT_PENALTY_FRACTION,
		CALLOFF_PRINCIPAL,
		CALLOFF_PRINCIPAL_INTEREST,
		CALLOFF_PRINCIPAL_INTEREST_DAILY, CALLOFF_PRINCIPAL_INTEREST_FRACTION,
	    CALLOFF_PRINCIPAL_PENALTY,
		CALLOFF_PRINCIPAL_PENALTY_DAILY, CALLOFF_PRINCIPAL_PENALTY_FRACTION,
		CALLOFF_PERCENT,
		CALLOFF_PERCENT_PENALTY,
		CALLOFF_PERCENT_PENALTY_DAILY, CALLOFF_PERCENT_PENALTY_FRACTION,
		CALLOFF_PENALTY,
		WRITEOFF_PRINCIPAL,
		WRITEOFF_PRINCIPAL_PENALTY,
		WRITEOFF_PRINCIPAL_PENALTY_DAILY, WRITEOFF_PRINCIPAL_PENALTY_FRACTION,
		WRITEOFF_PERCENT,
		WRITEOFF_PERCENT_PENALTY,
		WRITEOFF_PERCENT_PENALTY_DAILY, WRITEOFF_PERCENT_PENALTY_FRACTION,
		WRITEOFF_PENALTY,
		IMMEDIATE_PENALTY,
		FINE,
		MAX_CATEGORY_LEVEL,
		CATEGORY_1,
		CATEGORY_2,
		CATEGORY_3,
		CATEGORY_4,
		CATEGORY_5,
		CATEGORY_6,
		OVERDUE_INSURANCE,
		OVERDUE_SERVICE_FEE,	
		DEFERABLE_INTEREST,
		DEFERABLE_OVERDUE_INTEREST,
		DEFERABLE_PENALTY,
		DEFERABLE_FINE)
SELECT
	LOAN_ID, CALC_DATE, PREV_STEP,
	CASE WHEN ISNULL(@nu_principal,$0.00)=$0.00 THEN NULL ELSE @nu_principal END AS NU_PRINCIPAL,
	CASE WHEN ISNULL(@nu_interest,$0.00)=$0.00 THEN NULL ELSE @nu_interest END AS NU_INTEREST,
	NU_INTEREST_DAILY, NU_INTEREST_FRACTION,
	CASE WHEN ISNULL(@principal,$0.00)=$0.00 THEN NULL ELSE @principal END AS PRINCIPAL,
	CASE WHEN ISNULL(@interest,$0.00)=$0.00 THEN NULL ELSE @interest END AS INTEREST,
	INTEREST_DAILY, INTEREST_FRACTION,
	LATE_DATE,
	NULL AS LATE_PRINCIPAL,
	NULL AS LATE_PERCENT,
	OVERDUE_DATE,
	CASE WHEN ISNULL(@overdue_principal,$0.00)=$0.00 THEN NULL ELSE @overdue_principal END AS OVERDUE_PRINCIPAL,
	CASE WHEN ISNULL(@overdue_principal_interest,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_interest END AS OVERDUE_PRINCIPAL_INTEREST,
	OVERDUE_PRINCIPAL_INTEREST_DAILY, OVERDUE_PRINCIPAL_INTEREST_FRACTION,
	CASE WHEN ISNULL(@overdue_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_penalty END AS OVERDUE_PRINCIPAL_PENALTY,
	OVERDUE_PRINCIPAL_PENALTY_DAILY, OVERDUE_PRINCIPAL_PENALTY_FRACTION,
	CASE WHEN ISNULL(@overdue_percent,$0.00)=$0.00 THEN NULL ELSE @overdue_percent END AS OVERDUE_PERCENT,
	CASE WHEN ISNULL(@overdue_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @overdue_percent_penalty END AS OVERDUE_PERCENT_PENALTY,
	OVERDUE_PERCENT_PENALTY_DAILY, OVERDUE_PERCENT_PENALTY_FRACTION,
	CASE WHEN ISNULL(@calloff_principal,$0.00)=$0.00 THEN NULL ELSE @calloff_principal END AS CALLOFF_PRINCIPAL,
	CASE WHEN ISNULL(@calloff_principal_interest,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_interest END AS CALLOFF_PRINCIPAL_INTEREST,
	CALLOFF_PRINCIPAL_INTEREST_DAILY, CALLOFF_PRINCIPAL_INTEREST_FRACTION,
	CASE WHEN ISNULL(@calloff_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_penalty END AS CALLOFF_PRINCIPAL_PENALTY,
	CALLOFF_PRINCIPAL_PENALTY_DAILY, CALLOFF_PRINCIPAL_PENALTY_FRACTION,
	CASE WHEN ISNULL(@calloff_percent,$0.00)=$0.00 THEN NULL ELSE @calloff_percent END AS CALLOFF_PERCENT,
	CASE WHEN ISNULL(@calloff_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_percent_penalty END AS CALLOFF_PERCENT_PENALTY,
	CALLOFF_PERCENT_PENALTY_DAILY, CALLOFF_PERCENT_PENALTY_FRACTION,
	CASE WHEN ISNULL(@calloff_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_penalty END AS CALLOFF_PENALTY,
	CASE WHEN ISNULL(@writeoff_principal,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal END AS WRITEOFF_PRINCIPAL,
	CASE WHEN ISNULL(@writeoff_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal_penalty END AS WRITEOFF_PRINCIPAL_PENALTY,
	WRITEOFF_PRINCIPAL_PENALTY_DAILY, WRITEOFF_PRINCIPAL_PENALTY_FRACTION,
	CASE WHEN ISNULL(@writeoff_percent,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent END AS WRITEOFF_PERCENT,
	CASE WHEN ISNULL(@writeoff_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent_penalty END AS WRITEOFF_PERCENT_PENALTY,
	WRITEOFF_PERCENT_PENALTY_DAILY, WRITEOFF_PERCENT_PENALTY_FRACTION,
	CASE WHEN ISNULL(@writeoff_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_penalty END AS WRITEOFF_PENALTY,
	CASE WHEN ISNULL(@immediate_penalty,$0.00)=$0.00 THEN NULL ELSE @immediate_penalty END AS IMMEDIATE_PENALTY,
	CASE WHEN ISNULL(@fine,$0.00)=$0.00 THEN NULL ELSE @fine END AS FINE,
	@max_category_level AS MAX_CATEGORY_LEVEL,
	@category_1 AS CATEGORY_1,
	@category_2 AS CATEGORY_2,
	@category_3 AS CATEGORY_3,
	@category_4 AS CATEGORY_4,
	@category_5 AS CATEGORY_5,
	@category_6 AS CATEGORY_6,
	CASE WHEN ISNULL(@overdue_insurance,$0.00)=$0.00 THEN NULL ELSE @overdue_insurance END AS OVERDUE_INSURANCE,
	CASE WHEN ISNULL(@overdue_service_fee,$0.00)=$0.00 THEN NULL ELSE @overdue_service_fee END AS OVERDUE_SERVICE_FEE,
	CASE WHEN ISNULL(@deferable_interest,$0.00)=$0.00 THEN NULL ELSE @deferable_interest END AS DEFERABLE_INTEREST,
	CASE WHEN ISNULL(@deferable_overdue_interest,$0.00)=$0.00 THEN NULL ELSE @deferable_overdue_interest END AS DEFERABLE_OVERDUE_INTEREST,
	CASE WHEN ISNULL(@deferable_penalty,$0.00)=$0.00 THEN NULL ELSE @deferable_penalty END AS DEFERABLE_PENALTY,
	CASE WHEN ISNULL(@deferable_fine,$0.00)=$0.00 THEN NULL ELSE @deferable_fine END AS DEFERABLE_FINE
FROM dbo.LOAN_DETAILS
WHERE LOAN_ID = @loan_id

IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

/* დავალიანების დარიცხვა */
IF (@schedule_date IS NOT NULL) AND (@date = @schedule_date)
BEGIN
	SET @prev_step = @schedule_date --გადაყენდეს წინა უახლოესი დაფარვის თარიღი გრაფიკის მიხედვით
	
	SELECT TOP 1 @schedule_date=SCHEDULE_DATE, @schedule_interest_date=INTEREST_DATE, @schedule_principal=ISNULL(PRINCIPAL, $0.00), @schedule_interest=ISNULL(INTEREST, $0.00), @schedule_nu_interest=ISNULL(NU_INTEREST, $0.00), @schedule_balance=ISNULL(BALANCE, $0.00), @schedule_pay_interest=PAY_INTEREST,
		@schedule_nu_interest_correction = NU_INTEREST_CORRECTION, @schedule_interest_correction = INTEREST_CORRECTION
	FROM dbo.LOAN_SCHEDULE
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @schedule_date
	ORDER BY SCHEDULE_DATE
END

IF (@schedule_type = 64) AND (@date = @grace_finish_date)
BEGIN
	SELECT 
		@op_amount = SUM(ISNULL(DEFERED_INTEREST, $0.0)) - ISNULL(@deferable_interest, $0.00)
	FROM dbo.LOAN_SCHEDULE
	WHERE LOAN_ID = @loan_id
	
	SET @op_data =
		(SELECT 
			ISNULL(@interest, $0.00) AS INTEREST_OLD,
			ISNULL(@deferable_interest, $0.00) AS DEF_INTEREST_OLD,
			ISNULL(@deferable_interest, $0.00) AS DEF_DEBT_OLD,
			ISNULL(@interest, $0.00) AS DEBT_OLD,
			ISNULL(@interest, $0.00) AS DEF_INTEREST,
			ISNULL(@interest, $0.00) AS DEF_DEBT FOR XML RAW, TYPE)

	SET @op_note = 'ÀÅÔÏÌÀÔÖÒÉ ÂÄÍÄÒÀÝÉÀ, ÓÀÛÄÙÀÅÀÈÏ ÐÄÒÉÏÃÉÓ ÀÌÏßÖÒÅÉÓ ÈÀÒÉÙÛÉ'

	INSERT INTO dbo.LOAN_OPS(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, PARENT_OP_ID, AMOUNT, OP_DATA, OP_NOTE, [OWNER], UPDATE_DATA, UPDATE_SCHEDULE)
	VALUES(@loan_id, @date, dbo.loan_const_op_debt_defere(), 0xFF, NULL, @op_amount, @op_data, @op_note, @user_id, 0, 0)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END


	SET @deferable_interest = @op_amount + ISNULL(@deferable_interest, $0.00)
	SET @interest = $0.00
	SET @prev_step = @date
END

SET @schedule_control = CASE WHEN (@schedule_type = 64) AND (@date < @grace_finish_date) THEN 0 ELSE 1 END

EXEC @r = dbo.loan_get_accrual_amounts
	@loan_id = @loan_id,
	@guarantee = @guarantee,
	@disburse_type = @disburse_type,
	@date = @_date,
	@schedule_control = @schedule_control, -- დარიცხული პროცენტი დაანგარიშდეს გრაფიკის პროცენტიდან  1, თუ დარჩენილი ძირიდან 0
	@schedule_date = @schedule_date,
	@end_date = @end_date,
	@schedule_interest = @schedule_interest,
	@schedule_nu_interest = @schedule_nu_interest,
	@schedule_balance = @schedule_balance,
	@schedule_pay_interest = @schedule_pay_interest,
	@schedule_nu_interest_correction = @schedule_nu_interest_correction,
	@schedule_interest_correction = @schedule_interest_correction,

	@calc_date	= @date,
	@prev_step	= @prev_step,
	@interest_flags = @interest_flags,
	@penalty_flags = @penalty_flags,
	@nu_intrate = @nu_intrate,
	@intrate = @intrate,
	@basis = @basis,
	@penalty_intrate = @penalty_intrate,
	@penalty_delta = @penalty_delta,

	/*ძირითადი თანხები */
	@nu_principal = @nu_principal,
	@principal = @principal,
	@overdue_principal = @overdue_principal,
	@calloff_principal = @calloff_principal,
	@writeoff_principal = @writeoff_principal,

	/*პროცენტები*/
	@overdue_percent = @overdue_percent,
	@calloff_percent = @calloff_percent,
	@writeoff_percent = @writeoff_percent,

	@nu_interest = @nu_interest OUTPUT, 
	@nu_interest_daily = @nu_interest_daily OUTPUT,
	@nu_interest_fraction = @nu_interest_fraction OUTPUT,

	@interest = @interest OUTPUT,
	@interest_daily = @interest_daily OUTPUT,
	@interest_fraction = @interest_fraction OUTPUT, 

	@overdue_principal_interest = @overdue_principal_interest OUTPUT,
	@overdue_principal_interest_daily = @overdue_principal_interest_daily OUTPUT,
	@overdue_principal_interest_fraction = @overdue_principal_interest_fraction OUTPUT,
	@overdue_principal_penalty = @overdue_principal_penalty OUTPUT,
	@overdue_principal_penalty_daily = @overdue_principal_penalty_daily OUTPUT,
	@overdue_principal_penalty_fraction = @overdue_principal_penalty_fraction OUTPUT,
	@overdue_percent_penalty = @overdue_percent_penalty OUTPUT,
	@overdue_percent_penalty_daily = @overdue_percent_penalty_daily OUTPUT,
	@overdue_percent_penalty_fraction = @overdue_percent_penalty_fraction OUTPUT,

	@calloff_principal_interest = @calloff_principal_interest OUTPUT,
	@calloff_principal_interest_daily = @calloff_principal_interest_daily OUTPUT,
	@calloff_principal_interest_fraction = @calloff_principal_interest_fraction OUTPUT,
	@calloff_principal_penalty = @calloff_principal_penalty OUTPUT,
	@calloff_principal_penalty_daily = @calloff_principal_penalty_daily OUTPUT,
	@calloff_principal_penalty_fraction = @calloff_principal_penalty_fraction OUTPUT,
	@calloff_percent_penalty = @calloff_percent_penalty OUTPUT,
	@calloff_percent_penalty_daily = @calloff_percent_penalty_daily OUTPUT,
	@calloff_percent_penalty_fraction = @calloff_percent_penalty_fraction OUTPUT,

	@writeoff_principal_penalty = @writeoff_principal_penalty OUTPUT,
	@writeoff_principal_penalty_daily = @writeoff_principal_penalty_daily OUTPUT,
	@writeoff_principal_penalty_fraction = @writeoff_principal_penalty_fraction OUTPUT,
	@writeoff_percent_penalty = @writeoff_percent_penalty OUTPUT,
	@writeoff_percent_penalty_daily = @writeoff_percent_penalty_daily OUTPUT,	
	@writeoff_percent_penalty_fraction = @writeoff_percent_penalty_fraction OUTPUT	
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

/* მონაცემების შეცვლა */

/* ვადაგადაცილების თარიღების დადგენა  */
SET @overdue_date = NULL

SELECT @overdue_date = MIN(OVERDUE_DATE)
FROM #tbl_overdue 
WHERE (LOAN_ID = @loan_id) AND (ISNULL(OVERDUE_PRINCIPAL, $0.00) + ISNULL(OVERDUE_PERCENT, $0.00) <> $0.00) 

DELETE dbo.LOAN_DETAIL_OVERDUE
WHERE LOAN_ID = @loan_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

INSERT INTO dbo.LOAN_DETAIL_OVERDUE(LOAN_ID,OVERDUE_DATE,LATE_OP_ID,OVERDUE_OP_ID,OVERDUE_PRINCIPAL,OVERDUE_PERCENT)
SELECT LOAN_ID,OVERDUE_DATE,LATE_OP_ID,OVERDUE_OP_ID,OVERDUE_PRINCIPAL,OVERDUE_PERCENT
FROM #tbl_overdue
WHERE LOAN_ID = @loan_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

UPDATE dbo.LOAN_DETAILS
SET 
	CALC_DATE = @_date,
	PREV_STEP = @prev_step,
	NU_PRINCIPAL = CASE WHEN ISNULL(@nu_principal,$0.00)=$0.00 THEN NULL ELSE @nu_principal END,
	NU_INTEREST = CASE WHEN ISNULL(@nu_interest,$0.00)=$0.00 THEN NULL ELSE @nu_interest END,
	NU_INTEREST_DAILY = CASE WHEN ISNULL(@nu_interest_daily,$0.00)=$0.00 THEN NULL ELSE @nu_interest_daily END,
	NU_INTEREST_FRACTION = CASE WHEN ISNULL(@nu_interest_fraction,$0.00)=$0.00 THEN NULL ELSE @nu_interest_fraction END,
	PRINCIPAL = CASE WHEN ISNULL(@principal,$0.00)=$0.00 THEN NULL ELSE @principal END,
	INTEREST = CASE WHEN ISNULL(@interest,$0.00)=$0.00 THEN NULL ELSE @interest END,
	INTEREST_DAILY = CASE WHEN ISNULL(@interest_daily,$0.00)=$0.00 THEN NULL ELSE @interest_daily END,
	INTEREST_FRACTION = CASE WHEN ISNULL(@interest_fraction,$0.00)=$0.00 THEN NULL ELSE @interest_fraction END,
	OVERDUE_DATE = CASE WHEN ISNULL(@penalty_debt, $0.00) = $0.00 THEN @overdue_date ELSE OVERDUE_DATE END,
	OVERDUE_PRINCIPAL = CASE WHEN ISNULL(@overdue_principal,$0.00)=$0.00 THEN NULL ELSE @overdue_principal END,
	OVERDUE_PRINCIPAL_INTEREST = CASE WHEN ISNULL(@overdue_principal_interest,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_interest END,
	OVERDUE_PRINCIPAL_INTEREST_DAILY = CASE WHEN ISNULL(@overdue_principal_interest_daily,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_interest_daily END,
	OVERDUE_PRINCIPAL_INTEREST_FRACTION = CASE WHEN ISNULL(@overdue_principal_interest_fraction,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_interest_fraction END,
	OVERDUE_PRINCIPAL_PENALTY = CASE WHEN ISNULL(@overdue_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_penalty END,
	OVERDUE_PRINCIPAL_PENALTY_DAILY = CASE WHEN ISNULL(@overdue_principal_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_penalty_daily END,
	OVERDUE_PRINCIPAL_PENALTY_FRACTION = CASE WHEN ISNULL(@overdue_principal_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_penalty_fraction END,
	OVERDUE_PERCENT = CASE WHEN ISNULL(@overdue_percent,$0.00)=$0.00 THEN NULL ELSE @overdue_percent END,
	OVERDUE_PERCENT_PENALTY = CASE WHEN ISNULL(@overdue_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @overdue_percent_penalty END,
	OVERDUE_PERCENT_PENALTY_DAILY = CASE WHEN ISNULL(@overdue_percent_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @overdue_percent_penalty_daily END,
	OVERDUE_PERCENT_PENALTY_FRACTION = CASE WHEN ISNULL(@overdue_percent_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @overdue_percent_penalty_fraction END,
	CALLOFF_PRINCIPAL = CASE WHEN ISNULL(@calloff_principal,$0.00)=$0.00 THEN NULL ELSE @calloff_principal END,
	CALLOFF_PRINCIPAL_INTEREST = CASE WHEN ISNULL(@calloff_principal_interest,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_interest END,
	CALLOFF_PRINCIPAL_INTEREST_DAILY = CASE WHEN ISNULL(@calloff_principal_interest_daily,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_interest_daily END,
	CALLOFF_PRINCIPAL_INTEREST_FRACTION = CASE WHEN ISNULL(@calloff_principal_interest_fraction,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_interest_fraction END,
	CALLOFF_PRINCIPAL_PENALTY = CASE WHEN ISNULL(@calloff_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_penalty END,
	CALLOFF_PRINCIPAL_PENALTY_DAILY = CASE WHEN ISNULL(@calloff_principal_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_penalty_daily END,
	CALLOFF_PRINCIPAL_PENALTY_FRACTION = CASE WHEN ISNULL(@calloff_principal_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_penalty_fraction END,
	CALLOFF_PERCENT = CASE WHEN ISNULL(@calloff_percent,$0.00)=$0.00 THEN NULL ELSE @calloff_percent END,
	CALLOFF_PERCENT_PENALTY = CASE WHEN ISNULL(@calloff_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_percent_penalty END,
	CALLOFF_PERCENT_PENALTY_DAILY = CASE WHEN ISNULL(@calloff_percent_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @calloff_percent_penalty_daily END,
	CALLOFF_PERCENT_PENALTY_FRACTION = CASE WHEN ISNULL(@calloff_percent_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @calloff_percent_penalty_fraction END,
	CALLOFF_PENALTY = CASE WHEN ISNULL(@calloff_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_penalty END,
	WRITEOFF_PRINCIPAL = CASE WHEN ISNULL(@writeoff_principal,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal END,
	WRITEOFF_PRINCIPAL_PENALTY = CASE WHEN ISNULL(@writeoff_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal_penalty END,
	WRITEOFF_PRINCIPAL_PENALTY_DAILY = CASE WHEN ISNULL(@writeoff_principal_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal_penalty_daily END,
	WRITEOFF_PRINCIPAL_PENALTY_FRACTION = CASE WHEN ISNULL(@writeoff_principal_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal_penalty_fraction END,
	WRITEOFF_PERCENT = CASE WHEN ISNULL(@writeoff_percent,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent END,
	WRITEOFF_PERCENT_PENALTY = CASE WHEN ISNULL(@writeoff_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent_penalty END,
	WRITEOFF_PERCENT_PENALTY_DAILY = CASE WHEN ISNULL(@writeoff_percent_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent_penalty_daily END,
	WRITEOFF_PERCENT_PENALTY_FRACTION = CASE WHEN ISNULL(@writeoff_percent_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent_penalty_fraction END,
	WRITEOFF_PENALTY = CASE WHEN ISNULL(@writeoff_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_penalty END,
	IMMEDIATE_PENALTY = CASE WHEN ISNULL(@immediate_penalty,$0.00)=$0.00 THEN NULL ELSE @immediate_penalty END,
	FINE = CASE WHEN ISNULL(@fine,$0.00)=$0.00 THEN NULL ELSE @fine END,
	MAX_CATEGORY_LEVEL = @max_category_level,
	CATEGORY_1 = CASE WHEN ISNULL(@category_1,$0.00)=$0.00 THEN NULL ELSE @category_1 END,
	CATEGORY_2 = CASE WHEN ISNULL(@category_2,$0.00)=$0.00 THEN NULL ELSE @category_2 END,
	CATEGORY_3 = CASE WHEN ISNULL(@category_3,$0.00)=$0.00 THEN NULL ELSE @category_3 END,
	CATEGORY_4 = CASE WHEN ISNULL(@category_4,$0.00)=$0.00 THEN NULL ELSE @category_4 END,
	CATEGORY_5 = CASE WHEN ISNULL(@category_5,$0.00)=$0.00 THEN NULL ELSE @category_5 END,
	CATEGORY_6 = CASE WHEN ISNULL(@category_6,$0.00)=$0.00 THEN NULL ELSE @category_6 END,
	OVERDUE_INSURANCE = CASE WHEN ISNULL(@overdue_insurance,$0.00)=$0.00 THEN NULL ELSE @overdue_insurance END,
	OVERDUE_SERVICE_FEE = CASE WHEN ISNULL(@overdue_service_fee,$0.00)=$0.00 THEN NULL ELSE @overdue_service_fee END,
	DEFERABLE_INTEREST = CASE WHEN ISNULL(@deferable_interest,$0.00)=$0.00 THEN NULL ELSE @deferable_interest END,
	DEFERABLE_OVERDUE_INTEREST = CASE WHEN ISNULL(@deferable_overdue_interest,$0.00)=$0.00 THEN NULL ELSE @deferable_overdue_interest END,
	DEFERABLE_PENALTY = CASE WHEN ISNULL(@deferable_penalty,$0.00)=$0.00 THEN NULL ELSE @deferable_penalty END,
	DEFERABLE_FINE = CASE WHEN ISNULL(@deferable_fine,$0.00)=$0.00 THEN NULL ELSE @deferable_fine END
WHERE LOAN_ID = @loan_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

SET @debt_amount = ISNULL(@nu_interest, $0.00) + ISNULL(@interest, $0.00)+ @principal + 
		@overdue_principal + @overdue_principal_interest + @overdue_principal_penalty +
		@overdue_percent + @overdue_percent_penalty +
		@calloff_principal + @calloff_principal_interest + @calloff_principal_penalty +
		@calloff_percent + @calloff_percent_penalty + @calloff_penalty +
		@writeoff_principal + @writeoff_principal_penalty + 
		@writeoff_percent + @writeoff_percent_penalty +	@writeoff_penalty +
		@fine + @overdue_insurance + @overdue_service_fee + @rate_diff + 
		@deferable_interest + @deferable_overdue_interest + @deferable_penalty + @deferable_fine

IF ISNULL(@debt_amount, $0.00) = $0.00 AND @end_date <= @date
BEGIN
	SET @op_data = (SELECT [STATE] FROM dbo.LOANS WHERE LOAN_ID = @loan_id FOR XML RAW, TYPE)

	INSERT INTO dbo.LOAN_OPS(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, PARENT_OP_ID, AMOUNT, OP_DATA, [OWNER], UPDATE_DATA, UPDATE_SCHEDULE, NOTE_REC_ID)
	VALUES(@loan_id, @date, dbo.loan_const_op_close(), 0, @parent_op_id, $0.00, @op_data, @user_id, 0, 0, NULL)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END
	
	SET @child_op_id =  SCOPE_IDENTITY()

	IF @before_op_accounting = 0
	BEGIN
		EXEC @r = dbo.LOAN_SP_PROCESS_BEFORE_OP_ACCOUNTING
			@doc_rec_id			= @doc_rec_id OUTPUT,
			@op_id				= @child_op_id,
			@user_id			= @user_id,
			@doc_date			= @date,
			@by_processing		= 1,
			@simulate			= 0
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

		SET @before_op_accounting = 1
	END

	EXEC @r = dbo.LOAN_SP_EXEC_OP
		@doc_rec_id = @doc_rec_id OUTPUT,
		@op_id = @child_op_id,
		@user_id = @user_id,
		@by_processing = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END
END


IF @op_count > 1
	UPDATE dbo.LOAN_OPS
	SET PARENT_OP_ID = -1
	WHERE OP_ID = @parent_op_id

DROP TABLE #tbl_overdue

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
