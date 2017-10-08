SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[depo_add_deposit]
	@did int OUTPUT,
	@user_id int,
	@branch_id int,
	@dept_no int,
	@reg_date smalldatetime,
	@cid int,               
	@dtype_id int,            
	@prod_id int,             
	@start_date smalldatetime,
	@end_date smalldatetime,  
	@iso TISO,                
	@amount money,          
	@client_account int,
	@int_rate money,        
	@accumulate bit,          
	@move_count smallint,     
	@move_count_type tinyint, 
	@calc_type tinyint,       
	@days_in_year smallint,   
	@perc_flags int,          
	@perc_type tinyint,
	@tax_rate money,
	@prolongation bit,
	@ext_acc_id int,
	@realize_advance bit,
	@converted_deposit bit,
	@realize_adv_acc_id int,
	@rec_id int OUTPUT,
	@doc_type int OUTPUT,
	@rec_id2 int OUTPUT,
	@doc_type2 int OUTPUT
AS

SET NOCOUNT ON;

DECLARE
	@r int,
	@e int,
	@depo_no varchar(50),
	@rec_state tinyint

DECLARE
	@product_no int,
	@client_type int,
	@acc_only_cred bit,  
	@template_depo varchar(100),
	@template_disb varchar(100),
	@template_perc varchar(100),
	@template_realize_adv_acc varchar(100),
	@depo_acc_subtype int

DECLARE
	@start_date_type tinyint,
	@start_date_days int,
	@date_type tinyint,
	@open_date smalldatetime

SET @open_date = convert(smalldatetime, FLOOR(convert(float, GETDATE())))
IF DATEPART(hh, GETDATE()) >= 17
	SET @open_date = @open_date + 1 

SET @open_date = dbo.GET_NEAR_DAY_UP(@open_date)

DECLARE @annulment_method_id int

SELECT
	@product_no = PROD_NO,
	@template_depo = DEPOSIT_ACCOUNT,
	@template_disb = DISB_ACCOUNT,
	@template_perc = ACRUAL_ACCOUNT,
	@client_type = CLIENT_TYPE,
	@template_realize_adv_acc = REALIZE_ADV_ACCOUNT, 
	@depo_acc_subtype = DEPO_ACC_SUBTYPE,
	@annulment_method_id = ANNULMENT_METHOD
FROM dbo.DEPO_PRODUCTS (NOLOCK)
WHERE PROD_ID = @prod_id

SELECT
	@start_date_type	= START_DATE_TYPE,
	@start_date_days	= START_DATE_DAYS,
	@date_type			= DATE_TYPE
FROM dbo.DEPO_ANNULMENT_METHODS
WHERE METHOD_ID = @annulment_method_id	 

SET @acc_only_cred = CASE WHEN @client_type & 16 <> 0 THEN 1 ELSE 0 END

DECLARE
	@bal_acc TBAL_ACC,
	@descrip varchar(150),
	@descrip_lat varchar(150)

DECLARE
	@acc_id int,
	@perc_client_account TACCOUNT,
	@perc_client_account_id int,
	@perc_bank_account TACCOUNT,
	@perc_bank_account_id int,
	@realize_adv_account TACCOUNT,
	@realize_adv_account_id int


IF @realize_advance = 1
BEGIN
	SET @bal_acc = NULL
	EXEC dbo.DX_SPX_GET_DEPOSIT_REALIZE_ADV_ACCOUNT @prod_id=@prod_id, @branch_id=@branch_id, @dept_no=@dept_no, @product_no=@product_no, @client_no=@cid, @iso=@iso, @user_id=@user_id, @template=@template_realize_adv_acc,
		@account=@realize_adv_account OUTPUT, @bal_acc=@bal_acc OUTPUT

	IF NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC=@bal_acc)
	BEGIN RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒ ÒÄÀËÉÆÀÝÉÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ',16,1) RETURN(1) END

	IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT=@realize_adv_account AND ISO=@iso)
	BEGIN
		SELECT @descrip='ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒ ÒÄÀËÉÆÀÝÉÉÓ ÀÍÂÀÒÉÛÉ', @descrip_lat='Account Realize Advance'

		EXEC @r = dbo.ADD_ACCOUNT @acc_id=@realize_adv_account_id OUTPUT,
			@user_id=@user_id, @dept_no=@dept_no, @account=@realize_adv_account, @iso=@iso, @bal_acc_alt=@bal_acc,
			@act_pas=NULL,@rec_state=1,@descrip=@descrip,@descrip_lat=@descrip_lat,@acc_type=1,@acc_subtype=NULL,@client_no=@cid,
			@date_open=@open_date
		IF @r <> 0 OR @@ERROR<>0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ áÀÒãÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ',16,1) RETURN(1) END
	END
	ELSE
		SET @realize_adv_account_id = dbo.acc_get_acc_id (@branch_id, @realize_adv_account, @iso)
