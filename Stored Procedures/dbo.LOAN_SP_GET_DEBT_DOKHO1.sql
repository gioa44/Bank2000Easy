SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_DEBT_DOKHO1]
	@loan_id int,
	@amount money = null,
	@prepaym_intrate money = NULL,
	@principal_payment money = NULL
AS
CREATE TABLE #tbl (
	LOAN_ID int NOT NULL,
	MIN_DEBT money NULL,
	MAX_DEBT money NULL,
	NO_CHARGE_DEBT money NULL,
	LATE_DATE smalldatetime NULL,
	PREV_STEP smalldatetime NULL,
	CALC_DATE smalldatetime NULL,
	NU_PRINCIPAL money NULL,
	NU_INTEREST money NULL,
	PRINCIPAL money NULL,
	INTEREST money NULL,
	LATE_PRINCIPAL money NULL,
	LATE_PERCENT money NULL,
	OVERDUE_DATE smalldatetime NULL,
	OVERDUE_PRINCIPAL money NULL,
	OVERDUE_PRINCIPAL_INTEREST money NULL,
	OVERDUE_PRINCIPAL_PENALTY money NULL,
	OVERDUE_PERCENT money NULL,
	OVERDUE_PERCENT_PENALTY money NULL,
	WRITEOFF_PRINCIPAL money NULL,
	WRITEOFF_PRINCIPAL_PENALTY money NULL,
	WRITEOFF_PERCENT money NULL,
	WRITEOFF_PERCENT_PENALTY money NULL,
	WRITEOFF_PENALTY money NULL,
	CALLOFF_PRINCIPAL money NULL,
	CALLOFF_PRINCIPAL_INTEREST money NULL,
	CALLOFF_PRINCIPAL_PENALTY money NULL,
	CALLOFF_PERCENT money NULL,
	CALLOFF_PERCENT_PENALTY money NULL,
	CALLOFF_PENALTY money NULL,
	DEFERED_AMOUNT money NULL,
	NEXT_DATE smalldatetime NULL,
	NEXT_PRINCIPAL money NULL,
	NEXT_INTEREST money NULL,
	NEXT_NU_INTEREST money NULL,
	PREPAYMENT money NULL,
	PREPAYMENT_PENALTY money NULL,
	INFO_MSG varchar(1000) NULL
)

DECLARE
	@info_msg varchar(1000),
	@prev_step smalldatetime,
	@calc_date smalldatetime,

	@max_debt money,
	@min_debt money,
	@no_charge_debt money,

	@nu_principal money,
	@nu_interest money,
	@principal money,
	@interest money,
	@late_date smalldatetime,
	@late_principal money,
	@late_percent money,
	@overdue_date smalldatetime,
	@overdue_principal money,
	@overdue_principal_interest money,
	@overdue_principal_penalty money,
	@overdue_percent money,
	@overdue_percent_penalty money,
	@writeoff_principal money,
	@writeoff_principal_penalty money,
	@writeoff_percent money,
	@writeoff_percent_penalty money,
	@writeoff_penalty money,
	@calloff_principal money,
	@calloff_principal_interest money,
	@calloff_principal_penalty money,
	@calloff_percent money,
	@calloff_percent_penalty money,
	@calloff_penalty money,
	@defered_amount money,
	@next_date smalldatetime,
	@next_principal money,
	@next_interest money,
	@next_nu_interest money,
	@next_limit money

DECLARE
	@schedule_type tinyint, -- --> LOAN_SCHEDULE_TYPES
	@prepayment_intrate money,
	@prepayment money,
	@no_charge_prepayment money,
	@prepayment_penalty money,
	@prepayment_step tinyint,
	@sched_payment_count tinyint

