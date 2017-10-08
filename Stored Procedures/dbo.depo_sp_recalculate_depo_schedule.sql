SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_recalculate_depo_schedule]
	@op_id int,
	@depo_id int,
	@op_date smalldatetime,
	@new_intrate money
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE
	@r int,
	@prod_id int,
	@depo_acc_id int,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@date1 smalldatetime,
	@date2 smalldatetime,
	@last_calc_date smalldatetime,
	@days_in_year int,
	@formula varchar(255),

	@calc_amount1 money,
	@calc_amount2 money,
	@tax_rate money,

	@recalculate_date smalldatetime,
	@new_agreement_amount money,

	@sum_payment money,
	@sum_principal money,
	@sum_interest money,
	@sum_interest_tax money,
	@sum_tax money,

	@new_first_schedule_date smalldatetime,
	
	@old_schedule_interest money,
	@old_schedule_interest_tax money,
	@old_schedule_tax money,

	@new_schedule_interest money,
	@new_schedule_interest_tax money,
	@new_schedule_tax money,
	
	@perc_flags int,	
	@pfDontIncludeStartDate int,
	@pfDontIncludeEndDate int,

	@delta_schedule_interest money,
	@delta_schedule_interest_tax money,
	@delta_schedule_tax money


	DECLARE 
		@new_depo_schedule TABLE(	SCHEDULE_DATE smalldatetime NOT NULL PRIMARY KEY,
									PAYMENT money NOT NULL,	
									PRINCIPAL money NOT NULL,
									INTEREST money NOT NULL,
									INTEREST_TAX money NOT NULL,
									TAX money NOT NULL,
									BALANCE money NULL)

SET @pfDontIncludeStartDate = 1
SET @pfDontIncludeEndDate = 2