END

SET @bal_acc = NULL
EXEC dbo.DX_SPX_GET_DEPOSIT_DISB_ACCOUNT @prod_id=@prod_id, @branch_id=@branch_id, @dept_no=@dept_no, @product_no=@product_no, @client_no=@cid, @iso=@iso, @user_id=@user_id, @template=@template_disb,
	@account=@perc_bank_account OUTPUT, @bal_acc=@bal_acc OUTPUT

IF NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC=@bal_acc)
BEGIN RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ',16,1) RETURN(1) END

IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT=@perc_bank_account AND ISO=@iso)
BEGIN
	SELECT @descrip='áÀÒãÉÓ ÀÍÂÀÒÉÛÉ', @descrip_lat='Account 83'

	EXEC @r = dbo.ADD_ACCOUNT @acc_id=@perc_bank_account_id OUTPUT,
		@user_id=@user_id, @dept_no=@dept_no, @account=@perc_bank_account, @iso=@iso, @bal_acc_alt=@bal_acc,
		@act_pas=0,@rec_state=1,@descrip=@descrip,@descrip_lat=@descrip_lat,@acc_type=1,@acc_subtype=NULL,@client_no=@cid,
		@date_open=@open_date
	IF @r <> 0 OR @@ERROR<>0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ áÀÒãÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ',16,1) RETURN(1) END
END
ELSE
	SET @perc_bank_account_id = dbo.acc_get_acc_id (@branch_id, @perc_bank_account, @iso)

SET @bal_acc = NULL
EXEC dbo.DX_SPX_GET_DEPOSIT_PERC_ACCOUNT @prod_id=@prod_id, @branch_id=@branch_id, @dept_no=@dept_no, @product_no=@product_no, @client_no=@cid, @iso=@iso, @user_id=@user_id, @template=@template_perc, @client_account = @client_account,
	@account=@perc_client_account OUTPUT, @bal_acc=@bal_acc OUTPUT 

IF NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC=@bal_acc)
BEGIN RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ ÃÀÒÉÝáÅÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ',16,1) RETURN(1) END

IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT=@perc_client_account AND ISO=@iso)
BEGIN
	SELECT @descrip='ÃÀÒÉÝáÅÉÓ ÀÍÂÀÒÉÛÉ', @descrip_lat='Accrual Account'
	EXEC @r = dbo.ADD_ACCOUNT @acc_id=@perc_client_account_id OUTPUT,
		@user_id=@user_id, @dept_no=@dept_no, @account=@perc_client_account, @iso=@iso, @bal_acc_alt=@bal_acc,
		@act_pas=1,@rec_state=1,@descrip=@descrip,@descrip_lat=@descrip_lat,@acc_type=128,@acc_subtype=NULL,@client_no=@cid,
		@date_open=@open_date
	IF @r <> 0 OR @@ERROR<>0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÃÀÒÉÝáÅÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ',16,1) RETURN(1) END
END
ELSE
	SET @perc_client_account_id = dbo.acc_get_acc_id (@branch_id, @perc_client_account, @iso) 

SET @bal_acc = NULL
IF @client_account IS NOT NULL
	SELECT @bal_acc = convert(int, BAL_ACC_ALT) FROM dbo.ACCOUNTS(NOLOCK) WHERE ACC_ID = @client_account
ELSE
	SET @bal_acc = CASE WHEN @iso = 'GEL' THEN 3601 ELSE 3611 END

IF @bal_acc BETWEEN 3501 AND 3599.99
	SET @bal_acc = @bal_acc + 20
ELSE
	SET @bal_acc = @bal_acc + 50


SELECT @bal_acc = BAL_ACC
FROM dbo.ACC_PRODUCTS_FILTER
WHERE convert(int, BAL_ACC) = @bal_acc AND PRODUCT_NO = @product_no

IF NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
BEGIN 
	RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ ÐÒÏÃÖØÔÉÓ ÛÄÓÀÁÀÌÉÓÉ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ',16,1) 
	RETURN(1) 
END

DECLARE @account TACCOUNT

EXEC dbo.GET_NEXT_ACC_NUM_NEW 
	@bal_acc=@bal_acc, 
	@branch_id=@branch_id,
	@dept_no=@dept_no, 
	@client_no=@cid, 
	@iso=@iso, 
	@product_no=@product_no, 
	@template=@template_depo,
	@acc=@account OUTPUT,
	@user_id=@user_id,
	@return_row=0

