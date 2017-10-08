SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_calc_annul_amount]
(
	@depo_id int,
	@state int
)
RETURNS money
AS
BEGIN

DECLARE @annul_intrate money
SET @annul_intrate = NULL	

IF @state = 240 
BEGIN
	SELECT @annul_intrate = DEPO_REALIZE_INTEREST 
	FROM dbo.DEPO_VW_OP_DATA_ANNULMENT (NOLOCK)
	WHERE DEPO_ID = @depo_id
	
END
ELSE IF @state = 241 
BEGIN
	SELECT @annul_intrate=DEPO_REALIZE_INTEREST 
	FROM dbo.DEPO_VW_OP_DATA_ANNULMENT_AMOUNT (NOLOCK)
	WHERE DEPO_ID = @depo_id
END	
ELSE IF @state = 245 
BEGIN
	SELECT @annul_intrate=DEPO_REALIZE_INTEREST 
	FROM dbo.DEPO_VW_OP_DATA_ANNULMENT_POSITIVE (NOLOCK) 
	WHERE DEPO_ID = @depo_id
END	

/*




DECLARE
	@r int
	

DECLARE
	@iso CHAR(3),
	@depo_amount money,
	@date_type tinyint,
	@start_date smalldatetime,
	@real_intrate TRATE,
	@depo_acc_id int,
	@annulment_schema int,
	@annulment_schema_advance int
	
SELECT @depo_amount = AMOUNT, @iso = ISO, @start_date = [START_DATE], @real_intrate = REAL_INTRATE, @depo_acc_id = DEPO_ACC_ID,
	@annulment_schema = ANNULMENT_SCHEMA, @annulment_schema_advance = ANNULMENT_SCHEMA_ADVANCE
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RETURN -1; END

DECLARE
	@advance_amount money,
	@calc_amount money,
	@total_calc_amount money,
	@total_payed_amount money,
	@last_move_date smalldatetime

	
SELECT @calc_amount = ISNULL(CALC_AMOUNT, $0.00), @last_move_date = LAST_MOVE_DATE,	
	@total_calc_amount = ISNULL(TOTAL_CALC_AMOUNT, $0.00), @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00),
	@advance_amount = ISNULL(ADVANCE_AMOUNT, $0.00)
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @depo_acc_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RETURN -1; END

DECLARE
	@annul_intrate money
	
DECLARE
	@start_point tinyint
	
IF @annulment_schema IS NOT NULL
BEGIN
	SELECT @date_type = DATE_TYPE, @start_point = START_POINT
	FROM dbo.DEPO_PRODUCT_ANNULMENT_SCHEMA (NOLOCK)
	WHERE [SCHEMA_ID] = @annulment_schema
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RETURN -1; END	

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
		
	IF @@ERROR <> 0 OR @r <> 0 BEGIN RETURN -1; END	
END

IF @annul_intrate IS NULL	
	RETURN (-1)
*/
RETURN(@annul_intrate)

END
GO
