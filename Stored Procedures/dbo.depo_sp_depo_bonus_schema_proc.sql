SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_depo_bonus_schema_proc]
	@depo_id int,
	@user_id int,
	@dept_no int,
	@analyze_date smalldatetime,
	@accrue_amount money OUTPUT,
	@remark varchar(255) OUTPUT
AS
SET NOCOUNT ON;

DECLARE
	@r int
	
DECLARE
	@start_date smalldatetime,
	@days_in_year int,
	@accumulative bit,
	@accumulate_min money,
	@accumulate_max money,
	@depo_acc_id int
	
DECLARE
	@tax_rate money,
	@formula varchar(512)
	
SELECT @start_date = [START_DATE], @days_in_year = DAYS_IN_YEAR, @accumulative = ACCUMULATIVE, @accumulate_min = ACCUMULATE_MIN, @accumulate_max = ACCUMULATE_MAX, @depo_acc_id = DEPO_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

SELECT @tax_rate = TAX_RATE
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @depo_acc_id

SET @accrue_amount = $0.00

IF @accumulative <> 1
	RETURN 0

DECLARE
	@years int

SET @years = DATEDIFF(YEAR, @start_date, @analyze_date)

IF DATEADD(YEAR, @years, @start_date) <> @analyze_date
	RETURN 0
	
SET @start_date = DATEADD(YEAR, -1, @analyze_date)


SET @start_date = DATEADD(DAY, -(DAY(@start_date) - 1), @start_date)
SET @start_date = DATEADD(MONTH, 1, @start_date)
	
DECLARE @DOCS TABLE (DATE smalldatetime NOT NULL PRIMARY KEY)
DECLARE @DATES TABLE (DATE smalldatetime NOT NULL PRIMARY KEY)
	
INSERT INTO @DOCS(DATE)
SELECT DATEADD(DAY, -(DAY(O.DOC_DATE) - 1), O.DOC_DATE)
FROM dbo.OPS_FULL O (NOLOCK)
	INNER JOIN dbo.OPS_HELPER H (NOLOCK) ON O.REC_ID = H.REC_ID
WHERE H.ACC_ID = @depo_acc_id AND H.DT BETWEEN @start_date AND @analyze_date AND O.CREDIT_ID = H.ACC_ID AND (@accumulate_min IS NULL OR O.AMOUNT >= @accumulate_min) AND (@accumulate_max IS NULL OR O.AMOUNT <= @accumulate_max)
GROUP BY DATEADD(DAY, -(DAY(O.DOC_DATE) - 1), O.DOC_DATE)

WHILE @start_date <= @analyze_date
BEGIN
	INSERT @DATES(DATE) VALUES (@start_date)
	SET @start_date = DATEADD(MONTH, 1, @start_date)
END

DELETE D
FROM @DATES D
	INNER JOIN @DOCS docs ON D.DATE = docs.DATE
	
IF (SELECT COUNT(*) FROM @DATES) > 0
	RETURN 0
	
SET @formula = 'CASE WHEN AMOUNT<-0 THEN AMOUNT*-0.5 ELSE 0 END'

EXEC dbo.calc_accrual_amount
  @acc_id = @depo_acc_id,
  @start_date = @start_date,
  @end_date	= @analyze_date,
  @formula = @formula,
  @is_debit	= 0,
  @amount = @accrue_amount OUTPUT,
  @month_eq_30 = 0,
  @is_real = 0,
  @days_in_year = @days_in_year,
  @tax_rate = @tax_rate,
  @recalc_option  = 0x04 -- 0x04 - Recalc from beginning	

RETURN 0
GO
