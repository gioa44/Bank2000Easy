SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_calc_annul_amount]
	@depo_id int,
	@user_id int,
	@dept_no int,
	@annul_date smalldatetime,
	@annul_amount money  = NULL OUTPUT,
	@annul_intrate money = NULL OUTPUT,
	@show_result bit = 0
AS
SET NOCOUNT ON;

DECLARE
	@r int
	
SET @annul_amount = NULL	
	
DECLARE
	@iso CHAR(3),
	@depo_amount money,
	@date_type tinyint,
	@start_date smalldatetime,
	@real_intrate TRATE,
	@recalculate_type tinyint,
	@depo_acc_id int,
	@annulment_schema int,
	@annulment_schema_advance int
	
SELECT @depo_amount = D.AMOUNT, @iso = D.ISO, @start_date = D.[START_DATE], @real_intrate = D.REAL_INTRATE, @recalculate_type = D.RECALCULATE_TYPE, @depo_acc_id = D.DEPO_ACC_ID,
	@annulment_schema = D.ANNULMENT_SCHEMA, @annulment_schema_advance = D.ANNULMENT_SCHEMA_ADVANCE
FROM dbo.DEPO_DEPOSITS (NOLOCK)D
WHERE D.DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: DEPOSIT NOT FOUND', 16, 1); RETURN 1; END

DECLARE
	@recalc_option tinyint

SET @recalc_option = 0x00

IF @recalculate_type & 0x01 <> 0
	SET @recalc_option = 0x01
ELSE
IF @recalculate_type & 0x02 <> 0
	SET @recalc_option = 0x02
ELSE
IF @recalculate_type & 0x04 <> 0
	SET @recalc_option = 0x04


DECLARE
	@advance_amount money,
	@calc_amount money,
	@total_calc_amount money,
	@total_payed_amount money,
	@last_move_date smalldatetime,
	@total_tax_payed_amount money,
	@total_tax_payed_amount_equ money

	
SELECT @calc_amount = ISNULL(CALC_AMOUNT, $0.00), @last_move_date = LAST_MOVE_DATE,	
	@total_calc_amount = ROUND(ISNULL(TOTAL_CALC_AMOUNT, $0.00), 2), @total_payed_amount = ROUND(ISNULL(TOTAL_PAYED_AMOUNT, $0.00), 2),
	@total_tax_payed_amount = ISNULL(TOTAL_TAX_PAYED_AMOUNT, $0.00), @total_tax_payed_amount_equ = ROUND(ISNULL(TOTAL_TAX_PAYED_AMOUNT_EQU, $0.00), 2),
	@advance_amount = ISNULL(ADVANCE_AMOUNT, $0.00)
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @depo_acc_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: ACCOUNT CRED PERC SCHEMA NOT FOUND', 16, 1); RETURN 1; END

DECLARE
	@start_point tinyint
	
IF @annulment_schema IS NOT NULL
BEGIN
	SELECT @date_type = DATE_TYPE, @start_point = START_POINT
	FROM dbo.DEPO_PRODUCT_ANNULMENT_SCHEMA (NOLOCK)
	WHERE [SCHEMA_ID] = @annulment_schema
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: ANNULMENT SCHEMA NOT FOUND', 16, 1); RETURN 1; END	

	DECLARE 	
		@item_between int
	
	IF @date_type = 1 --დღეები
		SET @item_between = DATEDIFF(DAY, @start_date, @annul_date)
	ELSE
	BEGIN
		SET @item_between = DATEDIFF(MONTH, @start_date, @annul_date)

		IF DATEADD(MONTH, @item_between, @start_date) > @annul_date
			SET @item_between = @item_between - 1
	END
	
	SELECT TOP 1 @annul_intrate = INTRATE
	FROM dbo.DEPO_PRODUCT_ANNULMENT_SCHEMA_DETAILS (NOLOCK)
	WHERE [SCHEMA_ID] = @annulment_schema AND ISO = @iso AND ITEMS <= @item_between
	ORDER BY ITEMS DESC
	
	IF @start_date > @annul_date 
		SET @annul_intrate = $0.00