INSERT INTO dbo.DEPO_SCHEDULE_ARC
SELECT @op_id, * 
FROM dbo.DEPO_SCHEDULE (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE DEPO SCHEDULE ARC', 16, 1); RETURN (1); END

INSERT INTO @new_depo_schedule
SELECT SCHEDULE_DATE, PAYMENT, PRINCIPAL, INTEREST, INTEREST_TAX, TAX, BALANCE
FROM dbo.DEPO_SCHEDULE (NOLOCK)
WHERE DEPO_ID = @depo_id AND SCHEDULE_DATE <= @op_date
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT INTO @depo_schedule_new', 16, 1); RETURN (1); END

SELECT	@sum_payment = ISNULL(SUM(PAYMENT), $0.00),
		@sum_principal = ISNULL(SUM(PRINCIPAL), $0.00),
		@sum_interest = ISNULL(SUM(INTEREST), $0.00),
		@sum_interest_tax = ISNULL(SUM(INTEREST_TAX), $0.00),
		@sum_tax = ISNULL(SUM(TAX),  $0.00)
FROM @new_depo_schedule
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR CALCULATING DATA!', 16, 1); RETURN (1); END

SET @recalculate_date = NULL
SELECT @recalculate_date = MAX(SCHEDULE_DATE)
FROM dbo.DEPO_SCHEDULE (NOLOCK)
WHERE DEPO_ID = @depo_id AND SCHEDULE_DATE <= @op_date
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR CALCULATING @recalculate_date!', 16, 1); RETURN (1); END

DELETE FROM dbo.DEPO_SCHEDULE
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR DELETE DEPO SCHEDULE', 16, 1); RETURN (1); END

SELECT	@prod_id = D.PROD_ID
		,@depo_acc_id = D.DEPO_ACC_ID		
		,@start_date = D.[START_DATE]
		,@end_date = D.END_DATE
		,@days_in_year = D.DAYS_IN_YEAR
		,@formula = CP.FORMULA
		,@calc_amount1 = ISNULL(CP.CALC_AMOUNT, $0.00) --@recalculate_date–დან  @op_date–მდე დარიცხული სარგებელი ძველი საპროცენტო განაკვეთით
		,@last_calc_date = CP.LAST_CALC_DATE
		,@tax_rate = TAX_RATE
		,@recalculate_date = ISNULL(@recalculate_date, D.START_DATE)
		,@new_agreement_amount = D.AMOUNT
		,@new_intrate = D.REAL_INTRATE,
		@perc_flags = CP.PERC_FLAGS
FROM dbo.DEPO_DEPOSITS (NOLOCK)D
	INNER JOIN dbo.ACCOUNTS_CRED_PERC (NOLOCK) CP ON D.DEPO_ACC_ID = CP.ACC_ID
WHERE D.DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR READING DEPO DATA', 16, 1); RETURN (1); END

INSERT INTO @new_depo_schedule
EXEC @r = dbo.depo_sp_get_depo_reailze_schedule
	@depo_amount = @new_agreement_amount,
	@start_date = @recalculate_date,
	@end_date = @end_date,
	@date = @recalculate_date,
	@intrate = @new_intrate,
	@prod_id = @prod_id,
	@tax_rate = @tax_rate,
	@result_type = 1
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE NEW DEPO SCHEDULE', 16, 1); RETURN (1); END

SELECT @new_first_schedule_date = MIN(SCHEDULE_DATE)
FROM @new_depo_schedule
WHERE SCHEDULE_DATE > @op_date
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR SCHEDULE DATE NOT FOUNT', 16, 1); RETURN (1); END

SELECT	@old_schedule_interest = INTEREST, --დარიცხული სარგებელი ახალი საპროცენტო განაკვეთით @recalculate_date–დან @new_first_schedule_date–მდე
		@old_schedule_interest_tax = INTEREST_TAX,
		@old_schedule_tax = TAX
FROM @new_depo_schedule
WHERE SCHEDULE_DATE = @new_first_schedule_date
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR SCHEDULE DATE NOT FOUNT', 16, 1); RETURN (1); END

SET @date1 = @recalculate_date
SET @date2 = @op_date

IF (@date1 = @start_date) AND (@perc_flags & @pfDontIncludeStartDate <> 0)
	SET @date1 = @date1 + 1

IF (@date2 = @end_date)   AND (@perc_flags & @pfDontIncludeEndDate <> 0)
	SET @date2 = @date2 - 1

--IF (@last_calc_date IS NOT NULL) AND (@date1 <= @last_calc_date)
--	SET @date1 = @last_calc_date + 1

EXEC @r = dbo.calc_accrual_amount --@recalculate_date–დან  @op_date–მდე დარიცხული სარგებელი ახალი საპროცენტო განაკვეთით
	@acc_id = @depo_acc_id,
	@start_date = @date1,
	@end_date = @date2,
	@formula = @formula,
	@is_debit = 0,
	@amount = @calc_amount2 OUTPUT,
	@month_eq_30 = 0,
	@is_real = 0,
	@days_in_year = @days_in_year,
	@tax_rate = @tax_rate,
	@recalc_option = 0x00	-- 0x00 - Auto
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR CALC ACCRUAL AMOUNT', 16, 1); RETURN (1); END

SET @delta_schedule_interest = ISNULL(@calc_amount1, $0.00) - ISNULL(@calc_amount2, $0.00)
SET @delta_schedule_interest_tax = @delta_schedule_interest * ($1.0 - @tax_rate / $100.0)
SET @delta_schedule_tax = @delta_schedule_interest * @tax_rate / $100.0

--SET @new_schedule_interest = @old_schedule_interest + @delta_schedule_interest
--SET @new_schedule_interest_tax = @new_schedule_interest * ($1.0 - @tax_rate / $100.0)
--SET @new_schedule_tax = @new_schedule_interest * @tax_rate / $100.0
 
UPDATE @new_depo_schedule
SET PAYMENT = PRINCIPAL + (INTEREST + @delta_schedule_interest),
	INTEREST = INTEREST + @delta_schedule_interest,
	INTEREST_TAX = INTEREST_TAX + @delta_schedule_interest_tax,
	TAX = TAX + @delta_schedule_tax
WHERE SCHEDULE_DATE = @new_first_schedule_date
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE DEPO SCHEDULE', 16, 1); RETURN (1); END

UPDATE @new_depo_schedule
SET PAYMENT = (PRINCIPAL + @sum_principal) + (INTEREST + @delta_schedule_interest) + @sum_payment,
	PRINCIPAL = PRINCIPAL + @sum_principal,
	INTEREST = INTEREST + @delta_schedule_interest + @sum_interest,
	INTEREST_TAX = INTEREST_TAX + @delta_schedule_interest_tax + @sum_interest_tax,
	TAX = TAX + @delta_schedule_tax + @sum_tax
WHERE SCHEDULE_DATE = '20790101'
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE DEPO SCHEDULE', 16, 1); RETURN (1); END

INSERT INTO dbo.DEPO_SCHEDULE
SELECT @depo_id, * 
FROM @new_depo_schedule
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT DEPO SCHEDULE', 16, 1); RETURN (1); END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

END
GO