--SET @acc_subtype = CASE (@bal_acc - FLOOR(@bal_acc)) * 100 WHEN 3 THEN 43 WHEN 2 THEN 41 ELSE 40 END 

SET @rec_state = CASE WHEN @acc_only_cred = 1 THEN 4 ELSE 1 END
SELECT @descrip = DESCRIP, @descrip_lat=DESCRIP_LAT
FROM dbo.CLIENTS 
WHERE CLIENT_NO = @cid

BEGIN TRAN

EXEC @r = dbo.ADD_ACCOUNT @acc_id=@acc_id OUTPUT,
	@user_id=@user_id, @dept_no=@dept_no, @account=@account, @iso=@iso, @bal_acc_alt=@bal_acc,
	@act_pas=1,@rec_state=@rec_state,@descrip=@descrip,@descrip_lat=@descrip_lat,@acc_type=32,@acc_subtype=@depo_acc_subtype,@client_no=@cid,
	@date_open=@open_date, @period=@end_date, @product_no=@product_no
IF @r <> 0 OR @@ERROR<>0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ',16,1) ROLLBACK RETURN(1) END

IF @client_account IS NULL SET @client_account = @acc_id

DECLARE	@oid int

INSERT INTO dbo.DEPOS WITH (UPDLOCK) (CLIENT_NO, BRANCH_ID, DEPT_NO, DEPO_NO, DEPO_TYPE_ID, START_DATE, ACC_ID, ISO, PROD_ID, PROLONGATION, REALIZE_ADVANCE, REALIZE_ADV_ACC_ID, CONVERTED_DEPOSIT) 
VALUES (@cid, @branch_id, @dept_no, '', @dtype_id, @start_date, @acc_id, @iso, @prod_id, @prolongation, @realize_advance, @realize_adv_account_id, @converted_deposit)
IF @@ERROR <> 0 BEGIN RAISERROR ('ERROR INSERT DATA' ,16,1) ROLLBACK RETURN END

SET @did = SCOPE_IDENTITY()
INSERT INTO dbo.DEPO_OPS (DEPO_ID, DT, OP_NO, OP_TYPE, OWN_DATA, AMOUNT, SELF_EXEC, COMMIT_STATE, [OWNER], COMMITER_OWNER) 
VALUES (@did, @reg_date, 1, 10, 1, @amount, 1, 0xFF, @user_id, @user_id)
IF @@ERROR <> 0 AND @@ROWCOUNT <> 1 BEGIN RAISERROR ('ERROR INSERT DATA' ,16,1) ROLLBACK RETURN END

SET @oid = SCOPE_IDENTITY()

INSERT INTO dbo.DEPO_DATA (OP_ID, REC_STATE, END_DATE, AMOUNT, INT_RATE, ACCUMULATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA, DAYS_IN_YEAR, PERC_FLAGS, PERC_TYPE, TAX_RATE, CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, PERC_BANK_ACCOUNT, OFFICER_ID, START_DATE_TYPE, START_DATE_DAYS, DATE_TYPE) 
VALUES (@oid, 0, @end_date, @amount, @int_rate, @accumulate, @move_count, @move_count_type, @calc_type, '', @days_in_year, @perc_flags, @perc_type, @tax_rate, @client_account, @perc_client_account_id, @perc_bank_account_id, @user_id, @start_date_type, @start_date_days, ISNULL(@date_type, 1))
IF @@ERROR <> 0 AND @@ROWCOUNT <> 1 BEGIN RAISERROR ('ERROR INSERT DATA' ,16,1) ROLLBACK RETURN END

INSERT INTO dbo.DEPO_DATA_ANNULMENT_DETAILS (OP_ID, DAYS, PERC)
SELECT @oid, DAYS, PERC FROM dbo.DEPO_ANNULMENT_METHOD_DETAILS 
WHERE METHOD_ID = @annulment_method_id AND ISO = @iso
IF @@ERROR <> 0 BEGIN RAISERROR ('ERROR INSERT DATA' ,16,1) ROLLBACK RETURN END

UPDATE dbo.DEPO_DATA
SET FORMULA = dbo.depo_get_formula(@oid)
WHERE OP_ID = @oid
IF @@ERROR <> 0 BEGIN RAISERROR ('ERROR INSERT DATA' ,16,1) ROLLBACK RETURN END

