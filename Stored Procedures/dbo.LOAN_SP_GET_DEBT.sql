SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[LOAN_SP_GET_DEBT]
  @loan_id int,
  @amount money = null,
  @prepaym_intrate money = null
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
	WRITEOFF_DATE smalldatetime NULL,
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
	FINE money NULL,
	IMMEDIATE_PENALTY money NULL,
	NEXT_DATE smalldatetime NULL,
	NEXT_PRINCIPAL money NULL,
	NEXT_INTEREST money NULL,
	NEXT_NU_INTEREST money NULL,
	PREPAYMENT money NULL,
	PREPAYMENT_PENALTY money NULL,
	RATE_DIFF money,
	INSURANCE money,
	SERVICE_FEE money,
	DEFERABLE_INTEREST money NULL,
	DEFERABLE_OVERDUE_INTEREST money NULL,
	DEFERABLE_PENALTY money NULL,
	DEFERABLE_FINE money NULL,
	DEFERED_INTEREST money NULL,
	DEFERED_OVERDUE_INTEREST money NULL,
	DEFERED_PENALTY money NULL,
	DEFERED_FINE money NULL,
	REMAINING_FEE money NULL,
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
	@writeoff_date smalldatetime,
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
	@fine money,

	@deferable_interest money,
	@deferable_overdue_interest money,
	@deferable_penalty money,
	@deferable_fine money,
	
	@immediate_penalty money,
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
	@sched_payment_count int

DECLARE
	@ccy TISO,
	@linked_ccy TISO,
	@indexed_rate money,
	@rate_change_ratio money,	
	@rate_diff money

DECLARE
	@insurance money,
	@service_fee money	

DECLARE
	@defered_interest money,
	@defered_overdue_interest money,
	@defered_penalty money,
	@defered_fine money,

	@defered_interest_next money,
	@defered_overdue_interest_next money,
	@defered_penalty_next money,
	@defered_fine_next money,

	@remaining_fee money,
	
	@next_principal_prepay_penalty money,
	@grace_finish_date smalldatetime

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
	@fine = ROUND(ISNULL(FINE, $0.00), 2, 1),
	@immediate_penalty = ROUND(ISNULL(IMMEDIATE_PENALTY, $0.00), 2, 1),
	@insurance = ROUND(ISNULL(OVERDUE_INSURANCE, $0.00), 2, 1),
	@service_fee = ROUND(ISNULL(OVERDUE_SERVICE_FEE, $0.00), 2, 1),
	@deferable_interest = ROUND(ISNULL(DEFERABLE_INTEREST, $0.00), 2, 1),
	@deferable_overdue_interest = ROUND(ISNULL(DEFERABLE_OVERDUE_INTEREST, $0.00), 2, 1),
	@deferable_penalty = ROUND(ISNULL(DEFERABLE_PENALTY, $0.00), 2, 1),
	@deferable_fine = ROUND(ISNULL(DEFERABLE_FINE, $0.00), 2, 1),
	@remaining_fee = ROUND(ISNULL(REMAINING_FEE, $0.00), 2, 1)
FROM dbo.LOAN_DETAILS (NOLOCK)
WHERE LOAN_ID = @loan_id

SELECT 
	@schedule_type = SCHEDULE_TYPE, 
	@prepayment_intrate = PREPAYMENT_INTRATE, 
	@prepayment_step = PREPAYMENT_STEP,
	@writeoff_date = WRITEOFF_DATE,
	@ccy = ISO,
	@linked_ccy = LINKED_CCY,
	@indexed_rate = INDEXED_RATE,
	@grace_finish_date = GRACE_FINISH_DATE
FROM dbo.LOANS  (NOLOCK)
WHERE LOAN_ID = @loan_id

IF @schedule_type = 32 --თუ არის სესხის ლიმიტი
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
		IF @next_principal < $0.00 
			SET @next_principal = $0.00
		SET @next_interest = @interest 
		SET @next_nu_interest = @nu_interest
	END
	ELSE
	BEGIN
		SET @next_principal = $0.00 -- თუ არ არის გრაფიკში შემდეგი ბიჯი ანუ მთელი თანხა არის ვადაგადაცილებაში
		SET @next_interest = $0.00
		SET @next_nu_interest = $0.00
	END

	IF (@linked_ccy IS NOT NULL)
	BEGIN
		SET @rate_change_ratio = dbo.get_cross_rate(@linked_ccy, @ccy, @calc_date) / @indexed_rate - 1

		IF (@rate_change_ratio <= 0)
			SET @rate_change_ratio = 0
		ELSE
		BEGIN
			IF (@amount IS NOT NULL)
			BEGIN	
				SET @rate_diff = ROUND(@amount - @amount / (1 + @rate_change_ratio), 2, 1)
				SET @amount = @amount - @rate_diff
			END
		END
	END