SELECT
	@prev_step = PREV_STEP,
	@calc_date = CALC_DATE,
	@nu_principal = ROUND(ISNULL(NU_PRINCIPAL, $0.00), 2, 1), 
	@nu_interest = ROUND(ISNULL(NU_INTEREST, $0.00), 2, 1), 
	@principal = ROUND(ISNULL(PRINCIPAL, $0.00), 2, 1), 
	@interest = ROUND(ISNULL(INTEREST, $0.00), 2, 1), 
	@nu_interest = ROUND(ISNULL(NU_INTEREST, $0.00), 2, 1), 
	@late_date = LATE_DATE,
	@late_principal = ROUND(ISNULL(LATE_PRINCIPAL, $0.00), 2, 1), 
	@late_percent = ROUND(ISNULL(LATE_PERCENT, $0.00), 2, 1),
	@overdue_date = OVERDUE_DATE,
	@overdue_principal = ROUND(ISNULL(OVERDUE_PRINCIPAL, $0.00), 2, 1), 
	@overdue_principal_interest = ROUND(ISNULL(OVERDUE_PRINCIPAL_INTEREST, $0.00), 2, 1), 
	@overdue_principal_penalty = ROUND(ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00), 2, 1), 
	@overdue_percent = ROUND(ISNULL(OVERDUE_PERCENT, $0.00), 2, 1), 
	@overdue_percent_penalty = ROUND(ISNULL(OVERDUE_PERCENT_PENALTY, $0.00), 2, 1), 
	@writeoff_principal = ROUND(ISNULL(WRITEOFF_PRINCIPAL, $0.00), 2, 1), 
	@writeoff_principal_penalty = ROUND(ISNULL(WRITEOFF_PRINCIPAL_PENALTY, $0.00), 2, 1), 
	@writeoff_percent = ROUND(ISNULL(WRITEOFF_PERCENT, $0.00), 2, 1), 
	@writeoff_percent_penalty = ROUND(ISNULL(WRITEOFF_PERCENT_PENALTY, $0.00), 2, 1), 
	@writeoff_penalty = ROUND(ISNULL(WRITEOFF_PENALTY, $0.00), 2, 1), 
	@calloff_principal = ROUND(ISNULL(CALLOFF_PRINCIPAL, $0.00), 2, 1), 
	@calloff_principal_interest = ROUND(ISNULL(CALLOFF_PRINCIPAL_INTEREST, $0.00), 2, 1),
	@calloff_principal_penalty = ROUND(ISNULL(CALLOFF_PRINCIPAL_PENALTY, $0.00), 2, 1),
	@calloff_percent = ROUND(ISNULL(CALLOFF_PERCENT, $0.00), 2, 1),
	@calloff_percent_penalty = ROUND(ISNULL(CALLOFF_PERCENT_PENALTY, $0.00), 2, 1),
	@calloff_penalty = ROUND(ISNULL(CALLOFF_PENALTY, $0.00), 2, 1),
	@defered_amount = ROUND(ISNULL(DEFERED_AMOUNT, $0.00), 2, 1) 
FROM dbo.LOAN_DETAILS (NOLOCK)
WHERE LOAN_ID = @loan_id

SELECT 
	@schedule_type = SCHEDULE_TYPE, 
	@prepayment_intrate = PREPAYMENT_INTRATE, 
	@prepayment_step = PREPAYMENT_STEP 
FROM dbo.LOANS  (NOLOCK)
WHERE LOAN_ID = @loan_id


IF @schedule_type = 32 --თუ არ არის სესხის ლიმიტი
BEGIN
	SELECT @next_date = MIN(SCHEDULE_DATE)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @calc_date

	IF @next_date IS NOT NULL
	BEGIN
		SELECT 
			@next_limit = BALANCE
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE = @next_date

		SET @next_principal = @principal - @next_limit
		SET @next_interest = @interest 
		SET @next_nu_interest = @nu_interest
	END
	ELSE
	BEGIN
		SET @next_principal = $0.00 -- თუ არ არის გრაფიკში შემდეგი ბიჯი ანუ მთელი თანხა არის ვადაგადაცილებაში
		SET @next_interest = $0.00
		SET @next_nu_interest = $0.00
	END