UPDATE dbo.DEPOS
SET OP_ID = @oid
WHERE DEPO_ID = @did
IF @@ERROR <> 0 AND @@ROWCOUNT <> 1 BEGIN RAISERROR ('ERROR UPDATE DATA' ,16,1) ROLLBACK RETURN END
	
SET @depo_no = dbo.depo_get_depo_no (@did)

UPDATE dbo.DEPOS
SET DEPO_NO = @depo_no
WHERE DEPO_ID = @did

DECLARE @old_oid int
SET @old_oid = @oid

INSERT INTO dbo.DEPO_OPS (DT, OP_TYPE, OWN_DATA, AMOUNT, SELF_EXEC, COMMIT_STATE, OWNER, EXT_INT, EXT_ACC_ID, DEPO_ID)
VALUES (@start_date, 20, 1, @amount, 0, 0, @user_id, @realize_adv_acc_id, @ext_acc_id, @did)
IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN END

SET @oid = SCOPE_IDENTITY()

INSERT INTO dbo.DEPO_DATA (OP_ID,REC_STATE,AMOUNT,INT_RATE,ACCUMULATE,INC_AMOUNT,MAX_AMOUNT,OFFICER_ID,COMMENTS,END_DATE,MOVE_COUNT,MOVE_COUNT_TYPE,CALC_TYPE,FORMULA,CLIENT_ACCOUNT,PERC_CLIENT_ACCOUNT,PERC_BANK_ACCOUNT,DAYS_IN_YEAR,CALC_AMOUNT,TOTAL_CALC_AMOUNT,TOTAL_PAYED_AMOUNT,LAST_CALC_DATE,LAST_MOVE_DATE,PERC_FLAGS,PERC_TYPE,TAX_RATE,START_DATE_TYPE,START_DATE_DAYS,DATE_TYPE)
SELECT @oid,REC_STATE,AMOUNT,INT_RATE,ACCUMULATE,INC_AMOUNT,MAX_AMOUNT,OFFICER_ID,COMMENTS,END_DATE,MOVE_COUNT,MOVE_COUNT_TYPE,CALC_TYPE,FORMULA,CLIENT_ACCOUNT,PERC_CLIENT_ACCOUNT,PERC_BANK_ACCOUNT,DAYS_IN_YEAR,CALC_AMOUNT,TOTAL_CALC_AMOUNT,TOTAL_PAYED_AMOUNT,LAST_CALC_DATE,LAST_MOVE_DATE,PERC_FLAGS,PERC_TYPE,TAX_RATE,START_DATE_TYPE,START_DATE_DAYS,DATE_TYPE
FROM dbo.DEPO_DATA
WHERE OP_ID = @old_oid
IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN END

INSERT INTO dbo.DEPO_DATA_ANNULMENT_DETAILS (OP_ID, DAYS, PERC)
SELECT @oid, DAYS, PERC 
FROM dbo.DEPO_DATA_ANNULMENT_DETAILS
WHERE OP_ID = @old_oid
IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN END

DECLARE 
	@commit_state tinyint,
	@self_exec bit,
	@docs_rec_id int

SELECT @commit_state = COMMIT_STATE, @self_exec = SELF_EXEC 
FROM dbo.DEPO_OPS 
WHERE OP_ID = @oid

IF @commit_state = 0xFF BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÏÐÄÒÀÝÉÀ ÖÊÅÄ ÛÄÓÒÖËÄÁÖËÉÀ, ÂÀÍÀÀáËÄÈ ÌÏÍÀÝÄÌÄÁÉ!',16,1) END  RETURN END
IF @self_exec = 1 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÏÐÄÒÀÝÉÀ ÃÀÓÒÖËÄÁÖËÉÀ, ÂÀÍÀÀáËÄÈ ÌÏÍÀÝÄÌÄÁÉ!',16,1) END RETURN END

EXEC @r = dbo.depo_exec_op @docs_rec_id OUTPUT, @oid=@oid, @user_id=@user_id
IF @@ERROR<>0 OR @r <> 0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK END RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÉÓ ÃÒÏÓ!',16,1) RETURN END

SET @rec_id = @docs_rec_id

COMMIT

SELECT @doc_type = DOC_TYPE 
FROM dbo.OPS_0000 (NOLOCK)
WHERE REC_ID = @rec_id

SELECT @rec_id2 = @rec_id, @doc_type2 = @doc_type 

SELECT @rec_id2 = REC_ID, @doc_type2 = DOC_TYPE 
FROM dbo.OPS_0000 (NOLOCK)
WHERE PARENT_REC_ID = @rec_id AND ISNULL(OP_CODE, '') = '*%RL*'

RETURN 0
GO