END
ELSE
BEGIN
	SET @defered_interest = $0.00
	SET @defered_overdue_interest = $0.00
	SET @defered_penalty = $0.00
	SET @defered_fine = $0.00

	SELECT @next_date = MIN(SCHEDULE_DATE)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @calc_date AND AMOUNT > $0.00 AND ORIGINAL_AMOUNT IS NOT NULL

	SELECT TOP 1 
		@defered_interest = ISNULL(DEFERED_INTEREST, $0.00),
		@defered_overdue_interest = ISNULL(DEFERED_OVERDUE_INTEREST, $0.00),
		@defered_penalty = ISNULL(DEFERED_PENALTY, $0.00),
		@defered_fine = ISNULL(DEFERED_FINE, $0.00)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @calc_date AND ORIGINAL_AMOUNT IS NOT NULL AND (@schedule_type <> 64 OR @calc_date > @grace_finish_date)
	ORDER BY SCHEDULE_DATE ASC

	SELECT TOP 1 
		@insurance = @insurance + ISNULL(INSURANCE, $0.00)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @calc_date AND ORIGINAL_AMOUNT IS NOT NULL
	ORDER BY SCHEDULE_DATE ASC

	IF @next_date IS NOT NULL
		SELECT 
			@next_principal = ISNULL(PRINCIPAL, $0.00),
			@next_interest = ISNULL(INTEREST, $0.00),
			@next_nu_interest = ISNULL(NU_INTEREST, $0.00),
			@service_fee = @service_fee + CASE WHEN SCHEDULE_DATE = @calc_date THEN ISNULL(SERVICE_FEE, $0.00) ELSE $0.00 END
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE = @next_date
	ELSE
	BEGIN
		SET @next_principal = $0.00 -- თუ არ არის გრაფიკში შემდეგი ბიჯი ანუ მთელი თანხა არის ვადაგადაცილებაში
		SET @next_interest = $0.00
		SET @next_nu_interest = $0.00
		SET @insurance = $0.00
		SET @service_fee = $0.00
		SET @defered_interest = $0.00
		SET @defered_overdue_interest = $0.00
		SET @defered_penalty = $0.00
		SET @defered_fine = $0.00
	END

	SET @defered_interest_next = @deferable_interest - @defered_interest
	SET @defered_overdue_interest_next = @deferable_overdue_interest - @defered_overdue_interest
	SET @defered_penalty_next = @deferable_penalty - @defered_penalty
	SET @defered_fine_next = @deferable_fine - @defered_fine
	SET @next_principal_prepay_penalty = $0.00

	SET @min_debt = $0.00
	SET @no_charge_debt = $0.00
	SET @max_debt = @late_principal + @late_percent + @overdue_principal + @overdue_principal_interest + 
					@overdue_principal_penalty + @overdue_percent + @overdue_percent_penalty + @interest + @nu_interest + @insurance + 
					@service_fee + @deferable_interest + @deferable_overdue_interest + @deferable_penalty + @deferable_fine


	IF @prepaym_intrate IS NOT NULL
		SET @prepayment_intrate = @prepaym_intrate

	SET @prepayment_penalty = $0.00
	SET @prepayment = $0.00
	SET @no_charge_prepayment = $0.00


	SELECT @sched_payment_count = COUNT(*)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @prev_step AND ISNULL(ORIGINAL_PRINCIPAL, $0.00) > $0.00


	SELECT @max_debt = @max_debt + ISNULL(SUM(ISNULL(PRINCIPAL, $0.00)), $0.00)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND (@next_date IS NOT NULL) AND SCHEDULE_DATE >= @next_date

	SELECT TOP (@prepayment_step) @no_charge_prepayment = @no_charge_prepayment + ISNULL(PRINCIPAL, $0.00)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @prev_step AND SCHEDULE_DATE > @calc_date AND ISNULL(ORIGINAL_PRINCIPAL, $0.00) > $0.00


	SELECT @prepayment = @prepayment + ISNULL(PRINCIPAL, $0.00)
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @prev_step AND SCHEDULE_DATE > @calc_date

	SET @prepayment_penalty = ROUND((@prepayment - @no_charge_prepayment) * @prepayment_intrate / $100.00, 2, 1) 

	SET @max_debt = @max_debt + @prepayment_penalty

	SET @min_debt = @late_principal + @late_percent + @overdue_principal + @overdue_principal_penalty + @overdue_percent + @overdue_percent_penalty

	SET @no_charge_debt = @min_debt + @interest + @nu_interest + @overdue_principal_interest + @no_charge_prepayment + @insurance + @service_fee
							+ @defered_interest + @defered_overdue_interest + @defered_penalty + @defered_fine

	IF (@next_date IS NOT NULL) AND (@calc_date = @next_date) -- ესე იგი დღეს უწევს გრაფიკით და თან დღევანდელი გრაფიკის ძირი გათვალისწინებული არაა ჯამებში ამიტომ ვამატებთ ხელით
	BEGIN
		SET @min_debt = @min_debt + @next_principal + @interest + @nu_interest + @overdue_principal_interest + @insurance + @service_fee + @defered_interest + @defered_overdue_interest + @defered_penalty + @defered_fine
		SET @no_charge_debt = @no_charge_debt + @next_principal + @defered_interest_next + @defered_overdue_interest_next + @defered_penalty_next + @defered_fine_next
	END

	IF @prepayment_intrate = $0.00
		SET @no_charge_debt = @max_debt

	IF (@linked_ccy IS NOT NULL)
	BEGIN
		SET @rate_change_ratio = dbo.get_cross_rate(@linked_ccy, @ccy, @calc_date) / @indexed_rate - 1

		IF (@rate_change_ratio <= 0)
			SET @rate_change_ratio = 0
		ELSE
		BEGIN
			IF (@amount IS NOT NULL)
			BEGIN	
				SET @rate_diff = ROUND(@amount - @amount / (1 + @rate_change_ratio), 2, 1)
				SET @amount = @amount - @rate_diff
			END
			ELSE
				SET @rate_diff = ROUND(@max_debt * @rate_change_ratio, 2, 1)

			SET @min_debt = @min_debt + ROUND(@min_debt * @rate_change_ratio, 2, 1)	
			SET @max_debt = @max_debt + ROUND(@max_debt * @rate_change_ratio, 2, 1)
			SET @no_charge_debt = @no_charge_debt + ROUND(@no_charge_debt * @rate_change_ratio, 2, 1)
		END
	END


	IF @amount IS NOT NULL
	BEGIN		
		IF @amount > @max_debt
			SET @info_msg = 'ÈÀÍáÀ ÌÄÔÉÀ ÃÀÅÀËÉÀÍÄÁÀÆÄ!' /*თანხა მეტია დავალიანებაზე*/
		ELSE
		BEGIN
			SET @prepayment = @amount - (@late_principal + @late_percent + 
					@overdue_principal + @overdue_principal_interest + @overdue_principal_penalty + 
					@overdue_percent + @overdue_percent_penalty + @interest + @nu_interest + @insurance + @service_fee + 
					@defered_interest + @defered_overdue_interest + @defered_penalty + @defered_fine)

			IF @defered_interest_next + @defered_overdue_interest_next + @defered_penalty_next + @defered_fine_next > $0.00
			BEGIN
				IF @calc_date <> @next_date
					SET @next_principal_prepay_penalty = ROUND((@next_principal) * @prepayment_intrate / 100, 2, 1)

				IF @prepayment > @next_principal + @next_principal_prepay_penalty + @defered_interest_next + @defered_overdue_interest_next + @defered_penalty_next + @defered_fine_next
					SET @prepayment	= @prepayment - (@defered_interest_next + @defered_overdue_interest_next + @defered_penalty_next + @defered_fine_next)
				ELSE 
				IF @prepayment > @next_principal + @next_principal_prepay_penalty
					SET @prepayment = @next_principal + @next_principal_prepay_penalty
			END

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
				SET @prepayment_penalty = ROUND((@prepayment - @no_charge_prepayment) * @prepayment_intrate / 100, 2, 1)
			END
		END
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
	WRITEOFF_DATE,
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
	FINE,
	IMMEDIATE_PENALTY,
	NEXT_DATE,
	NEXT_PRINCIPAL,
	NEXT_INTEREST,
	NEXT_NU_INTEREST,
	PREPAYMENT,
	PREPAYMENT_PENALTY,
	RATE_DIFF,
	INSURANCE,
	SERVICE_FEE,
	DEFERABLE_INTEREST,
	DEFERABLE_OVERDUE_INTEREST,
	DEFERABLE_PENALTY,
	DEFERABLE_FINE,
	DEFERED_INTEREST,
	DEFERED_OVERDUE_INTEREST,
	DEFERED_PENALTY,
	DEFERED_FINE,
	REMAINING_FEE,
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
	@writeoff_date,
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
	ISNULL(@fine, $0.00),
 	ISNULL(@immediate_penalty, $0.00),
	@next_date,
	ISNULL(@next_principal, $0.00),
	ISNULL(@next_interest, $0.00),
	ISNULL(@next_nu_interest, $0.00),
	ISNULL(@prepayment, $0.00),
	ISNULL(@prepayment_penalty, $0.00),
	ISNULL(@rate_diff, $0.00),
	ISNULL(@insurance, $0.00),
	ISNULL(@service_fee, $0.00),
	ISNULL(@deferable_interest, $0.00),
	ISNULL(@deferable_overdue_interest, $0.00),
	ISNULL(@deferable_penalty, $0.00),
	ISNULL(@deferable_fine, $0.00),
	ISNULL(@defered_interest, $0.00),
	ISNULL(@defered_overdue_interest, $0.00),
	ISNULL(@defered_penalty, $0.00),
	ISNULL(@defered_fine, $0.00),
	ISNULL(@remaining_fee, $0.00),	
	@info_msg
)

SELECT * FROM #tbl
DROP TABLE #tbl



GO
