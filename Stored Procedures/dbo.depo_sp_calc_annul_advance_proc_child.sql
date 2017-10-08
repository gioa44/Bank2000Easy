SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_calc_annul_advance_proc_child]
	@depo_id int,
	@user_id int,
	@dept_no int,
	@annul_date smalldatetime,
	@start_point tinyint OUTPUT,
	@annul_intrate money OUTPUT,
	@annul_amount money OUTPUT
AS
SET NOCOUNT ON;

DECLARE
	@r int

SET @annul_amount = NULL

DECLARE
	@last_move_date smalldatetime,
	@total_payed_amount money
	
DECLARE
	@start_date smalldatetime,
	@formula varchar(512),
	@days_in_year int,
	@acc_id int


SELECT @start_date = [START_DATE], @acc_id = DEPO_ACC_ID, @days_in_year = DAYS_IN_YEAR
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	RETURN 1;
	
SELECT @last_move_date = LAST_MOVE_DATE, @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00)
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @acc_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	RETURN 1;	

SET @start_date = ISNULL(@last_move_date, @start_date)

SET @formula = 'CASE WHEN AMOUNT<-0 THEN AMOUNT*-2.0 ELSE 0 END'

EXEC @r = dbo.calc_accrual_amount
	@acc_id = @acc_id,
	@start_date = @start_date,
	@end_date	= @annul_date,
	@formula = @formula,
	@is_debit = 0,
	@amount = @annul_amount OUTPUT,
	@month_eq_30 = 0,
	@is_real = 0,
	@days_in_year = @days_in_year,
	@tax_rate = $0.00,
	@recalc_option = 0x02	-- 0x02 - Recalc from last realize date

IF @@ERROR <> 0 OR @r <> 0
	RETURN 1

SET @annul_amount = @annul_amount + @total_payed_amount

RETURN 0
GO
