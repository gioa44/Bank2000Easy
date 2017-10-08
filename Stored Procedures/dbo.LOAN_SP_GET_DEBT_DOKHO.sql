SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_DEBT_DOKHO]
  @loan_id int,
  @amount money = null,
  @payment_type tinyint = 0,
  @prepaym_intrate money = NULL
AS
CREATE TABLE #tbl (
	LOAN_ID int NOT NULL,
	MIN_DEBT money,
	MAX_DEBT money,
	LATE_DATE smalldatetime NULL,
	PREV_STEP smalldatetime NULL,
	CALC_DATE smalldatetime NULL,
	PRINCIPAL money,
	INTEREST money,
	LATE_PRINCIPAL money,
	LATE_PERCENT money,
	OVERDUE_DATE smalldatetime NULL,
	OVERDUE_PRINCIPAL money,
	OVERDUE_PRINCIPAL_INTEREST money,
	OVERDUE_PRINCIPAL_PENALTY money,
	OVERDUE_PERCENT money,
	OVERDUE_PERCENT_PENALTY money,
	WRITEOFF_PRINCIPAL money,
	WRITEOFF_PRINCIPAL_PENALTY money,
	WRITEOFF_PERCENT money,
	WRITEOFF_PERCENT_PENALTY money,
	WRITEOFF_PENALTY money,
	CALLOFF_PRINCIPAL money,
	CALLOFF_PRINCIPAL_INTEREST money,
	CALLOFF_PRINCIPAL_PENALTY money,
	CALLOFF_PERCENT money,
	CALLOFF_PERCENT_PENALTY money,
	CALLOFF_PENALTY money,
	DEFERED_AMOUNT money,
	NEXT_DATE smalldatetime NULL,
	NEXT_PRINCIPAL money,
	NEXT_INTEREST money,
	NU_INTEREST money,
	PREPAYMENT money,
	PREPAYMENT_PENALTY money,
	LATE_DEBT money,
	OVERDUE_DEBT money,
	INFO_MSG varchar(1000) NULL
)

DECLARE
	@info_msg varchar(1000),
	@prev_step smalldatetime,
	@calc_date smalldatetime,

	@max_debt money,
	@min_debt money,

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
	@nu_interest money,
	@late_debt money,
	@overdue_debt money

DECLARE
	@schedule_type tinyint, -- --> LOAN_SCHEDULE_TYPES
	@prepayment_intrate money,
	@prepayment money,
	@prepayment_penalty money,
	@prepayment_step tinyint,
	@prepayment_schedule_date smalldatetime,
	@sched_payment_count tinyint

SELECT
	@prev_step = PREV_STEP,
	@calc_date = CALC_DATE,
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

SET @late_debt = @late_principal + @late_percent
SET @overdue_debt = @overdue_principal + @overdue_principal_interest + @overdue_principal_penalty + @overdue_percent + @overdue_percent_penalty

SELECT @next_date = MIN(SCHEDULE_DATE)
FROM dbo.LOAN_SCHEDULE (NOLOCK)
WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @prev_step AND AMOUNT > $0.00

IF @next_date IS NOT NULL
	SELECT 
		@next_principal = PRINCIPAL,
		@next_interest = INTEREST
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE = @next_date
ELSE
BEGIN
	SET @next_principal = $0.00 -- თუ არ არის გრაფიკში შემდეგი ბიჯი ანუ მთელი თანხა არის ვადაგადაცილებაში
	SET @next_interest = $0.00
END

SET @min_debt = $0.00
SET @max_debt = @late_principal + @late_percent + 
				@overdue_principal + @overdue_principal_interest + @overdue_principal_penalty + 
				@overdue_percent + @overdue_percent_penalty + @nu_interest


SELECT 
	@schedule_type = SCHEDULE_TYPE, 
	@prepayment_intrate = PREPAYMENT_INTRATE, 
	@prepayment_step = PREPAYMENT_STEP 
FROM dbo.LOANS  (NOLOCK)
WHERE LOAN_ID = @loan_id


IF @prepaym_intrate IS NOT NULL
	SET @prepayment_intrate = @prepaym_intrate

SET @prepayment_penalty = $0.00
SET @prepayment = $0.00


--Processing

IF @payment_type = 0	-- თანხის შემოტანა
BEGIN
	SELECT @max_debt = @max_debt + SUM(ISNULL(PRINCIPAL, $0.00))
	FROM dbo.LOAN_SCHEDULE (NOLOCK)
	WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @prev_step

	SET @max_debt = @max_debt + @interest