END
ELSE
BEGIN
	SELECT @next_date = MIN(SCHEDULE_DATE)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @calc_date AND AMOUNT > $0.00

	IF @next_date IS NOT NULL
		SELECT 
			@next_principal = PRINCIPAL,
			@next_interest = INTEREST,
			@next_nu_interest = NU_INTEREST
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE = @next_date
	ELSE
	BEGIN
		SET @next_principal = $0.00 -- თუ არ არის გრაფიკში შემდეგი ბიჯი ანუ მთელი თანხა არის ვადაგადაცილებაში
		SET @next_interest = $0.00
		SET @next_nu_interest = $0.00
	END

	SET @min_debt = $0.00
	SET @no_charge_debt = $0.00
	SET @max_debt = @late_principal + @late_percent + 
					@overdue_principal + @overdue_principal_interest + @overdue_principal_penalty + 
					@overdue_percent + @overdue_percent_penalty + @interest + @nu_interest

	IF @prepaym_intrate IS NOT NULL
		SET @prepayment_intrate = @prepaym_intrate

	SET @prepayment_penalty = $0.00
	SET @prepayment = $0.00
	SET @no_charge_prepayment = $0.00


	SELECT @sched_payment_count = COUNT(*)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @prev_step AND ORIGINAL_PRINCIPAL > $0.00


	SELECT @max_debt = @max_debt + SUM(ISNULL(PRINCIPAL, $0.00))
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND (@next_date IS NOT NULL) AND SCHEDULE_DATE >= @next_date

	SELECT TOP (@prepayment_step) @no_charge_prepayment = @no_charge_prepayment + ISNULL(PRINCIPAL, $0.00)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @prev_step AND SCHEDULE_DATE > @calc_date AND ORIGINAL_PRINCIPAL > $0.00


	SELECT @prepayment = @prepayment + ISNULL(PRINCIPAL, $0.00)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @prev_step AND SCHEDULE_DATE > @calc_date

	SET @prepayment_penalty = ROUND((@prepayment - @no_charge_prepayment) * @prepayment_intrate / $100.00, 2, 1) 

	SET @max_debt = @max_debt + @prepayment_penalty

	SET @min_debt = @late_principal + @late_percent + 
					@overdue_principal + @overdue_principal_interest + @overdue_principal_penalty + 
					@overdue_percent + @overdue_percent_penalty
	SET @no_charge_debt = @min_debt + @interest + @nu_interest + @no_charge_prepayment

	IF (@next_date IS NOT NULL) AND (@calc_date = @next_date) -- ესე იგი დღეს უწევს გრაფიკით და თან დღევანდელი გრაფიკის ძირი გათვალისწინებული არაა ჯამებში ამიტომ ვამატებთ ხელით
		SET @min_debt = @min_debt + @next_principal + @interest + @nu_interest
	IF (@next_date IS NOT NULL) AND (@calc_date = @next_date)
		SET @no_charge_debt = @no_charge_debt + @next_principal

	IF @prepayment_intrate = $0.00
		SET @no_charge_debt = @max_debt


	IF @amount IS NOT NULL
	BEGIN
		IF @amount > @max_debt
			SET @info_msg = 'ÈÀÍáÀ ÌÄÔÉÀ ÃÀÅÀËÉÀÍÄÁÀÆÄ!'
		ELSE
		BEGIN
			SET @prepayment = @amount - (@late_principal + @late_percent + 
					@overdue_principal + @overdue_principal_interest + @overdue_principal_penalty + 
					@overdue_percent + @overdue_percent_penalty + @interest + @nu_interest)
			IF (@next_date IS NOT NULL) AND (@calc_date = @next_date)
				SET @prepayment = @prepayment - @next_principal
			IF @prepayment < $0.00
			BEGIN
				SET @prepayment = $0.00
				SET @prepayment_penalty = $0.00
			END
			ELSE
			IF (@prepayment <= @no_charge_prepayment)
				SET @prepayment_penalty = $0.00
			ELSE
			BEGIN
				SET @prepayment = ROUND((100 * @prepayment + @no_charge_prepayment * @prepayment_intrate) / (100 + @prepayment_intrate), 2, 1) 
				SET @prepayment_penalty = ROUND((@prepayment - @no_charge_prepayment) * @prepayment_intrate / $100.00, 2, 1)
			END
		END
	END
	IF @principal_payment IS NOT NULL
	BEGIN
		SET @prepayment = @principal_payment 
		IF (@next_date IS NOT NULL) AND (@calc_date = @next_date)
			SET @prepayment = @prepayment - @next_principal
		IF @prepayment < $0.00
		BEGIN
			SET @prepayment = $0.00
			SET @prepayment_penalty = $0.00
		END
		ELSE
		IF (@prepayment <= @no_charge_prepayment)
			SET @prepayment_penalty = $0.00
		ELSE
			SET @prepayment_penalty = ROUND((@prepayment - @no_charge_prepayment) * @prepayment_intrate / $100.00, 2, 1)
	END
