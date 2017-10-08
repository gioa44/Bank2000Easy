SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GET_DEBT_HISTORY]
	@loan_id int,
	@dt smalldatetime
AS
SET NOCOUNT ON

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
	RATE_DIFF money NULL,
	INSURANCE money NULL,
	SERVICE_FEE money NULL,
	DEFERABLE_INTEREST money NULL,
	DEFERABLE_OVERDUE_INTEREST money NULL,
	DEFERABLE_PENALTY money NULL,
	DEFERABLE_FINE money NULL,
	DEFERED_INTEREST money NULL,
	DEFERED_OVERDUE_INTEREST money NULL,
	DEFERED_PENALTY money NULL,
	DEFERED_FINE money NULL,
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
	@defered_interest money,
	@defered_overdue_interest money,
	@defered_penalty money,
	@defered_fine money,
	@immediate_penalty money,
	@next_date smalldatetime,
	@next_principal money,
	@next_interest money,
	@next_nu_interest money,
	@next_limit money

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
	@op_id int

SELECT @op_id = MAX(O.OP_ID)
FROM dbo.LOANS_HISTORY L (NOLOCK)
	INNER JOIN dbo.LOAN_OPS O (NOLOCK) ON L.OP_ID = O.OP_ID
WHERE O.OP_DATE <= @dt


SELECT 
	@writeoff_date = WRITEOFF_DATE 
FROM dbo.LOANS_HISTORY  (NOLOCK)
WHERE LOAN_ID = @loan_id AND OP_ID = @op_id

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
	@deferable_fine = ROUND(ISNULL(DEFERABLE_FINE, $0.00), 2, 1)
FROM dbo.LOAN_DETAILS_HISTORY (NOLOCK)
WHERE LOAN_ID = @loan_id AND CALC_DATE = @dt

DECLARE
	@schedule_type int
SELECT 
	@schedule_type = SCHEDULE_TYPE
FROM dbo.LOANS  (NOLOCK)
WHERE LOAN_ID = @loan_id


IF @schedule_type <> 32
BEGIN
	SELECT TOP 1
		@insurance = @insurance + ISNULL(INSURANCE, $0.00),
		@service_fee = @service_fee + CASE WHEN SCHEDULE_DATE = @calc_date THEN ISNULL(SERVICE_FEE, $0.00) ELSE $0.00 END,
		@defered_interest = ISNULL(DEFERED_INTEREST, $0.00),
		@defered_overdue_interest = ISNULL(DEFERED_OVERDUE_INTEREST, $0.00),
		@defered_penalty = ISNULL(DEFERED_PENALTY, $0.00),
		@defered_fine = ISNULL(DEFERED_FINE, $0.00)
	FROM dbo.LOAN_FN_FIND_LOAN_SCHEDULE(@loan_id, @dt) 
	WHERE SCHEDULE_DATE >= @calc_date 
	ORDER BY SCHEDULE_DATE ASC
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
	$0.00,
	$0.00,
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
	@info_msg
)

SELECT * FROM #tbl
DROP TABLE #tbl

GO