END
ELSE
IF @payment_type = 1	-- წინსწრებით დაფარვა
BEGIN
	SELECT @sched_payment_count = COUNT(*) FROM dbo.LOAN_SCHEDULE (NOLOCK) WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @prev_step

	IF @schedule_type IN (2, 16, 32) -- პროცენტი, ინდივიდუალური გრაფიკი, სესხის ლიმიტი
	BEGIN
		SET @info_msg = 'ÂÒÀ×ÉÊÉÓ ÔÉÐÉÃÀÍ ÂÀÌÏÌÃÉÍÀÒÄ ÓÄÓáÉÓ ßÉÍÓßÒÄÁÉÈ ÃÀ×ÀÒÅÀ ÛÄÖÞËÄÁÄËÉÀ!'

		SELECT @max_debt = @max_debt + SUM(ISNULL(PRINCIPAL, $0.00) + ISNULL(INTEREST, $0.00) + ISNULL(NU_INTEREST, $0.00))
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @prev_step
	END
	ELSE
	IF @sched_payment_count < @prepayment_step + 1
	BEGIN
		SET @info_msg = 'ßÉÍÓßÒÄÁÉÈ ÃÀ×ÀÒÅÀ ÛÄÖÞËÄÁÄËÉÀ!'

		SELECT @max_debt = @max_debt + SUM(ISNULL(PRINCIPAL, $0.00) + ISNULL(INTEREST, $0.00) + ISNULL(NU_INTEREST, $0.00))
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @prev_step
	END
	ELSE
	BEGIN
		SET @min_debt = @max_debt
		
		SELECT @max_debt = @max_debt + SUM(ISNULL(PRINCIPAL, $0.00))
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @next_date

		SELECT @prepayment = @prepayment + ISNULL(PRINCIPAL, $0.00)
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @next_date

		SET @prepayment_penalty = ROUND(@prepayment * @prepayment_intrate / $100.00, 2, 1) 
		SET @max_debt = @max_debt + @next_principal + @interest + @prepayment_penalty

		SET @prepayment = $0.00

		SELECT TOP (@prepayment_step) SCHEDULE_DATE
		INTO #T
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = LOAN_ID AND SCHEDULE_DATE > @prev_step
		ORDER BY SCHEDULE_DATE

		SELECT @prepayment_schedule_date = MAX(SCHEDULE_DATE)
		FROM #T
		DROP TABLE #T

		SET @prepayment_schedule_date = ISNULL(@prepayment_schedule_date, @prev_step)

		SELECT @prepayment = @principal - ISNULL(BALANCE, $0.00)
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE = @prepayment_schedule_date


		SELECT TOP (@prepayment_step) @prepayment = @prepayment + ISNULL(PRINCIPAL, $0.00)
		FROM dbo.LOAN_SCHEDULE (NOLOCK)
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @next_date

		SET @prepayment_penalty = ROUND(@prepayment * @prepayment_intrate / $100.00, 2, 1)
		SET @min_debt = @min_debt + @next_principal + @interest + @prepayment + @prepayment_penalty

		
		IF @amount IS NOT NULL
		BEGIN
			IF @amount < @min_debt
				SET @info_msg = 'ÈÀÍáÀ ÍÀÊËÄÁÉÀ ßÉÍÓßÒÄÁÉÈ ÃÀ×ÀÒÅÉÓÈÅÉÓ ÃÀÓÀÛÅÄÁ ÌÉÍÉÌÖÌÆÄ!'
			ELSE
			IF @amount > @max_debt
				SET @info_msg = 'ÈÀÍáÀ ÌÄÔÉÀ ÃÀÅÀËÉÀÍÄÁÀÆÄ!'
			ELSE
			BEGIN
				SET @prepayment = @prepayment + @amount - (@min_debt - @prepayment_penalty)
				SET @prepayment = ROUND(100 * @prepayment / (100 + @prepayment_intrate), 2, 1) 
				SET @prepayment_penalty = ROUND(@prepayment * @prepayment_intrate / $100.00, 2, 1)
			END
		END
	END	
END 
IF @payment_type = 2	-- სესხის წინსწრებით დახურვა
BEGIN
	SET @prepayment = ISNULL((SELECT SUM(PRINCIPAL) FROM dbo.LOAN_SCHEDULE (NOLOCK) WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @next_date), $0.00)
	SET @prepayment_penalty = ROUND(@prepayment * @prepayment_intrate / $100.00, 2, 1)

	SET @max_debt = @max_debt + @next_principal + @interest + @prepayment + @prepayment_penalty
	SET @min_debt = @max_debt
END

INSERT INTO #tbl (
	LOAN_ID,
	MIN_DEBT,
	MAX_DEBT,
	PREV_STEP,
	CALC_DATE,
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
	NU_INTEREST,
	PREPAYMENT,
	PREPAYMENT_PENALTY,
	LATE_DEBT,
	OVERDUE_DEBT,
	INFO_MSG
)
VALUES (
	@loan_id,
	ISNULL(@min_debt, $0.00),
	ISNULL(@max_debt, $0.00),
	@prev_step,
	@calc_date,
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
	ISNULL(@next_date, $0.00),
	ISNULL(@next_principal, $0.00),
	ISNULL(@next_interest, $0.00),
	ISNULL(@nu_interest, $0.00),
	ISNULL(@prepayment, $0.00),
	ISNULL(@prepayment_penalty, $0.00),
	ISNULL(@late_debt, $0.00),
	ISNULL(@overdue_debt, $0.00),
	@info_msg
)

SELECT * FROM #tbl


GO
