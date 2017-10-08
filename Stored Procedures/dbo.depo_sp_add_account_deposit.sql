SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_add_account_deposit]
	@depo_id int,
	@user_id int,
	@op_date smalldatetime,
	@depo_account TACCOUNT = NULL,
	@acc_id int OUTPUT,
	@bal_acc TBAL_ACC OUTPUT
AS
SET NOCOUNT ON;

DECLARE
	@e int,
	@r int

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE -- Deposit Data
	@branch_id int,
	@dept_no int,
	@client_no int,
	@prod_id int,
	@depo_type tinyint,
	@depo_acc_subtype int,
	@depo_account_state tinyint,
	@iso char(3),
	@end_date smalldatetime,
	@shareable bit,
	@shared_control_client_no int,
	@shared_control bit,
	@child_deposit bit,
	@child_control_client_no_1 int,
	@child_control_client_no_2 int,
	@min_amount money,
	@min_amount_new money,
	@min_amount_check_date smalldatetime,
	@spend_amount money


SELECT 	@branch_id = BRANCH_ID,	@dept_no = DEPT_NO,	@client_no = CLIENT_NO,	@prod_id = PROD_ID,
	@depo_type = DEPO_TYPE, @depo_acc_subtype = DEPO_ACC_SUBTYPE, @depo_account_state = DEPO_ACCOUNT_STATE,
	@iso = ISO,	@end_date = END_DATE,
	@shareable = SHAREABLE, @shared_control_client_no = SHARED_CONTROL_CLIENT_NO, @shared_control = SHARED_CONTROL,
	@child_deposit = CHILD_DEPOSIT, @child_control_client_no_1 = CHILD_CONTROL_CLIENT_NO_1, @child_control_client_no_2 = CHILD_CONTROL_CLIENT_NO_2,
	@spend_amount = SPEND_AMOUNT

FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR: DEPOSIT NOT FOUND!', 16, 1); RETURN (1); END

DECLARE -- Product Data
	@prod_no int,
	@template varchar(150)

SELECT @prod_no = PROD_NO, @template = DEPO_ACC_TEMPL
FROM dbo.DEPO_PRODUCT (NOLOCK)
WHERE PROD_ID = @prod_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR: DEPOSIT PRODUCT NOT FOUND!', 16, 1); RETURN (1); END


EXEC @r = dbo.depo_sp_get_depo_bal_acc
	@bal_acc = @bal_acc OUTPUT,
	@client_no = @client_no,
	@prod_id = @prod_id,
	@iso = @iso,
	@depo_type = @depo_type

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING BALANCE ACCOUNT', 16, 1); RETURN (1); END


IF (@bal_acc IS NULL) OR NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ ÐÒÏÃÖØÔÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ', 16, 1); RETURN(1); END

DECLARE
	@account TACCOUNT,
	@rec_state tinyint,
	@client_type tinyint,
	@descrip varchar(150),
	@descrip_lat varchar(150),
	@acc_product_no int,
	@acc_open_date smalldatetime,
	@acc_period smalldatetime,
	@remark varchar(100)

SET @account = NULL

IF @depo_account IS NOT NULL
BEGIN
	IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT = @depo_account AND ISO = @iso)
		SET @account = @depo_account
END

IF @account IS NULL
BEGIN
	EXEC dbo.depo_sp_generate_account
		@account = @account OUTPUT,  
		@template = @template,
		@branch_id = @branch_id,
		@dept_id = @dept_no,
		@bal_acc = @bal_acc,  
		@depo_bal_acc = @bal_acc,
		@client_no = @client_no, 
		@ccy = @iso, 
		@prod_code4	= @prod_no

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GENERATE DEPOSIT ACCOUNT', 16, 1); RETURN (1); END
END

SELECT @client_type = CLIENT_TYPE, @descrip = DESCRIP, @descrip_lat = DESCRIP_LAT
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1) RETURN (1) END

IF @shareable = 1
BEGIN
	SELECT @descrip = @descrip + ' (' + DESCRIP + ')', @descrip_lat = @descrip_lat + ' (' + DESCRIP_LAT + ')'
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @shared_control_client_no
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END

	IF @shared_control = 1
		SET @remark = 'ÄÒÈÏÁËÉÅÉ ÂÀÍÊÀÒÂÅÉÓ Ö×ËÄÁÉÈ'
	ELSE
		SET @remark = 'ÃÀÌÏÖÊÉÃÄÁÄËÉ ÂÀÍÊÀÒÂÅÉÓ Ö×ËÄÁÉÈ'
END

IF @child_deposit = 1
BEGIN
	SELECT @remark = @remark + ' (' + DESCRIP
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @child_control_client_no_1
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END

	IF @child_control_client_no_2 IS NOT NULL
	BEGIN
		SELECT @remark = @remark + ', ' + DESCRIP
		FROM dbo.CLIENTS (NOLOCK)
		WHERE CLIENT_NO = @child_control_client_no_2
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END
	END

	SET @remark = @remark + ') '
END 

SET @rec_state = CASE @depo_account_state
	WHEN 1 THEN 1
	WHEN 2 THEN 4
	WHEN 3 THEN 16
END

SET @acc_product_no = @prod_no
SET @acc_open_date = @op_date
SET	@acc_period = @end_date

EXEC @r = dbo.on_user_depo_sp_add_deposit_account
	@prod_id = @prod_id,
	@client_no = @client_no,
	@descrip = @descrip OUTPUT,
	@descrip_lat = @descrip_lat OUTPUT,
	@date_open = @acc_open_date OUTPUT,
	@period = @acc_period OUTPUT,
	@product_no = @acc_product_no OUTPUT
IF @r <> 0 OR @@ERROR<>0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÆÄ ÐÀÒÀÌÄÔÒÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ', 16, 1); RETURN (1); END

IF @acc_product_no IS NOT NULL
BEGIN
	IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS (NOLOCK) WHERE PRODUCT_NO = @acc_product_no)
	BEGIN RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END

	IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS_FILTER (NOLOCK) WHERE BAL_ACC = @bal_acc AND PRODUCT_NO = @acc_product_no)
	BEGIN RAISERROR ('ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END
END

IF NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
BEGIN RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ ÐÒÏÃÖØÔÉÓ ÛÄÓÀÁÀÌÉÓÉ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ (ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN(1); END

IF ISNULL(@spend_amount, $0.00) <> $0.00
BEGIN
	SET @min_amount =  @spend_amount
	SET @min_amount_new = @spend_amount
	SET @min_amount_check_date = @end_date
END
ELSE
BEGIN
	SET @min_amount = $0.00
	SET @min_amount_new = $0.00
	SET @min_amount_check_date = NULL
END

EXEC @r = dbo.ADD_ACCOUNT
	@acc_id = @acc_id OUTPUT,
	@user_id = @user_id,
	@dept_no = @dept_no,
	@account = @account,
	@iso = @iso,
	@bal_acc_alt = @bal_acc,
	@rec_state = @rec_state,
	@descrip = @descrip,
	@descrip_lat = @descrip_lat,
	@acc_type = 32,
	@acc_subtype = @depo_acc_subtype,
	@client_no = @client_no,
	@date_open = @acc_open_date,
	@period = @acc_period,
	@product_no = @acc_product_no,
	@min_amount = @min_amount,
	@min_amount_new = @min_amount_new,
	@min_amount_check_date = @min_amount_check_date,
	@remark = @remark
IF @r <> 0 OR @@ERROR<>0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ', 16, 1); RETURN (1); END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN 0
GO
