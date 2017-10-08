SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--------------------------------




CREATE PROCEDURE [dbo].[depo_sp_add_account_loss]
	@depo_id int,
	@user_id int,
	@op_date smalldatetime,
	@depo_bal_acc TBAL_ACC,
	@acc_id int OUTPUT
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
	@iso char(3),
	@end_date smalldatetime

DECLARE
	@common_branch_id int,
	@acc_branch_id int,
	@acc_dept_no int

SET @common_branch_id = dbo.depo_common_branch_id()

SELECT 	@branch_id = BRANCH_ID,	@dept_no = DEPT_NO,	@client_no = CLIENT_NO,	@prod_id = PROD_ID,
	@depo_type = DEPO_TYPE,	@iso = ISO,	@end_date = END_DATE
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR: DEPOSIT NOT FOUND!', 16, 1); RETURN (1); END

DECLARE -- Product Data
	@prod_no int,
	@template varchar(150)

SELECT @prod_no = PROD_NO, @template = LOSS_ACC_TEMPL
FROM dbo.DEPO_PRODUCT (NOLOCK)
WHERE PROD_ID = @prod_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR: DEPOSIT PRODUCT NOT FOUND!', 16, 1); RETURN (1); END

DECLARE
	@bal_acc TBAL_ACC

EXEC @r = dbo.depo_sp_get_depo_loss_bal_acc
	@bal_acc = @bal_acc OUTPUT,
	@depo_bal_acc = @depo_bal_acc,
	@client_no = @client_no,
	@prod_id = @prod_id,
	@iso = @iso,
	@depo_type = @depo_type

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING BALANCE ACCOUNT', 16, 1); RETURN (1); END

IF (@bal_acc IS NULL) OR NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ', 16, 1); RETURN(1); END

DECLARE
	@account TACCOUNT,
	@descrip varchar(150),
	@descrip_lat varchar(150),
	@acc_product_no int,
	@acc_open_date smalldatetime,
	@acc_period smalldatetime


IF (CHARINDEX('N', UPPER(@template)) = 0) AND (@common_branch_id <> -1)
BEGIN
	SET @acc_branch_id = @common_branch_id
	SET @acc_dept_no = @common_branch_id
END
ELSE
BEGIN
	SET @acc_branch_id = @branch_id
	SET @acc_dept_no = @dept_no
END


EXEC dbo.depo_sp_generate_account
	@account = @account OUTPUT,  
	@template = @template,
	@branch_id = @branch_id,
	@dept_id = @acc_dept_no,
	@bal_acc = @bal_acc,  
	@depo_bal_acc = @depo_bal_acc,
	@client_no = @client_no, 
	@ccy = @iso, 
	@prod_code4	= @prod_no

IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GENERATE DEPOSIT LOSS ACCOUNT', 16, 1); RETURN (1); END

IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @acc_branch_id AND ACCOUNT = @account AND ISO = @iso)
BEGIN
	IF CHARINDEX('N', UPPER(@template)) = 0
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
		RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÐÒÏÝÄÍÔÖËÉ áÀÒãÄÁÉ ÃÄÐÏÆÉÔÄÁÉÓ ÌÉáÄÃÅÉÈ ×ÉØÓÉÒÄÁÖËÉ ÀÍÂÀÒÉÛÉ', 16, 1);
		RETURN (1);
	END

	SELECT @descrip = 'ÐÒÏÝÄÍÔÖËÉ áÀÒãÄÁÉ ÃÄÐÏÆÉÔÄÁÉÓ ÌÉáÄÃÅÉÈ', @descrip_lat = 'Account 83 (LOSS)'

	SET @acc_product_no = NULL
	SET @acc_open_date = @op_date
	SET	@acc_period = @end_date

	EXEC @r = dbo.on_user_depo_sp_add_deposit_loss_account
		@prod_id = @prod_id,
		@client_no = @client_no,
		@descrip = @descrip OUTPUT,
		@descrip_lat = @descrip_lat OUTPUT,
		@date_open = @acc_open_date OUTPUT,
		@period = @acc_period OUTPUT,
		@product_no = @acc_product_no OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÆÄ ÐÀÒÀÌÄÔÒÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ', 16, 1); RETURN (1); END

	IF @acc_product_no IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS (NOLOCK) WHERE PRODUCT_NO = @acc_product_no)
		BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END

		IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS_FILTER (NOLOCK) WHERE BAL_ACC = @bal_acc AND PRODUCT_NO = @acc_product_no)
		BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END
	END

	EXEC @r = dbo.ADD_ACCOUNT
		@acc_id = @acc_id OUTPUT,
		@user_id = @user_id,
		@dept_no = @acc_dept_no,
		@account = @account,
		@iso = @iso,
		@bal_acc_alt = @bal_acc,
		@rec_state = 1,
		@descrip = @descrip,
		@descrip_lat = @descrip_lat,
		@acc_type = 1,
		@acc_subtype = NULL,
		@client_no = @client_no,
		@date_open = @acc_open_date,
		@period = @acc_period,
		@product_no = @acc_product_no
	IF @@ERROR <> 0 AND @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ', 16, 1); RETURN (1); END
END
ELSE
	SET @acc_id = dbo.acc_get_acc_id (@acc_branch_id, @account, @iso)


IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN 0
GO