END

INSERT INTO #tbl (
	LOAN_ID,
	MIN_DEBT,
	MAX_DEBT,
	NO_CHARGE_DEBT,
	PREV_STEP,
	CALC_DATE,
	NU_PRINCIPAL,
	NU_INTEREST,
	PRINCIPAL,
	INTEREST,
	LATE_DATE,
	LATE_PRINCIPAL,
	LATE_PERCENT,
	OVERDUE_DATE,
	OVERDUE_PRINCIPAL,
	OVERDUE_PRINCIPAL_INTEREST,
	OVERDUE_PRINCIPAL_PENALTY,
	OVERDUE_PERCENT,
	OVERDUE_PERCENT_PENALTY,
	WRITEOFF_PRINCIPAL,
	WRITEOFF_PRINCIPAL_PENALTY,
	WRITEOFF_PERCENT,
	WRITEOFF_PERCENT_PENALTY,
	WRITEOFF_PENALTY,
	CALLOFF_PRINCIPAL,
	CALLOFF_PRINCIPAL_INTEREST,
	CALLOFF_PRINCIPAL_PENALTY,
	CALLOFF_PERCENT,
	CALLOFF_PERCENT_PENALTY,
	CALLOFF_PENALTY,
	DEFERED_AMOUNT,
	NEXT_DATE,
	NEXT_PRINCIPAL,
	NEXT_INTEREST,
	NEXT_NU_INTEREST,
	PREPAYMENT,
	PREPAYMENT_PENALTY,
	INFO_MSG
)
VALUES (
	@loan_id,
	ISNULL(@min_debt, $0.00),
	ISNULL(@max_debt, $0.00),
	ISNULL(@no_charge_debt, $0.00),
	@prev_step,
	@calc_date,
	ISNULL(@nu_principal, $0.00),
	ISNULL(@nu_interest, $0.00),
	ISNULL(@principal, $0.00),
	ISNULL(@interest, $0.00),
	@late_date,
	ISNULL(@late_principal, $0.00),
	ISNULL(@late_percent, $0.00),
	@overdue_date,
	ISNULL(@overdue_principal, $0.00),
	ISNULL(@overdue_principal_interest, $0.00),
	ISNULL(@overdue_principal_penalty, $0.00),
	ISNULL(@overdue_percent, $0.00),
	ISNULL(@overdue_percent_penalty, $0.00),
	ISNULL(@writeoff_principal, $0.00),
	ISNULL(@writeoff_principal_penalty, $0.00),
	ISNULL(@writeoff_percent, $0.00),
	ISNULL(@writeoff_percent_penalty, $0.00),
	ISNULL(@writeoff_penalty, $0.00),
	ISNULL(@calloff_principal, $0.00),
	ISNULL(@calloff_principal_interest, $0.00),
	ISNULL(@calloff_principal_penalty, $0.00),
	ISNULL(@calloff_percent, $0.00),
	ISNULL(@calloff_percent_penalty, $0.00),
	ISNULL(@calloff_penalty, $0.00),
	ISNULL(@defered_amount, $0.00),
	@next_date,
	ISNULL(@next_principal, $0.00),
	ISNULL(@next_interest, $0.00),
	ISNULL(@next_nu_interest, $0.00),
	ISNULL(@prepayment, $0.00),
	ISNULL(@prepayment_penalty, $0.00),
	@info_msg
)

SELECT * FROM #tbl
DROP TABLE #tbl


GO
