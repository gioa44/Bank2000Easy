SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_calc_annul_advance_proc_jur_prolong2]
	@depo_id int,
	@user_id int,
	@dept_no int,
	@annul_date smalldatetime,
	@start_point tinyint OUTPUT,
	@annul_intrate money OUTPUT,
	@annul_amount money OUTPUT
AS
SET NOCOUNT ON;

SET @annul_amount = $0.00

DECLARE
	@pfDontIncludeStartDate int,
	@pfDontIncludeEndDate int

SET @pfDontIncludeStartDate = 1
SET @pfDontIncludeEndDate = 2

DECLARE
	@depo_start_date smalldatetime,
	@depo_end_date smalldatetime,
	@days_in_year int,
	@depo_acc_id int,
	@prolongation_count int

SELECT @depo_start_date = [START_DATE], @depo_end_date = END_DATE, @days_in_year = DAYS_IN_YEAR, @prolongation_count = ISNULL(PROLONGATION_COUNT, 0), @depo_acc_id = DEPO_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: DEPOSIT DATA NOT FOUND', 16, 1); RETURN 1; END	

IF @prolongation_count > 0
BEGIN
	DECLARE
		@start_date smalldatetime,
		@end_date smalldatetime,
		@perc_flags int,
		@formula varchar(512),
		@tax_rate money

	SELECT @start_date = [START_DATE], @formula = FORMULA, @tax_rate = TAX_RATE, @perc_flags = PERC_FLAGS
	FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
	WHERE ACC_ID = @depo_acc_id
	
	SET @end_date = @start_date
		
	WHILE DATEADD(MONTH, 1, @end_date) <= @annul_date
	BEGIN
		SET @end_date = DATEADD(MONTH, 1, @end_date)
	END
	
	IF @end_date > @start_date
	BEGIN
		IF (@perc_flags & @pfDontIncludeEndDate = 0)
			SET @end_date = @end_date + 1
		
		EXEC dbo.calc_accrual_amount
			@acc_id = @depo_acc_id,
			@start_date = @start_date,
			@end_date	= @end_date,
			@formula = @formula,
			@is_debit	= 0,
			@amount = @annul_amount OUTPUT,
			@month_eq_30 = 0,
			@is_real = 0,
			@days_in_year = @days_in_year,
			@tax_rate  = @tax_rate,
			@recalc_option = 0x04
		  
		SET @annul_amount = ROUND(@annul_amount, 2) 	 
	END	
END


RETURN 0
GO