END

IF (@annulment_schema_advance IS NOT NULL)
BEGIN
	DECLARE
		@sql nvarchar(2000),
		@annul_advance_proc varchar(128)
		
	SELECT @annul_advance_proc = PROCEDURE_NAME
	FROM dbo.DEPO_PRODUCT_ANNULMENT_SCHEMA_ADVANCE (NOLOCK) 
	WHERE [SCHEMA_ID] = @annulment_schema_advance
		
	SET @sql = 'EXEC @r=' + @annul_advance_proc +
		' @depo_id=@depo_id,@user_id=@user_id,@dept_no=@dept_no,@annul_date=@annul_date,@start_point=@start_point OUTPUT, @annul_intrate=@annul_intrate OUTPUT,@annul_amount=@annul_amount OUTPUT'
	EXEC sp_executesql @sql, N'@r int OUTPUT, @depo_id int,@user_id int,@dept_no int,@annul_date smalldatetime,@start_point tinyint OUTPUT,@annul_intrate money OUTPUT,@annul_amount money OUTPUT',
		@r OUTPUT, @depo_id, @user_id, @dept_no, @annul_date, @start_point OUTPUT, @annul_intrate OUTPUT,@annul_amount OUTPUT
		
	IF @@ERROR <> 0 OR @r <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÃÀÒÙÅÄÅÉÓ ÀËÔÄÒÍÀÔÉÖËÉ ÓØÄÌÉÓ ÛÄÓÒÖËÄÁÉÓ ÃÒÏÓ!', 16, 1); RETURN 1; END	
END

IF @annul_amount IS NOT NULL
	GOTO _show_result


IF @annul_intrate IS NULL
BEGIN
	RAISERROR('ÃÀÒÙÅÄÅÉÓ ÓÀÐÒÏÝÄÍÔÏ ÂÀÍÀÊÅÄÈÉ ÀÒ ÀÒÉÓ ÂÀÍÓÀÆÙÅÒÖËÉ', 16, 1);
	RETURN (1)
END

DECLARE
	@close_amount money

EXEC @r = dbo.PROCESS_ACCRUAL
	@perc_type = 0,
	@acc_id = @depo_acc_id,
	@user_id = @user_id,
	@dept_no = @dept_no,
	@doc_date = @annul_date,
	@calc_date = @annul_date,
	@force_realization = 1,
	@simulate = 1,
	@show_result = 0,
	@depo_depo_id = @depo_id,
	@interest_amount  = @close_amount OUTPUT

SET @close_amount = ISNULL(@close_amount, $0.00)

IF @recalc_option = 0x04 -- ÓÖË ÈÀÅÉÃÀÍ 
	SET @close_amount = @close_amount - @total_payed_amount 

SET @close_amount = @close_amount + @total_payed_amount 

IF @start_point = 2 
	SET @close_amount = @close_amount - @total_payed_amount 

SET @annul_amount = ROUND(@close_amount * @annul_intrate / @real_intrate, 2) 

IF @start_point = 2 
	SET @annul_amount = @annul_amount + @total_payed_amount 

_show_result:

IF @show_result = 1
	SELECT @annul_amount AS ANNUL_AMOUNT, @annul_intrate AS ANNUL_INTRATE, @depo_amount AS DEPO_AMOUNT, @advance_amount AS ADVANCE_AMOUNT,
		@calc_amount AS CALC_AMOUNT, @total_calc_amount AS TOTAL_CALC_AMOUNT, @total_payed_amount AS TOTAL_PAYED_AMOUNT, @last_move_date AS LAST_MOVE_DATE,
		@total_tax_payed_amount AS TOTAL_TAX_PAYED_AMOUNT, @total_tax_payed_amount_equ AS TOTAL_TAX_PAYED_AMOUNT_EQU

RETURN 0
GO
