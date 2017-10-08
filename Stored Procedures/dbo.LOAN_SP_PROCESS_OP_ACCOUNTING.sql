SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_PROCESS_OP_ACCOUNTING]
	@doc_rec_id int OUTPUT,
	@op_id int,
	@user_id int,
	@doc_date smalldatetime,
	@by_processing bit = 0,
	@simulate bit = 0
AS
SET NOCOUNT ON

IF @by_processing = 1
	SET @simulate = 0

DECLARE
	@r int,
	@internal_transaction bit

SET @internal_transaction = 0
IF @simulate = 0 AND @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE
	@account_type_descrip varchar(150),
	@ovd_percent_account_bal_acc TBAL_ACC

DECLARE -- Op Data
	@loan_id int,
	@op_type smallint,
	@op_date smalldatetime,
	@op_amount TAMOUNT

SELECT
	@loan_id = LOAN_ID,
	@op_type = OP_TYPE,
	@op_date = OP_DATE,
	@op_amount = AMOUNT
FROM dbo.LOAN_OPS (NOLOCK)
WHERE OP_ID = @op_id

SELECT @r = @@ROWCOUNT
IF @@ERROR<>0 OR @r<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

IF @doc_date IS NULL
	SET @doc_date = @op_date


DECLARE -- Loan Data
	@head_branch_id int,
	@branch_id int,
	@dept_no int,
	@agreement_no varchar(100),
	@product_id int,
	@disburse_type int,
	@loan_amount TAMOUNT,
	@loan_iso TISO,
	@writeoff_date smalldatetime,
	@guarantee bit,
	@guarantee_internat bit,
	@immediate_feeing bit,
	@guarantee_purpose_code varchar(15),	
	@client_descrip varchar(100),
	@client_no int,
	@conv_only bit,
	@use_kas_amount int
	

SELECT
	@branch_id			= BRANCH_ID,
	@dept_no			= DEPT_NO,
	@agreement_no		= AGREEMENT_NO,
	@product_id			= PRODUCT_ID,
	@disburse_type		= DISBURSE_TYPE,
	@loan_amount		= AMOUNT,
	@loan_iso			= ISO,
	@writeoff_date		= WRITEOFF_DATE,
	@guarantee			= GUARANTEE,
	@guarantee_internat	= INTERNAT_GUARANTEE,
	@immediate_feeing	= IMMEDIATE_FEEING
FROM dbo.LOANS (NOLOCK)
WHERE LOAN_ID = @loan_id
SET @r = @@ROWCOUNT
IF @@ERROR<>0 OR @r<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

SET @client_descrip = Null

SET @conv_only = 0

IF @guarantee = 0
	SET @immediate_feeing = 0

IF @guarantee = 1
BEGIN
	SELECT 
		@client_descrip = C.DESCRIP,
		@client_no = C.CLIENT_NO,
		@guarantee_purpose_code = ISNULL(LPT.CODE, '')
	FROM dbo.LOANS L (NOLOCK)
		INNER JOIN dbo.CLIENTS C (NOLOCK) ON L.CLIENT_NO = C.CLIENT_NO
		LEFT JOIN dbo.LOAN_PURPOSE_TYPES LPT ON L.PURPOSE_TYPE = LPT.[TYPE_ID]
	WHERE L.LOAN_ID = @loan_id
END

CREATE TABLE #docs(
	[REC_ID]		int PRIMARY KEY NOT NULL IDENTITY (1,1),
	[DOC_DATE]		smalldatetime	NOT NULL,
	[DEBIT_ID]		int,
	[DEBIT]			decimal(15,0)	NOT NULL,
	[CREDIT_ID]		int,
	[CREDIT]		decimal(15,0)	NOT NULL,
	[ISO]			char(3)			NOT NULL,
	[AMOUNT]		money			NOT NULL,
	[ISO2]			char(3)			NULL,
	[AMOUNT2]		money			NULL,
	[DOC_TYPE]		smallint		NOT NULL,
	[OP_CODE]		char(5)			collate database_default NOT NULL,
	[DESCRIP]		varchar(150)	collate database_default NOT NULL,
	[FOREIGN_ID]	int				NULL,
	[TYPE_ID]		int				NOT NULL,
	[CHECK_SALDO]	bit				NOT NULL DEFAULT 1)

DECLARE
	@doc_rec_id2	int,	
	@doc_num		int,
	@debit_id		int,
	@debit			TACCOUNT,
	@credit_id		int,
	@credit			TACCOUNT,
	@iso			TISO,
	@amount			TAMOUNT,
	@iso2			TISO,
	@amount2		TAMOUNT,
	@doc_type		smallint,
	@op_code		TOPCODE,
	@rec_state		tinyint,
	@descrip		TDESCRIP,
	@foreign_id		int,
	@type_id		int,
	@check_saldo	bit,
	@is_incasso		bit,
	@acc_rec_state	tinyint


DECLARE
	@l_technical_999 TACCOUNT,
	@l_technical_999_id int,
	@l_overdue_all int,
	@l_overdue_noacc int,
	@l_rsrv_chng_disb int,
	@l_rsrv_chng_ctgr int,
	@l_rsrv_chng_paym int

SET @iso2 = NULL
SET @amount2 = NULL
SET @doc_rec_id2 = NULL


DECLARE
	@template_41	varchar(150),
	@account_41		TACCOUNT,
	@acc_id_41		int,
	@type_id_41		int


IF EXISTS(SELECT * FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = 8000)
	SELECT @template_41 = TEMPLATE FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = 8000
ELSE
	SELECT @template_41 = TEMPLATE FROM dbo.LOAN_COMMON_ACCOUNT_TEMPLATES (NOLOCK) WHERE ACC_TYPE_ID = 8000

DECLARE
	@template_85	varchar(150),
	@account_85		TACCOUNT,
	@acc_id_85		int,
	@type_id_85		int


IF EXISTS(SELECT * FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = 9000)
	SELECT @template_85 = TEMPLATE FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = 9000
ELSE
	SELECT @template_85 = TEMPLATE FROM dbo.LOAN_COMMON_ACCOUNT_TEMPLATES (NOLOCK) WHERE ACC_TYPE_ID = 9000


EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO', @head_branch_id OUTPUT	--ÓÀÈÀÏ ×ÉËÉÀËÉÓ ÍÏÌÄÒÉ

EXEC dbo.GET_SETTING_INT 'L_TECHNICAL_999', @l_technical_999 OUTPUT	--ÔÄØÍÉÊÖÒÉ ÀÍÂÀÒÉÛÉ ÂÀÒÄÁÀËÀÍÓÄÁÉÓÈÅÉÓ
SET @l_technical_999_id = dbo.acc_get_acc_id(@head_branch_id, @l_technical_999, @loan_iso)

EXEC dbo.GET_SETTING_INT 'L_RSRV_CHNG_DISB', @l_rsrv_chng_disb OUTPUT --ÂÀÔÀÒÃÄÓ ÈÖ ÀÒÀ ÒÄÆÄÒÅÉÓ ÃÀÒÉÝáÅÉÓ ÓÀÁÖÈÄÁÉ ÂÀÝÄÌÉÓ ÃÒÏÓ

EXEC dbo.GET_SETTING_INT 'L_RSRV_CHNG_CTGR', @l_rsrv_chng_ctgr OUTPUT --ÂÀÔÀÒÃÄÓ ÈÖ ÀÒÀ ÒÄÆÄÒÅÉÓ ÃÀÒÉÝáÅÉÓ ÓÀÁÖÈÄÁÉ ÒÄÆÄÒÅÉÓ ÒÄÓÔÒÖØÔÖÒÉÆÀÝÉÉÓ/ÝÅËÉËÄÁÉÓ ÃÒÏÓ

EXEC dbo.GET_SETTING_INT 'L_RSRV_CHNG_PAYM', @l_rsrv_chng_paym OUTPUT --ÂÀÔÀÒÃÄÓ ÈÖ ÀÒÀ ÒÄÆÄÒÅÉÓ ÃÀÒÉÝáÅÉÓ ÓÀÁÖÈÄÁÉ ÃÀ×ÀÒÅÉÓ ÃÒÏÓ


IF @by_processing = 1
	SET @rec_state = 20
ELSE
	SELECT @rec_state = DOC_REC_STATE FROM dbo.LOAN_OP_TYPES (NOLOCK) WHERE [TYPE_ID] = @op_type


DECLARE
	@l_approve_0301 int

EXEC dbo.GET_SETTING_INT 'L_APPROVE_0301', @l_approve_0301 OUTPUT


DECLARE
	@acc_id		int,
	@acc_added	bit,
	@bal_acc	TBAL_ACC

IF (@guarantee = 0) AND (@op_type = dbo.loan_const_op_approval()) -- ÓÄÓáÉÓ ÃÀÌÔÊÉÝÄÁÀ
BEGIN
	IF (@l_approve_0301 = 1) 
	BEGIN
		IF @simulate = 1 GOTO ret_select
		
		SET @debit_id = @l_technical_999_id
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
 		SET @debit = @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 10,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		SET @iso			= @loan_iso
		SET @amount			= @op_amount
		SET @doc_type		= 245
		SET @op_code		= '*LNP+'
		SET @descrip		= 'ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÀÙÉÀÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

		SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id
		SET @type_id		= 10
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	EXEC @r = dbo.loan_process_collateral_accounting
		@op_id = @op_id,
		@user_id = @user_id,
		@doc_date = @doc_date,
		@head_branch_id = @head_branch_id,
		@l_technical_999 = @l_technical_999,
		@only_close = 0,
		@by_processing = @by_processing,
		@simulate = @simulate
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END
ELSE
IF @op_type = dbo.loan_const_op_disburse()  -- ÓÄÓáÉÓ ÂÀÝÄÌÀ
BEGIN
	SELECT @use_kas_amount = USE_KAS_AMOUNT
	FROM dbo.LOAN_PRODUCTS (NOLOCK)
	WHERE PRODUCT_ID = @product_id
	
	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 30,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @credit_id OUTPUT,
		@account	= @credit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 20,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @iso			= @loan_iso
	SET @amount			= @op_amount
	SET @doc_type		= 45
	SET @op_code		= CASE WHEN @use_kas_amount = 1 THEN '*LP+' ELSE '*LP1+' END
	SET @descrip		= 'ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÂÀÝÄÌÀ (áÄËÛ. ' + @agreement_no + ')'
	SET @foreign_id		= NULL
	SET @type_id		= 30
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SELECT @amount = ISNULL(ADMIN_FEE, $0.00)
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id
	
	IF @amount > $0.00
	BEGIN
		SET @debit = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1000,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @doc_type		= 45
		SET @op_code		= '*LA+'
		SET @descrip		= 'ÀÃÌÉÍÉÓÔÒÀÝÉÖËÉ ÂÀÃÀÓÀáÀÃÉÓ ÀÙÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 1000
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	SET @debit = NULL
	SET @credit = NULL

	IF (@l_approve_0301 = 0)
	BEGIN
		IF @disburse_type IN (2, 4)
		BEGIN
			SET @amount = @loan_amount - @op_amount
			IF @amount > $0.00
			BEGIN
				SET @debit_id = @l_technical_999_id
				IF @debit_id IS NULL
				BEGIN
					SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
					RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
					BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
				END

 				SET @debit = @l_technical_999
				
				EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
					@acc_id		= @credit_id OUTPUT,
					@account	= @credit OUTPUT,
					@acc_added	= @acc_added OUTPUT,
					@bal_acc	= @bal_acc OUTPUT,
					@type_id	= 10,
					@loan_id	= @loan_id,
					@iso		= @loan_iso,
					@user_id	= @user_id,
					@simulate	= @simulate,
					@guarantee	= @guarantee
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

				SET @iso			= @loan_iso
				SET @doc_type		= 245
				SET @op_code		= '*LNP+'
				SET @descrip		= 'ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÀÙÉÀÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

				SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id
				SET @type_id = 10
				SET @check_saldo	= 0

				INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
				VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
				IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
			END
		END
	END
	ELSE 
	BEGIN
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 10,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
 		
		SET @credit_id = @l_technical_999_id
		IF @credit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @credit			= @l_technical_999
		SET @iso			= @loan_iso
		SET @amount			= @op_amount
		SET @doc_type		= 245
		SET @op_code		= '*LNP-'
		SET @descrip		= 'ÀÙÉÀÒÄÁÖËÉ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

		SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id

		SET @type_id		= -10
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	/*IF @l_rsrv_chng_disb = 1
	BEGIN
		EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
			@accrue_date					= @doc_date,
			@loan_id						= @loan_id,
			@user_id						= @user_id,
			@create_table					= 0,
			@simulate						= @simulate
		
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END*/
END
ELSE
IF @op_type = dbo.loan_const_op_disburse_transh()  -- ÓÄÓáÉÓ ÂÀÝÄÌÀ (ÔÒÀÍÛÉ)
BEGIN
	SELECT @use_kas_amount = USE_KAS_AMOUNT
	FROM dbo.LOAN_PRODUCTS (NOLOCK)
	WHERE PRODUCT_ID = @product_id

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 30,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @credit_id OUTPUT,
		@account	= @credit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 20,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @iso			= @loan_iso
	SET @amount			= @op_amount
	SET @doc_type		= 45
	SET @op_code		= CASE WHEN @use_kas_amount = 1 THEN '*LP+' ELSE '*LP1+' END
	SET @descrip		= 'ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÂÀÝÄÌÀ (áÄËÛ. ' + @agreement_no + ')'
	SET @foreign_id		= NULL
	SET @type_id		= 30
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @debit = NULL
	SET @credit = NULL

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 10,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	
	SET @credit_id = @l_technical_999_id
	IF @credit_id IS NULL
	BEGIN
		SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
		RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
		BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	SET @credit			= @l_technical_999
	SET @iso			= @loan_iso
	SET @amount			= @op_amount
	SET @doc_type		= 245
	SET @op_code		= '*LNP-'
	SET @descrip		= 'ÀÙÉÀÒÄÁÖËÉ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

	SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id

	SET @type_id		= -10
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	/*IF @l_rsrv_chng_disb = 1
	BEGIN
		EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
			@accrue_date					= @doc_date,
			@loan_id						= @loan_id,
			@user_id						= @user_id,
			@create_table					= 0,
			@simulate						= @simulate
		
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END*/
END
ELSE
IF @op_type = dbo.loan_const_op_stop_disburse()  -- ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÀÈÅÉÓÄÁÉÓ ÛÄßÚÅÄÔÀ
BEGIN
	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 10,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @credit_id = @l_technical_999_id
	IF @credit_id IS NULL
	BEGIN
		SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
		RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
		BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	SET @credit			= @l_technical_999
	SET @iso			= @loan_iso
	SET @amount			= @op_amount
	SET @doc_type		= 245
	SET @op_code		= '*LNP-'
	SET @descrip		= 'ÀÙÉÀÒÄÁÖËÉ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

	SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id

	SET @type_id		= -10
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END
ELSE
IF @op_type = dbo.loan_const_op_dec_disburse()
BEGIN
DECLARE
	@nu_amount_delta money


	SELECT @nu_amount_delta  = ISNULL(LOAN_NU_AMOUNT_DELTA, $0.00)
	FROM dbo.LOAN_VW_LOAN_OP_DEC_DISBURSE
	WHERE OP_ID = @op_id

	IF SIGN(@nu_amount_delta) = -1
	BEGIN
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 10,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @credit_id = @l_technical_999_id
		IF @credit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @credit = @l_technical_999
		SET @op_code		= '*LNP-'
		SET @descrip		= 'ÀÙÉÀÒÄÁÖËÉ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

		SET @type_id		= -10
	END
	ELSE
	BEGIN
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @credit_id OUTPUT,
		@account	= @credit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 10,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit_id = @l_technical_999_id
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @debit = @l_technical_999
		SET @op_code		= '*LNP+'
		SET @descrip		= 'ÀÙÉÀÒÄÁÖËÉ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÂÀÆÒÃÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @type_id		= 10
	END

	SET @iso			= @loan_iso
	SET @amount			= ABS(@nu_amount_delta)
	SET @doc_type		= 245
	SET @check_saldo	= 0

	SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END
ELSE
IF @op_type = dbo.loan_const_op_overdue()  -- ÓÄÓáÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ
BEGIN
	EXEC dbo.GET_SETTING_INT 'L_OVERDUE_ALL', @l_overdue_all OUTPUT
	EXEC dbo.GET_SETTING_INT 'L_OVERDUE_NOACC', @l_overdue_noacc OUTPUT

	DECLARE
		@principal_balance	TAMOUNT,
		@overdue_percent	TAMOUNT,
		@overdue_principal	TAMOUNT,
		@overdue_defered_interest TAMOUNT
	
	SELECT @principal_balance = ISNULL(PRINCIPAL_BALANCE, $0.00)
	FROM dbo.LOAN_ACCOUNT_BALANCE
	WHERE LOAN_ID = @loan_id

	SELECT 
		@overdue_percent = ISNULL(OVERDUE_PERCENT, $0.00), 
		@overdue_principal = ISNULL(OVERDUE_PRINCIPAL, $0.00),
		@overdue_defered_interest = ISNULL(OVERDUE_DEFERED_INTEREST, $0.00)
	FROM dbo.LOAN_VW_LOAN_OP_OVERDUE
	WHERE OP_ID = @op_id

	IF @overdue_principal > $0.00
	BEGIN
		IF @l_overdue_noacc = 0
		BEGIN 
			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @debit_id OUTPUT,	
				@account	= @debit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 40,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 30,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= @loan_iso
			SET @amount			= CASE WHEN @l_overdue_all = 1 THEN @principal_balance ELSE @overdue_principal END
			SET @doc_type		= 45
			SET @op_code		= '*LOP+'
			SET @descrip		= 'ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= 40
			SET @check_saldo	= 1

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
	END

	IF @overdue_percent + @overdue_defered_interest > $0.00
	BEGIN
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1130,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1030,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @overdue_percent + @overdue_defered_interest
		SET @doc_type		= 45
		IF @guarantee = 0 
		BEGIN
			SET @op_code		= '*LI-'
			SET @descrip		= 'ÃÀÒÉÝáÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		END
		ELSE
		BEGIN
			SET @op_code		= '*GI-'
			IF @guarantee_internat = 1
				SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÓÀÊÏÌÉÓÉÏÓ (ÅÀÃÉÀÍÉ) ÂÀÃÀÔÀÍÀ ÅÀÃÀÂÀÃÀÝÉËÄÁÀÆÄ'
			ELSE
				SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip +  ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÓÀÊÏÌÉÓÉÏÓ (ÅÀÃÉÀÍÉ) ÂÀÃÀÔÀÍÀ ÅÀÃÀÂÀÃÀÝÉËÄÁÀÆÄ'
		END
		SELECT @foreign_id = CONVERT(int, INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id

		SET @type_id		= -1030
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @ovd_percent_account_bal_acc OUTPUT,
			@type_id	= 60,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		IF @ovd_percent_account_bal_acc > 999.99
		BEGIN 
			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 1160,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @doc_type		= 45
		END
		ELSE
		BEGIN
			SET @credit_id = @l_technical_999_id
			IF @credit_id IS NULL
			BEGIN
				SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
				RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
				BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
			END

			SET @credit			= @l_technical_999
			SET @doc_type		= 240
		END

		SET @iso			= @loan_iso
		SET @amount			= @overdue_percent + @overdue_defered_interest
		IF @guarantee = 0
		BEGIN
			SET @op_code		= '*LOI+'
			SET @descrip		= 'ÃÀÒÉÝáÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		END
		ELSE
		BEGIN
			SET @op_code		= '*GOI+'
			IF @guarantee_internat = 1
				SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÌÉáÄÃÅÉÈ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÖËÉ ÛÄÌÏÓÀÅËÉÓ ÀÙÉÀÒÄÁÀ'
			ELSE
				SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip +  ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÌÉáÄÃÅÉÈ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÖËÉ ÛÄÌÏÓÀÅËÉÓ ÀÙÉÀÒÄÁÀ'
		END

		SELECT @foreign_id = CONVERT(int, OVERDUE_INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id

		SET @type_id		= 1160
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
	/*IF @l_rsrv_chng_ctgr = 1
	BEGIN
		EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
			@accrue_date					= @doc_date,
			@loan_id						= @loan_id,
			@user_id						= @user_id,
			@create_table					= 0,
			@simulate						= @simulate
		
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END*/
END
ELSE
IF @op_type = dbo.loan_const_op_overdue_revert()  -- ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÄÓáÉÓ ÒÄÊËÀÓÉ×ÉÊÀÝÉÀ ÒÏÂÏÒÝ ÜÅÄÖËÄÁÒÉÅÉÓÀ
BEGIN
	EXEC dbo.GET_SETTING_INT 'L_OVERDUE_ALL', @l_overdue_all OUTPUT
	EXEC dbo.GET_SETTING_INT 'L_OVERDUE_NOACC', @l_overdue_noacc OUTPUT
	
	IF @l_overdue_noacc = 0
	BEGIN
		DECLARE
			@overdue_principal_balance TAMOUNT
		
		SELECT @overdue_principal_balance = ISNULL(OVERDUE_PRINCIPAL_BALANCE, $0.00)
		FROM dbo.LOAN_ACCOUNT_BALANCE
		WHERE LOAN_ID = @loan_id
	
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 30, 
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 40,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @overdue_principal_balance
		SET @doc_type		= 45
		SET @op_code		= '*LOP-'
		SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÄÓáÉÓ ÒÄÊËÀÓÉ×ÉÊÀÝÉÀ ÒÏÂÏÒÝ ÜÅÄÖËÄÁÒÉÅÉÓÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL

		SET @type_id		= -40
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		/*IF @l_rsrv_chng_ctgr = 1
		BEGIN
			EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
				@accrue_date					= @doc_date,
				@loan_id						= @loan_id,
				@user_id						= @user_id,
				@create_table					= 0,
				@simulate						= @simulate
			
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END*/
	END	
END
ELSE
/*IF @op_type = dbo.loan_const_op_restructure_risks() -- ÓÄÓáÉÓ ÒÉÓÊÄÁÉÓ ÒÄÓÔÒÖØÔÖÒÉÆÀÝÉÀ
BEGIN
	IF @l_rsrv_chng_ctgr = 1
	BEGIN
		EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
			@accrue_date					= @doc_date,
			@loan_id						= @loan_id,
			@user_id						= @user_id,
			@create_table					= 0,
			@simulate						= @simulate
		
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END
ELSE
IF @op_type = dbo.loan_const_op_individual_risks() -- ÓÄÓáÉÓ ÒÄÆÄÒÅÉÓ ÛÄÝÅËÀ
BEGIN
	IF @l_rsrv_chng_ctgr = 1
	BEGIN
		EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
			@accrue_date					= @doc_date,
			@loan_id						= @loan_id,
			@user_id						= @user_id,
			@create_table					= 0,
			@simulate						= @simulate
		
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END
ELSE*/
IF @op_type = dbo.loan_const_op_payment_writedoff() -- ÜÀÌÏßÄÒÉËÉ ÓÄÓáÉÓ ÃÀ×ÀÒÅÀ
BEGIN
	DECLARE
		@payment_writeoff_principal TAMOUNT,
		@payment_writeoff_principal_penalty TAMOUNT,
		@payment_writeoff_percent TAMOUNT,
		@payment_writeoff_percent_penalty TAMOUNT,
		@payment_writeoff_penalty TAMOUNT

	SELECT @payment_writeoff_principal = WRITEOFF_PRINCIPAL,
		@payment_writeoff_principal_penalty = WRITEOFF_PRINCIPAL_PENALTY,
		@payment_writeoff_percent = WRITEOFF_PERCENT,
		@payment_writeoff_percent_penalty = WRITEOFF_PERCENT_PENALTY,
		@payment_writeoff_penalty = WRITEOFF_PENALTY
	FROM dbo.LOAN_VW_LOAN_OP_PAYMENT_WRITEDOFF
	WHERE OP_ID = @op_id

	SET @payment_writeoff_penalty = ISNULL(@payment_writeoff_principal_penalty, $0.00) + ISNULL(@payment_writeoff_percent_penalty, $0.00) + ISNULL(@payment_writeoff_penalty, $0.00)

	IF ISNULL(@payment_writeoff_principal, $0.00) <> 0
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		

		SELECT 
			@is_incasso = IS_INCASSO,
			@acc_rec_state = REC_STATE
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @debit_id
		
		IF @is_incasso = 1
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK
			RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÀÃÄÅÓ ÉÍÊÀÓÏ, ÃÀ×ÀÒÅÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
			RETURN 101
		END

		IF @acc_rec_state <> 1
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK
			RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÓÔÀÔÖÓÉÓ ÂÀÌÏ ÃÀ×ÀÒÅÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
			RETURN 101
		END


		IF @loan_iso = 'GEL'
		BEGIN
			IF (@template_41 IS NOT NULL)
			BEGIN
				SET @type_id_41 = 8000
				EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
					@acc_id		= @acc_id_41 OUTPUT,
					@account	= @account_41 OUTPUT,
					@acc_added	= @acc_added OUTPUT,
					@bal_acc	= @bal_acc OUTPUT,
					@type_id	= 8000,
					@loan_id	= @loan_id,
					@iso		= 'GEL',
					@user_id	= @user_id,
					@simulate	= @simulate,
					@guarantee	= @guarantee
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
			END
			ELSE
			BEGIN
				SET @type_id_41 = 8050
				EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
					@acc_id		= @acc_id_41 OUTPUT,
					@account	= @account_41 OUTPUT,
					@acc_added	= @acc_added OUTPUT,
					@bal_acc	= @bal_acc OUTPUT,
					@type_id	= 8050,
					@loan_id	= @loan_id,
					@iso		= 'GEL',
					@user_id	= @user_id,
					@simulate	= @simulate,
					@guarantee	= @guarantee
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
			END


			SET	@credit_id = @acc_id_41
			SET @credit = @account_41

			SET @iso			= 'GEL'
			SET @amount			= @payment_writeoff_principal
			SET @doc_type		= 45
			SET @op_code		= '*LR6-'
			SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= 0--@type_id_41
			SET @check_saldo	= 1

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @amount2 = @payment_writeoff_principal

		END
		ELSE
		BEGIN
			SET @iso2 = 'GEL'
			EXEC @r = dbo.GET_CROSS_AMOUNT
				@iso1			= @loan_iso,
				@iso2			= @iso2,
				@amount 		= @payment_writeoff_principal,
				@dt				= @writeoff_date,
				@new_amount 	= @amount2 OUTPUT	
			IF @r <> 0 OR @@ERROR <> 0	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1001 END


			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 170,
				@loan_id	= @loan_id,
				@iso		= 'GEL',
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= @loan_iso
			SET @amount			= @amount2
			SET @doc_type		= 98
			SET @op_code		= '*LW-'
			SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÞÉÒÉÈÀÃÉÓ ÃÀ×ÀÒÅÀ(áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= 0
			SET @check_saldo	= 1

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, ISO2, AMOUNT2, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @payment_writeoff_principal, @iso2, @amount2, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


			SET @debit_id = @credit_id
			SET @debit = @credit
			SET @credit_id = NULL
			SET @credit = NULL


			IF (@template_41 IS NOT NULL)
			BEGIN
				SET @type_id_41 = 8000
				EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
					@acc_id		= @acc_id_41 OUTPUT,
					@account	= @account_41 OUTPUT,
					@acc_added	= @acc_added OUTPUT,
					@bal_acc	= @bal_acc OUTPUT,
					@type_id	= 8000,
					@loan_id	= @loan_id,
					@iso		= 'GEL',
					@user_id	= @user_id,
					@simulate	= @simulate,
					@guarantee	= @guarantee
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
			END
			ELSE
			BEGIN
				SET @type_id_41 = 8050
				EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
					@acc_id		= @acc_id_41 OUTPUT,
					@account	= @account_41 OUTPUT,
					@acc_added	= @acc_added OUTPUT,
					@bal_acc	= @bal_acc OUTPUT,
					@type_id	= 8050,
					@loan_id	= @loan_id,
					@iso		= 'GEL',
					@user_id	= @user_id,
					@simulate	= @simulate,
					@guarantee	= @guarantee
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
			END

			SET	@credit_id = @acc_id_41
			SET @credit = @account_41

			SET @iso			= 'GEL'
			SET @amount			= @amount2
			SET @doc_type		= 45
			SET @op_code		= '*LR6-'
			SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÞÉÒÉÈÀÃÉÓ ÃÀ×ÀÒÅÀ(áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= 0
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		

		IF (@template_85 IS NOT NULL)
		BEGIN
			SET @type_id_85 = 9000
			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @acc_id_85 OUTPUT,
				@account	= @account_85 OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 9000,
				@loan_id	= @loan_id,
				@iso		= 'GEL',
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		ELSE
		BEGIN
			SET @type_id_85 = 9050
			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @acc_id_85 OUTPUT,
				@account	= @account_85 OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 9050,
				@loan_id	= @loan_id,
				@iso		= 'GEL',
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @debit = @account_41
		SET @debit_id = @acc_id_41
		SET @credit = @account_85
		SET @credit_id = @acc_id_85


		SET @iso			= 'GEL'
		SET @amount			= @amount2
		SET @doc_type		= 95
		SET @op_code		= '*LRW'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÓÄÓáÉÓ ÒÄÆÄÒÅÉÓ áÀÒãÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 0
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		SET @debit_id = @l_technical_999_id
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @debit	= @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 50,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_writeoff_principal
		SET @doc_type		= 245
		SET @op_code		= '*LW-'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'

		SELECT @foreign_id	= NULL
		SET @type_id		= -50
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF ISNULL(@payment_writeoff_penalty, $0.00) <> 0
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2100,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_writeoff_penalty
		SET @doc_type		= 98
		SET @op_code		= '*LWI-'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ãÀÒÉÌÉÓ ÃÀ×ÀÒÅÀ(áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 0
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		SET @debit_id = @l_technical_999_id 
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @debit	= @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 80,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @payment_writeoff_penalty
		SET @doc_type		= 240
		SET @op_code		= '*LWI-'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ãÀÒÉÌÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 0
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF ISNULL(@payment_writeoff_percent, $0.00) <> 0
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1170,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_writeoff_percent
		SET @doc_type		= 98
		SET @op_code		= '*LWI-'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÃÀ×ÀÒÅÀ(áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 0
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		SET @debit_id = @l_technical_999_id 
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @debit	= @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 70,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @payment_writeoff_percent
		SET @doc_type		= 240
		SET @op_code		= '*LWI-'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 0
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END
ELSE
IF @op_type = dbo.loan_const_op_payment() -- ÓÄÓáÉÓ ÃÀ×ÀÒÅÀ
BEGIN
	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 20,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SELECT 
		@is_incasso = IS_INCASSO,
		@acc_rec_state = REC_STATE
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @debit_id
	
	IF @is_incasso = 1
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK
		RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÀÃÄÅÓ ÉÍÊÀÓÏ, ÃÀ×ÀÒÅÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
		RETURN 101
	END

	IF @acc_rec_state <> 1
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK
		RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÓÔÀÔÖÓÉÓ ÂÀÌÏ ÃÀ×ÀÒÅÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
		RETURN 101
	END

	DECLARE
		@rate_diff money,
		@payment_interest money,
		@payment_principal money,
		@payment_prepayment_penalty money,
		@payment_overdue_principal money,
		@payment_overdue_percent money,
		@payment_overdue_percent30 money,
		@payment_penalty money,
		@payment_nu_principal money,
		@insurance money,
		@service_fee money,
		@payment_defered_interest money,
		@payment_defered_penalty money
		

	SELECT
		@rate_diff = ISNULL(RATE_DIFF, $0.00),
		@payment_nu_principal = ISNULL(PRINCIPAL, $0.00) + ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(OVERDUE_PRINCIPAL, $0.00),
		@payment_interest = ISNULL(INTEREST, $0.00) + ISNULL(NU_INTEREST, $0.00) + ISNULL(OVERDUE_PRINCIPAL_INTEREST, $0.00),
		@payment_principal = ISNULL(PRINCIPAL, $0.00),
		@payment_prepayment_penalty = ISNULL(PREPAYMENT_PENALTY, $0.00),
		@payment_overdue_principal = ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(OVERDUE_PRINCIPAL, $0.00),
		@payment_overdue_percent = ISNULL(LATE_PERCENT, $0.00) + ISNULL(OVERDUE_PERCENT, $0.00),
		@payment_penalty = ISNULL(OVERDUE_PERCENT_PENALTY, $0.00) + ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00),
		@insurance = ISNULL(INSURANCE, $0.00),
		@service_fee = ISNULL(SERVICE_FEE, $0.00),
		@payment_defered_interest = ISNULL(DEFERED_INTEREST, $0.00),
		@payment_defered_penalty = ISNULL(DEFERED_PENALTY, $0.00)
	FROM dbo.LOAN_VW_LOAN_OP_PAYMENT_DETAILS
	WHERE OP_ID = @op_id

	SELECT @payment_overdue_percent30 = ISNULL(OVERDUE_INTEREST30_BALANCE, $0.00)
	FROM dbo.LOAN_ACCOUNT_BALANCE
	WHERE LOAN_ID = @loan_id

	IF @payment_overdue_percent > $0.00
	BEGIN
		IF @payment_overdue_percent >= @payment_overdue_percent30
			SET @payment_overdue_percent = @payment_overdue_percent - @payment_overdue_percent30
		ELSE
		BEGIN
			SET @payment_overdue_percent30 = @payment_overdue_percent
			SET @payment_overdue_percent = $0.00
		END
	END
	ELSE SET @payment_overdue_percent30 = $0.00

	IF @payment_principal <> $0.00 -- ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÂÀÃÀáÃÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END



		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 30,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_principal
		SET @doc_type		= 45
		SET @op_code		= '*LP-'
		SET @descrip		= 'ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= -30
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_overdue_principal <> $0.00 -- ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÂÀÃÀáÃÀ
	BEGIN
		DECLARE
			@overdue_account_balance_18 money,
			@overdue_account_balance_19 money
			
		SET @overdue_account_balance_18 = $0.00
		SET @overdue_account_balance_19 = $0.00
	
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL
		
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC dbo.GET_SETTING_INT 'L_OVERDUE_NOACC', @l_overdue_noacc OUTPUT
		
		IF @l_overdue_noacc = 1
		BEGIN
			SELECT @credit_id = ACC_ID
			FROM dbo.LOAN_ACCOUNTS (NOLOCK)
			WHERE LOAN_ID = @loan_id AND ACCOUNT_TYPE = 40
			
			IF @credit_id IS NULL
			BEGIN
				EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
					@acc_id		= @credit_id OUTPUT,
					@account	= @credit OUTPUT,
					@acc_added	= @acc_added OUTPUT,
					@bal_acc	= @bal_acc OUTPUT,
					@type_id	= 30, -- ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÈÀÍáÀ ÀÉÙÏÓ 18-ÃÀÍ
					@loan_id	= @loan_id,
					@iso		= @loan_iso,
					@user_id	= @user_id,
					@simulate	= @simulate,
					@guarantee	= @guarantee
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
			END
			ELSE
			BEGIN
				EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
					@acc_id		= @credit_id OUTPUT,
					@account	= @credit OUTPUT,
					@acc_added	= @acc_added OUTPUT,
					@bal_acc	= @bal_acc OUTPUT,
					@type_id	= 40,
					@loan_id	= @loan_id,
					@iso		= @loan_iso,
					@user_id	= @user_id,
					@simulate	= @simulate,
					@guarantee	= @guarantee
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

				SET @overdue_account_balance_19 = dbo.acc_get_balance(@credit_id, @doc_date, 0, 0, 1)

				IF @overdue_account_balance_19 > $0.00
				BEGIN
					SET @overdue_account_balance_18 = @payment_overdue_principal - @overdue_account_balance_19
					SET @payment_overdue_principal = @overdue_account_balance_19
				END
			END
		END
		ELSE
		BEGIN
			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 40,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END	

		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_principal
		SET @doc_type		= 45
		SET @op_code		= '*LOP-'
		SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= -40
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		
		IF @overdue_account_balance_18 <> $0.00
		BEGIN
			SET @debit_id = NULL
			SET @debit = NULL
			SET @credit_id = NULL
			SET @credit = NULL

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @debit_id OUTPUT,
				@account	= @debit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 20,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END



			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 30,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= @loan_iso
			SET @amount			= @overdue_account_balance_18
			SET @doc_type		= 45
			SET @op_code		= '*LP-'
			SET @descrip		= 'ÃÀÂÅÉÀÍÄÁÖËÉ ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= -30
			SET @check_saldo	= 1

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
	END

	IF @payment_interest <> $0.00 --ÐÒÏÝÄÍÔÉÓ ÂÀÃÀáÃÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1030,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_interest
		SET @doc_type		= 45
		SET @op_code		= '*LI-'
		SET @descrip		= 'ÃÀÒÉÝáÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -1030
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_defered_interest <> $0.00 --ÂÀÃÀÅÀÃÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÂÀÃÀáÃÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1030,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_defered_interest
		SET @doc_type		= 45
		SET @op_code		= '*DLI-'
		SET @descrip		= 'ÂÀÃÀÅÀÃÄÁÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -1030
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_overdue_percent <> $0.00 --ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÂÀÃÀáÃÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 60,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_percent
		SET @doc_type		= 45
		SET @op_code		= '*LOI-'
		SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, OVERDUE_INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -1160
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_overdue_percent30 <> $0.00 -- 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÃÀ×ÀÒÅÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 60,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1160,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_percent30
		SET @doc_type		= 45
		SET @op_code		= '*LOI+'
		SET @descrip		= '30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÉÈ ÌÉÖÙÄÁÄËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÀÙÃÂÄÍÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 1160
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		SET @debit_id = @l_technical_999_id 
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @debit	= @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2060,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_percent30
		SET @doc_type		= 240
		SET @op_code		= '*LOI-'
		SET @descrip		= '30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÉÈ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, OVERDUE_INTEREST30_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -2060
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 60,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_percent30
		SET @doc_type		= 45
		SET @op_code		= '*LOI-'
		SET @descrip		= '30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÉÈ ÌÉÖÙÄÁÄËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= -1160
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_penalty <> $0.00 -- ÓÄÓáÆÄ ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÃÀ×ÀÒÅÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2100,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_penalty
		SET @doc_type		= 45
		SET @op_code		= '*LPII'
		SET @descrip		= 'ÓÄÓáÆÄ ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 2100
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		SET @debit_id = @l_technical_999_id 
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @debit	= @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2000,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @payment_penalty
		SET @doc_type		= 240
		SET @op_code		= '*LPI-'
		SET @descrip		= 'ÓÄÓáÆÄ ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, PENALTY_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -2000
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_defered_penalty <> $0.00 -- ÂÀÃÀÅÀÃÄÁÖËÉ ãÀÒÉÌÉÓ ÃÀ×ÀÒÅÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2100,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_defered_penalty
		SET @doc_type		= 45
		SET @op_code		= '*LPII'
		SET @descrip		= 'ÓÄÓáÆÄ ÂÀÃÀÅÀÃÄÁÖËÉ ãÀÒÉÌÉÓ ÃÀ×ÀÒÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 2100
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		SET @debit_id = @l_technical_999_id 
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @debit	= @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2000,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @payment_defered_penalty
		SET @doc_type		= 240
		SET @op_code		= '*LPI-'
		SET @descrip		= 'ÓÄÓáÆÄ ÃÀÒÉÝáÖËÉ ÂÀÃÀÅÀÃÄÁÖËÉ ãÀÒÉÌÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, PENALTY_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -2000
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_prepayment_penalty <> $0.00 -- ßÉÍÓßÒÄÁÉÓ ÓÀÊÏÌÉÓÉÏÓ ÂÀÃÀáÃÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 3000,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_prepayment_penalty
		SET @doc_type		= 45
		SET @op_code		= '*PPA+'
		SET @descrip		= 'ÓÀÊÏÌÉÓÉÏ ßÉÍÓßÒÄÁÉÈ ÃÀ×ÀÒÅÀÆÄ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 3000
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @rate_diff <> $0.00 -- ÓÀÊÖÒÓÏ ÓáÅÀÏÁÉÈ ÌÉÙÄÁÖËÉ ÛÄÌÏÓÀÅËÄÁÉ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 4000,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @rate_diff
		SET @doc_type		= 98
		SET @op_code		= '*RDFF'
		SET @descrip		= 'ÓÀÊÖÒÓÏ ÓáÅÀÏÁÉÈ ÌÉÙÄÁÖËÉ ÛÄÌÏÓÀÅËÄÁÉ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 4000
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @insurance <> $0.00 -- ÃÀÆÙÅÄÅÉÓ ÐÒÄÌÉÀÒÖËÉ ÂÀÃÀÓÀáÀÃÉ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 5000,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @insurance
		SET @doc_type		= 98
		SET @op_code		= '*INSU'
		SET @descrip		= 'ÃÀÆÙÅÄÅÉÓ ÐÒÄÌÉÀÒÖËÉ ÂÀÃÀÓÀáÀÃÉ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 5000
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @service_fee <> $0.00 -- ÌÏÌÓÀáÖÒÄÁÉÓ ÂÀÃÀÓÀáÀÃÉÈ ÌÉÙÄÁÖËÉ ÛÄÌÏÓÀÅËÄÁÉ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 3100,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @service_fee
		SET @doc_type		= 98
		SET @op_code		= '*SVCF'
		SET @descrip		= 'ÌÏÌÓÀáÖÒÄÁÉÓ ÂÀÃÀÓÀáÀÃÉÈ ÌÉÙÄÁÖËÉ ÛÄÌÏÓÀÅËÄÁÉ (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id		= NULL
		SET @type_id		= 3100
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_nu_principal > $0.00 AND  @disburse_type = 4
	BEGIN
		SET @debit_id = @l_technical_999_id
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
 		SET @debit = @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 10,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		SET @iso			= @loan_iso
		SET @amount			= @payment_nu_principal
		SET @doc_type		= 245
		SET @op_code		= '*LNP+'
		SET @descrip		= 'ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÀÙÉÀÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		
		SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id
		SET @type_id		= 10
		SET @check_saldo	= 0
			

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	/*IF @l_rsrv_chng_paym = 1
	BEGIN
		EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
			@accrue_date					= @doc_date,
			@loan_id						= @loan_id,
			@user_id						= @user_id,
			@create_table					= 0,
			@simulate						= @simulate
		
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END*/
END
ELSE
IF @op_type = dbo.loan_const_op_close() -- ÓÄÓáÉÓ ÃÀáÖÒÅÀ
BEGIN
	DECLARE
		@acc_0301_balance TAMOUNT
	
	SELECT @acc_0301_balance = ACC_0301_BALANCE FROM dbo.LOAN_ACCOUNT_BALANCE WHERE LOAN_ID = @loan_id
	
	IF @acc_0301_balance <> 0
	BEGIN
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 10,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @credit_id = @l_technical_999_id
		IF @credit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
 		SET @credit = @l_technical_999

		SET @iso			= @loan_iso
		SET @amount			= @acc_0301_balance
		SET @doc_type		= 245
		SET @op_code		= '*LNP-'
		SET @descrip		= 'ÀÙÉÀÒÄÁÖËÉ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

		SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id
		SET @type_id		= -10
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
	
	EXEC @r = dbo.loan_process_collateral_accounting
		@op_id = @op_id,
		@user_id = @user_id,
		@doc_date = @doc_date,
		@head_branch_id = @head_branch_id,
		@l_technical_999 = @l_technical_999,
		@only_close = 1,
		@by_processing = @by_processing,
		@simulate = @simulate
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
		@accrue_date					= @doc_date,
		@loan_id						= @loan_id,
		@user_id						= @user_id,
		@create_table					= 0,
		@simulate						= @simulate
	
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END
ELSE
IF @op_type = dbo.loan_const_op_writeoff() --ÓÄÓáÉÓ ÜÀÌÏßÄÒÀ
BEGIN
	DECLARE
		@risk_category_date smalldatetime
	SELECT @risk_category_date = RISK_CATEGORY_DATE
	FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)
	WHERE LOAN_ID = @loan_id

	DECLARE
		@acc_906_gel TACCOUNT,
		@acc_906_gel_id int,
		@acc_906_val TACCOUNT,
		@acc_906_val_id int

	EXEC dbo.GET_SETTING_ACC 'CONV_ACC_2601', @acc_906_gel OUTPUT
	SET @acc_906_gel_id = dbo.acc_get_acc_id(@head_branch_id, @acc_906_gel, 'GEL')
	EXEC dbo.GET_SETTING_ACC 'CONV_ACC_2611', @acc_906_val OUTPUT
	SET @acc_906_val_id = dbo.acc_get_acc_id(@head_branch_id, @acc_906_val, @loan_iso)  
	
	IF (@template_41 IS NOT NULL)
	BEGIN
		SET @type_id_41 = 8000
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_41 OUTPUT,
			@account	= @account_41 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 8000,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
	ELSE
	BEGIN
		SET @type_id_41 = 8050
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_41 OUTPUT,
			@account	= @account_41 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 8050,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
	

	DECLARE
		@writeoff_penalty TAMOUNT,
		@writeoff_overdue_percent TAMOUNT,
		@writeoff_overdue_percent30 TAMOUNT,
		@writeoff_overdue_principal TAMOUNT,
		@writeoff_overdue_principal_GEL TAMOUNT,
		@writeoff_interest TAMOUNT,
		@writeoff_principal TAMOUNT,
		@writeoff_principal_GEL TAMOUNT

	SELECT
		@writeoff_interest = ISNULL(INTEREST, $0.00) + ISNULL(NU_INTEREST, $0.00) + ISNULL(OVERDUE_PRINCIPAL_INTEREST, $0.00),
		@writeoff_principal = ISNULL(PRINCIPAL, $0.00) + ISNULL(LATE_PRINCIPAL, $0.00),
		@writeoff_overdue_principal = ISNULL(OVERDUE_PRINCIPAL, $0.00),
		@writeoff_overdue_percent = ISNULL(LATE_PERCENT, $0.00) + ISNULL(OVERDUE_PERCENT, $0.00),
		@writeoff_penalty = ISNULL(OVERDUE_PERCENT_PENALTY, $0.00) + ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00)
	FROM dbo.LOAN_VW_LOAN_OP_WRITEOFF_DETAILS
	WHERE OP_ID = @op_id

	SELECT @writeoff_overdue_percent30 = ISNULL(OVERDUE_INTEREST30_BALANCE, $0.00)
	FROM dbo.LOAN_ACCOUNT_BALANCE
	WHERE LOAN_ID = @loan_id

	SET @writeoff_overdue_percent = @writeoff_overdue_percent - @writeoff_overdue_percent30

	IF @writeoff_principal <> $0.00
	BEGIN
		IF @loan_iso <> 'GEL'
		BEGIN
			SET @debit = NULL
			SET @debit_id = NULL
			SET @credit = NULL
			SET @credit_id = NULL

			EXEC @r = dbo.GET_CROSS_AMOUNT
				@iso1			= @loan_iso,
				@iso2			= 'GEL',
				@amount 		= @writeoff_principal,
				@dt				= @doc_date,
				@new_amount 	= @writeoff_principal_GEL OUTPUT	

			IF @r <> 0 OR @@ERROR <> 0	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1001 END

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @debit_id OUTPUT,
				@account	= @debit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 170,
				@loan_id	= @loan_id,
				@iso		= 'GEL',
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


			SET @credit = @acc_906_gel
			SET @credit_id = @acc_906_gel_id


			SET @iso			= @loan_iso
			SET @amount			= @writeoff_principal_GEL
			SET @doc_type		= 20
			SET @op_code		= 'WRCNV'
			SET @descrip		= 'ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= 0
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, 'GEL', @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @debit = NULL
			SET @debit_id = NULL
			SET @credit = NULL
			SET @credit_id = NULL

			SET @debit = @acc_906_val
			SET @debit_id = @acc_906_val_id

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 30,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= @loan_iso
			SET @amount			= @writeoff_principal
			SET @doc_type		= 14
			SET @op_code		= 'WRCNV'
			SET @descrip		= 'ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= CONVERT(int, @risk_category_date)
			SET @type_id		= 0
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @debit = NULL
			SET @debit_id = NULL
			SET @credit = NULL
			SET @credit_id = NULL

			SET	@debit_id = @acc_id_41
			SET @debit = @account_41

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 170,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= 'GEL'
			SET @amount			= @writeoff_principal_GEL
			SET @doc_type		= 40
			SET @op_code		= '*LR6+'
			SET @descrip		= 'ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= -@type_id_41
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		ELSE
		BEGIN
			SET @debit = NULL
			SET @debit_id = NULL
			SET @credit = NULL
			SET @credit_id = NULL

			SET	@debit_id = @acc_id_41
			SET @debit = @account_41

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 30,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= @loan_iso
			SET @amount			= @writeoff_principal
			SET @doc_type		= 40
			SET @op_code		= '*LR6+'
			SET @descrip		= 'ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= CONVERT(int, @risk_category_date)
			SET @type_id		= -@type_id_41
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 50,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @credit_id = @l_technical_999_id 
		IF @credit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @credit	= @l_technical_999

		SET @iso			= @loan_iso
		SET @amount			= @writeoff_principal
		SET @doc_type		= 245
		SET @op_code		= '*LW+'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÂÀÒÄÁÀËÀÍÓÆÄ ÀÓÀáÅÀ (áÄËÛ. ' + @agreement_no + ')'

		SELECT @foreign_id	= NULL
		SET @type_id		= 50
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @writeoff_overdue_principal <> $0.00
	BEGIN
		IF @loan_iso <> 'GEL'
		BEGIN
			SET @debit = NULL
			SET @debit_id = NULL
			SET @credit = NULL
			SET @credit_id = NULL

			EXEC @r = dbo.GET_CROSS_AMOUNT
				@iso1			= @loan_iso,
				@iso2			= 'GEL',
				@amount 		= @writeoff_overdue_principal,
				@dt				= @doc_date,
				@new_amount 	= @writeoff_overdue_principal_GEL OUTPUT	

			IF @r <> 0 OR @@ERROR <> 0	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1001 END

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @debit_id OUTPUT,
				@account	= @debit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 170,
				@loan_id	= @loan_id,
				@iso		= 'GEL',
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @credit = @acc_906_gel
			SET @credit_id = @acc_906_gel_id


			SET @iso			= 'GEL'
			SET @amount			= @writeoff_overdue_principal_GEL
			SET @doc_type		= 20
			SET @op_code		= 'WRCNV'
			SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= 0
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @debit = NULL
			SET @debit_id = NULL
			SET @credit = NULL
			SET @credit_id = NULL

			SET @debit = @acc_906_val
			SET @debit_id = @acc_906_val_id

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT, 
				@type_id	= 40,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= @loan_iso
			SET @amount			= @writeoff_overdue_principal
			SET @doc_type		= 14
			SET @op_code		= 'WRCNV'
			SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= CONVERT(int, @risk_category_date)
			SET @type_id		= 0
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @debit = NULL
			SET @debit_id = NULL
			SET @credit = NULL
			SET @credit_id = NULL

			SET	@debit_id = @acc_id_41
			SET @debit = @account_41

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 170,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= 'GEL'
			SET @amount			= @writeoff_overdue_principal_GEL
			SET @doc_type		= 40
			SET @op_code		= '*LR6+'
			SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= NULL
			SET @type_id		= -@type_id_41
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		ELSE
		BEGIN
			SET @debit = NULL
			SET @debit_id = NULL
			SET @credit = NULL
			SET @credit_id = NULL

			SET	@debit_id = @acc_id_41
			SET @debit = @account_41

			EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
				@acc_id		= @credit_id OUTPUT,
				@account	= @credit OUTPUT,
				@acc_added	= @acc_added OUTPUT,
				@bal_acc	= @bal_acc OUTPUT,
				@type_id	= 40,
				@loan_id	= @loan_id,
				@iso		= @loan_iso,
				@user_id	= @user_id,
				@simulate	= @simulate,
				@guarantee	= @guarantee
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

			SET @iso			= @loan_iso
			SET @amount			= @writeoff_overdue_principal
			SET @doc_type		= 40
			SET @op_code		= '*LR6+'
			SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
			SET @foreign_id		= CONVERT(int, @risk_category_date)
			SET @type_id		= -@type_id_41
			SET @check_saldo	= 0

			INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
			VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
			IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 50,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @credit_id = @l_technical_999_id 
		IF @credit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @credit	= @l_technical_999

		SET @iso			= @loan_iso
		SET @amount			= @writeoff_overdue_principal
		SET @doc_type		= 245
		SET @op_code		= '*LW+'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÂÀÒÄÁÀËÀÍÓÆÄ ÀÓÀáÅÀ (áÄËÛ. ' + @agreement_no + ')'

		SELECT @foreign_id	= NULL
		SET @type_id		= 51
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @writeoff_interest <> $0.00
	BEGIN
		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1130,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1030,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @writeoff_interest
		SET @doc_type		= 40
		SET @op_code		= '*LI-'
		SET @descrip		= 'ÃÀÒÉÝáÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -1030
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 70,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @credit_id = @l_technical_999_id
		IF @credit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @credit	= @l_technical_999
		

		SET @iso			= @loan_iso
		SET @amount			= @writeoff_interest
		SET @doc_type		= 240
		SET @op_code		= '*LWI+'
		SET @descrip		= 'ÃÀÒÉÝáÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, WRITEOFF_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= 70
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @writeoff_overdue_percent <> $0.00
	BEGIN
		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1160,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 60,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @writeoff_overdue_percent
		SET @doc_type		= 45
		SET @op_code		= '*LOI-'
		SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -1160
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 70,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @credit_id = @l_technical_999_id
		IF @credit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END

		SET @credit	= @l_technical_999
		

		SET @iso			= @loan_iso
		SET @amount			= @writeoff_overdue_percent
		SET @doc_type		= 240
		SET @op_code		= '*LWI+'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÂÀÒÄÁÀËÀÍÓÆÄ ÀÓÀáÅÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, WRITEOFF_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= 70
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @writeoff_overdue_percent30 <> $0.00
	BEGIN
		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 70,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2060,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		

		SET @iso			= @loan_iso
		SET @amount			= @writeoff_overdue_percent30
		SET @doc_type		= 240
		SET @op_code		= '*LOI-'
		SET @descrip		= '30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃ. ÐÒÏÝÄÍÔÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, OVERDUE_INTEREST30_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -2060
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @writeoff_penalty <> $0.00
	BEGIN
		SET @debit = NULL
		SET @debit_id = NULL
		SET @credit = NULL
		SET @credit_id = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 80,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2000,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		

		SET @iso			= @loan_iso
		SET @amount			= @writeoff_penalty
		SET @doc_type		= 240
		SET @op_code		= '*LPI-'
		SET @descrip		= 'ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÜÀÌÏßÄÒÀ (áÄËÛ. ' + @agreement_no + ')'
		SELECT @foreign_id	= CONVERT(int, PENALTY_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -2000
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END
ELSE
IF @op_type = dbo.loan_const_op_writedoff_forgive()
BEGIN

	DECLARE
		@writeoff_percent_forgive money,
		@writeoff_penalty_forgive money

	SELECT 
		@writeoff_percent_forgive = WRITEOFF_PERCENT_ORG - WRITEOFF_PERCENT,
		@writeoff_penalty_forgive = WRITEOFF_PENALTY_ORG - WRITEOFF_PENALTY
	FROM dbo.LOAN_VW_LOAN_OP_WRITEDOFF_FORGIVE
	WHERE OP_ID = @op_id

	SET @debit_id = @l_technical_999_id
	IF @debit_id IS NULL
	BEGIN
		SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
		RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
		BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
 	SET @debit = @l_technical_999


	IF ISNULL(@writeoff_percent_forgive, $0.00) <> $0.00 
	BEGIN
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 70,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @writeoff_percent_forgive
		SET @doc_type		= 240
		SET @op_code		= '*LWI-'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ÐÒÏÝÄÍÔÉÓ ÐÀÔÉÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

		SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id

		SET @type_id		= 0 --????
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF ISNULL(@writeoff_penalty_forgive, $0.00) <> $0.00
	BEGIN
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 80,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @writeoff_penalty_forgive
		SET @doc_type		= 98
		SET @op_code		= '*LWI-'
		SET @descrip		= 'ÜÀÌÏßÄÒÉËÉ ãÀÒÉÌÉÓ ÐÀÔÉÄÁÀ (áÄËÛ. ' + @agreement_no + ')'

		SELECT @foreign_id = CONVERT(int, ACC_0301_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)	WHERE LOAN_ID = @loan_id

		SET @type_id		= 0
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END
ELSE
IF @op_type IN (dbo.loan_const_op_restructure_collateral(), dbo.loan_const_op_correct_collateral())
BEGIN
	EXEC @r = dbo.loan_process_collateral_accounting
		@op_id = @op_id,
		@user_id = @user_id,
		@doc_date = @doc_date,
		@head_branch_id = @head_branch_id,
		@l_technical_999 = @l_technical_999,
		@only_close = 0,
		@by_processing = @by_processing,
		@simulate = @simulate
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END
ELSE
IF @op_type = dbo.loan_const_op_guar_disburse()  -- ÂÀÒÀÍÔÉÉÓ ÂÀÝÄÌÀ
BEGIN
	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 35,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @credit_id OUTPUT,
		@account	= @credit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 36,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @iso			= @loan_iso
	SET @amount			= @op_amount
	SET @doc_type		= 200
	SET @op_code		= '*GP+'

	IF @guarantee_internat = 1
		SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÂÀÝÄÌÀ'
	ELSE
		SET @descrip = @agreement_no + '/09/ÊÁ (' + @client_descrip +  ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÂÀÝÄÌÀ'

	SET @foreign_id		= NULL
	SET @type_id		= 30
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SELECT @amount = ISNULL(ADMIN_FEE, $0.00)
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id
	
	IF (@amount > $0.00) AND (@immediate_feeing = 1)
	BEGIN
		SET @debit = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso2 = CASE WHEN @guarantee_internat = 0 THEN @loan_iso ELSE 'EUR' END
		SET @amount2 = @amount

		IF @loan_iso <> @iso2
		BEGIN
			EXEC @r = dbo.GET_CROSS_AMOUNT
				@iso1			= @iso2,
				@iso2			= @loan_iso,
				@amount 		= @amount2,
				@dt				= @op_date,
				@new_amount 	= @amount OUTPUT	
			IF @r <> 0 OR @@ERROR <> 0	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1001 END
		END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1000,
			@loan_id	= @loan_id,
			@iso		= @iso2,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @doc_type		= 45
		SET @op_code		= '*GA+'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÄÒÈãÄÒÀÃÉ ÓÀÊÏÌÉÓÉÏ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip +  ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÄÒÈãÄÒÀÃÉ ÓÀÊÏÌÉÓÉÏ'
		SET @foreign_id		= NULL
		SET @type_id		= 1000
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, ISO2, AMOUNT2, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @iso2, @amount2, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	SET @debit = NULL
	SET @credit = NULL
END
ELSE
IF @op_type = dbo.loan_const_op_guar_payment()
BEGIN
	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 20,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SELECT 
		@is_incasso = IS_INCASSO,
		@acc_rec_state = REC_STATE
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @debit_id
	
	IF @is_incasso = 1
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK
		RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÀÃÄÅÓ ÉÍÊÀÓÏ, ÃÀ×ÀÒÅÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
		RETURN 101
	END

	IF @acc_rec_state <> 1
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK
		RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÓÔÀÔÖÓÉÓ ÂÀÌÏ ÃÀ×ÀÒÅÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
		RETURN 101
	END

	SELECT
		@payment_interest = ISNULL(INTEREST, $0.00),
		@payment_overdue_percent = ISNULL(OVERDUE_PERCENT, $0.00),
		@payment_penalty = ISNULL(PENALTY, $0.00)
	FROM dbo.LOAN_VW_GUARANTEE_OP_PAYMENT
	WHERE OP_ID = @op_id

	SELECT @payment_overdue_percent30 = ISNULL(OVERDUE_INTEREST30_BALANCE, $0.00)
	FROM dbo.LOAN_ACCOUNT_BALANCE
	WHERE LOAN_ID = @loan_id

	IF @payment_overdue_percent > $0.00
	BEGIN
		IF @payment_overdue_percent >= @payment_overdue_percent30
			SET @payment_overdue_percent = @payment_overdue_percent - @payment_overdue_percent30
		ELSE
		BEGIN
			SET @payment_overdue_percent30 = @payment_overdue_percent
			SET @payment_overdue_percent = $0.00
		END
	END
	ELSE SET @payment_overdue_percent30 = $0.00

	IF @payment_interest <> $0.00 --ÐÒÏÝÄÍÔÉÓ ÂÀÃÀáÃÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1030,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_interest
		SET @doc_type		= 45
		SET @op_code		= '*GI-'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÓÀÊÏÌÉÓÉÏ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÓÀÊÏÌÉÓÉÏ'
		SELECT @foreign_id	= CONVERT(int, INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -1030
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_overdue_percent <> $0.00 --ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÂÀÃÀáÃÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 60,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_percent
		SET @doc_type		= 45
		SET @op_code		= '*GOI-'
		SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ % ÒÄÀËÉÆÄÁÀ'
		SELECT @foreign_id	= CONVERT(int, OVERDUE_INTEREST_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -1160
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_overdue_percent30 <> $0.00 -- 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÃÀ×ÀÒÅÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 60,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1160,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_percent30
		SET @doc_type		= 45
		SET @op_code		= '*GOI+'
		SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ % ÀÙÃÂÄÍÀ'
		SET @foreign_id		= NULL
		SET @type_id		= 1160
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		SET @debit_id = @l_technical_999_id 
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @debit	= @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2060,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_percent30
		SET @doc_type		= 240
		SET @op_code		= '*GOI-'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ % ÜÀÌÏßÄÒÀ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ % ÜÀÌÏßÄÒÀ'
		SELECT @foreign_id	= CONVERT(int, OVERDUE_INTEREST30_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -2060
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 60,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_overdue_percent30
		SET @doc_type		= 45
		SET @op_code		= '*GOI-'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ % ÒÄÀËÉÆÄÁÀ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ % ÒÄÀËÉÆÄÁÀ'
		SET @foreign_id		= NULL
		SET @type_id		= -1160
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	IF @payment_penalty <> $0.00 -- ÓÄÓáÆÄ ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÃÀ×ÀÒÅÀ
	BEGIN
		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2100,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @payment_penalty
		SET @doc_type		= 45
		SET @op_code		= '*GPII'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÃÀÍ ÌÉÙÄÁÖËÉ ãÀÒÉÌÀ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÃÀÍ ÌÉÙÄÁÖËÉ ãÀÒÉÌÀ'
		SET @foreign_id		= NULL
		SET @type_id		= 2100
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @debit_id = NULL
		SET @debit = NULL
		SET @credit_id = NULL
		SET @credit = NULL

		SET @debit_id = @l_technical_999_id 
		IF @debit_id IS NULL
		BEGIN
			SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
			RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
		END
		SET @debit	= @l_technical_999

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 2000,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


		SET @iso			= @loan_iso
		SET @amount			= @payment_penalty
		SET @doc_type		= 240
		SET @op_code		= '*GPI-'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ ÌÉÓÀÙÄÁÉ ãÀÒÉÌÄÁÉÓ ÜÀÌÏßÄÒÀ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ ÌÉÓÀÙÄÁÉ ãÀÒÉÌÄÁÉÓ ÜÀÌÏßÄÒÀ'
		SELECT @foreign_id	= CONVERT(int, PENALTY_DATE) FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) WHERE LOAN_ID = @loan_id
		SET @type_id		= -2000
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END
ELSE
IF @op_type = dbo.loan_const_op_guar_fee()
BEGIN
	DECLARE
		@rate_amount money,
		@rate_items int,
		@rate_reverse bit

	SET @amount = @op_amount

	IF @amount > $0.00
	BEGIN
		SET @debit = Null
		SET @credit = Null

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 20,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso2 = CASE WHEN @guarantee_internat = 0 THEN @loan_iso ELSE 'EUR' END
		SET @amount2 = @amount

		IF @loan_iso <> @iso2
		BEGIN
			SET @conv_only = 1
			
			EXEC dbo.client_sp_get_convert_amount
					@client_no = @client_no,
					@iso1  = @iso2,
					@iso2 = @loan_iso,
					@amount = @amount2,
					@new_amount = @amount OUT,
					@rate_amount = @rate_amount OUT,
					@rate_items = @rate_items OUT,
					@reverse = @rate_reverse OUT,
					@look_buy = 0
			IF @@ERROR <> 0	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1001 END

			--EXEC @r = dbo.GET_CROSS_AMOUNT
			--	@iso1			= @iso2,
			--	@iso2			= @loan_iso,
			--	@amount 		= @amount2,
			--	@dt				= @op_date,
			--	@new_amount 	= @amount OUTPUT	
			--IF @r <> 0 OR @@ERROR <> 0	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1001 END
		END

		IF EXISTS (SELECT * FROM dbo.LOAN_OPS (NOLOCK) WHERE LOAN_ID = @loan_id AND OP_TYPE = 216) --dbo.loan_const_op_guar_fee2()
			SET @type_id = 1010
		ELSE 
			SET @type_id = 1000

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= @iso2,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @doc_type		= 45
		SET @op_code		= '*GA+'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÄÒÈãÄÒÀÃÉ ÓÀÊÏÌÉÓÉÏ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip +  ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÄÒÈãÄÒÀÃÉ ÓÀÊÏÌÉÓÉÏ'
		SET @foreign_id		= NULL
		SET @type_id		= 1000
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, ISO2, AMOUNT2, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @iso2, @amount2, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END
ELSE
IF @op_type = dbo.loan_const_op_guar_fee2()
BEGIN
	SET @amount = @op_amount

	IF @amount > $0.00
	BEGIN
		SET @debit = Null
		SET @credit = Null

		SET @iso2 = CASE WHEN @guarantee_internat = 0 THEN @loan_iso ELSE 'EUR' END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1010,
			@loan_id	= @loan_id,
			@iso		= @iso2,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1000,
			@loan_id	= @loan_id,
			@iso		= @iso2,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @iso2
		SET @doc_type		= 98
		SET @op_code		= '*GAF+'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÄÒÈãÄÒÀÃÉ ÓÀÊÏÌÉÓÉÏ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip +  ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÄÒÈãÄÒÀÃÉ ÓÀÊÏÌÉÓÉÏ'
		SET @foreign_id		= NULL
		SET @type_id		= 0
		SET @check_saldo	= 1

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END
ELSE
IF @op_type = dbo.loan_const_op_guar_inc()
BEGIN
	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 35,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @credit_id OUTPUT,
		@account	= @credit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 36,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @iso			= @loan_iso
	SET @amount			= @op_amount
	SET @doc_type		= 200
	SET @op_code		= '*GP+'
	IF @guarantee_internat = 1
		SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÂÀÆÒÃÀ'
	ELSE
		SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÂÀÆÒÃÀ'
	SET @foreign_id		= NULL
	SET @type_id		= 30
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END
ELSE
IF @op_type = dbo.loan_const_op_guar_dec()
BEGIN
	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @debit_id OUTPUT,
		@account	= @debit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 36,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @credit_id OUTPUT,
		@account	= @credit OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 35,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @iso			= @loan_iso
	SET @amount			= @op_amount
	SET @doc_type		= 200
	SET @op_code		= '*GP-'
	IF @guarantee_internat = 1
		SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÛÄÌÝÉÒÄÁÀ'
	ELSE
		SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÛÄÌÝÉÒÄÁÀ'
	SET @foreign_id		= NULL
	SET @type_id		= -30
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END
ELSE
IF @op_type = dbo.loan_const_op_guar_close()
BEGIN
	IF @op_amount > $0.00
	BEGIN
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @debit_id OUTPUT,
			@account	= @debit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 36,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @credit_id OUTPUT,
			@account	= @credit OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 35,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @iso			= @loan_iso
		SET @amount			= @op_amount
		SET @doc_type		= 200
		SET @op_code		= '*GP-'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÃÀáÖÒÅÀ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ (' + @client_descrip + ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÃÀáÖÒÅÀ'
		SET @foreign_id		= NULL
		SET @type_id		= -30
		SET @check_saldo	= 0

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
	
	EXEC @r = dbo.loan_process_collateral_accounting
		@op_id = @op_id,
		@user_id = @user_id,
		@doc_date = @doc_date,
		@head_branch_id = @head_branch_id,
		@l_technical_999 = @l_technical_999,
		@only_close = 1,
		@by_processing = @by_processing,
		@simulate = @simulate
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
		@accrue_date					= @doc_date,
		@loan_id						= @loan_id,
		@user_id						= @user_id,
		@create_table					= 0,
		@simulate						= @simulate
	
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END


EXECUTE @r = dbo.ON_USER_LOAN_SP_AFTER_PROCESS_OP_ACCOUNTING
	@op_id = @op_id,
	@user_id = @user_id,
	@doc_date = @doc_date,
	@by_processing = @by_processing,
	@simulate = @simulate
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

DECLARE
	@sender_client_no int,
	@sender_bank_code varchar(37),
	@sender_bank_name varchar(105),
	@sender_acc varchar(37),
	@sender_acc_name varchar(105),
	@sender_tax_code varchar(11),

	@receiver_client_no int,
	@receiver_bank_code varchar(37),
	@receiver_bank_name varchar(105),
	@receiver_acc varchar(37),
	@receiver_acc_name varchar(105),
	@receiver_tax_code varchar(11)

IF @simulate = 0
BEGIN
	DECLARE 
		@rec_id int,
		@rec_id_2 int,
		@parent_rec_id int

	SET @parent_rec_id = 0
	IF ((SELECT COUNT(*) FROM #docs) > 1) OR (@conv_only = 1)
		SET @parent_rec_id = -1

	SET @doc_num = 1
	SET @doc_rec_id = NULL

	DECLARE cr CURSOR FOR
	SELECT DOC_DATE, DEBIT_ID, CREDIT_ID, ISO, AMOUNT, ISO2, AMOUNT2, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO
	FROM #docs
	ORDER BY REC_ID

	OPEN cr
	FETCH NEXT FROM cr
	INTO @doc_date, @debit_id, @credit_id, @iso, @amount, @iso2, @amount2, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sender_bank_code = NULL
		SET @sender_bank_name = NULL
		SET @sender_acc_name = NULL
		SET @sender_acc = NULL
		SET @sender_client_no = NULL
		SET @sender_tax_code = NULL
	
		SET @receiver_bank_code = NULL
		SET @receiver_bank_name = NULL
		SET @receiver_acc_name = NULL
		SET @receiver_acc = NULL
		SET @receiver_client_no = NULL

		IF @iso = ISNULL(@iso2, @iso)
		BEGIN
			IF @doc_type IN (100, 110)
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code(@debit_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name(@debit_id)
				SET @sender_acc = dbo.acc_get_account(@debit_id)
				SELECT @sender_client_no = CLIENT_NO FROM dbo.ACCOUNTS WHERE ACC_ID = @debit_id
				IF @sender_client_no IS NOT NULL
					SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @sender_client_no 
			
				SET @receiver_bank_code = dbo.acc_get_bank_code(@credit_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name(@credit_id)
				SET @receiver_acc = dbo.acc_get_account(@credit_id)
				IF @receiver_client_no IS NOT NULL
					SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @receiver_client_no 
			END
			
			EXEC @r = dbo.ADD_DOC4
				@rec_id				= @rec_id OUTPUT,
				@user_id			= @user_id,
				@doc_type			= @doc_type, 
				@doc_num			= @doc_num,
				@doc_date			= @doc_date,
				@doc_date_in_doc	= @doc_date,
				@debit_id			= @debit_id,
				@credit_id			= @credit_id,
				@iso				= @iso, 
				@amount				= @amount,
				@rec_state			= @rec_state,
				@descrip			= @descrip,
				@op_code			= @op_code,
				@bnk_cli_id			= @type_id, 
				@account_extra		= @loan_id,
				@parent_rec_id		= @parent_rec_id,
				@prod_id			= 7,
				@foreign_id			= @foreign_id,
				@channel_id			= 700,
				@dept_no			= @dept_no,

				@check_saldo		= @check_saldo,
				@add_tariff			= 0,
				@info				= 0,

				@sender_bank_code	= @sender_bank_code,
				@sender_acc			= @sender_acc,
				@sender_tax_code	= @sender_tax_code,
				@receiver_bank_code = @receiver_bank_code,
				@receiver_acc		= @receiver_acc,
				@receiver_tax_code	= @receiver_tax_code,
				@sender_bank_name	= @sender_bank_name,
				@receiver_bank_name = @receiver_bank_name,
				@sender_acc_name	= @sender_acc_name,
				@receiver_acc_name	= @receiver_acc_name

			IF @@ERROR<>0 OR @r<>0 GOTO cr_ret
		END
		ELSE
		BEGIN
			EXEC @r = dbo.ADD_CONV_DOC4
				@rec_id_1			= @rec_id OUTPUT,
				@rec_id_2			= @rec_id_2 OUTPUT,
				@user_id			= @user_id,
				@iso_d				= @iso,              
				@iso_c				= @iso2,              
				@amount_d			= @amount,          
				@amount_c			= @amount2,
				@debit_id			= @debit_id,
				@credit_id			= @credit_id,
				@doc_date			= @doc_date,
				@doc_num			= @doc_num,
				@account_extra		= @loan_id,
				@descrip1			= @descrip,   
				@descrip2			= @descrip,   
				@rec_state			= @rec_state,
				@par_rec_id			= @parent_rec_id,
				@dept_no			= @dept_no,
				@prod_id			= 7,
				@foreign_id			= @foreign_id,
				@channel_id			= 700,
				@check_saldo		= @check_saldo,
				@add_tariff			= 0,
				@info				= 0
			IF @@ERROR<>0 OR @r<>0 GOTO cr_ret
		END

		SET @doc_num = @doc_num + 1

		IF @doc_rec_id IS NULL
			SET @doc_rec_id = @rec_id
		
		IF @parent_rec_id <= 0
			SET @parent_rec_id = @rec_id
	
		EXEC @r = dbo.LOAN_SP_UPDATE_ACCOUNT_BALANCE_INTERNAL
			@loan_id = @loan_id,
			@type_id = @type_id,
			@doc_date = @doc_date,
			@amount = @amount

		IF @@ERROR<>0 OR @r <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÀÓÄÓáÏ ÍÀÛÈÉÓ ÝÅËÉËÄÁÉÓÀÓ!!!', 16, 1) RETURN (1) END

		FETCH NEXT FROM cr
		INTO @doc_date, @debit_id, @credit_id, @iso, @amount, @iso2, @amount2, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo
	END
GOTO cr_ok
cr_ret:
	CLOSE cr
	DEALLOCATE cr
	IF @internal_transaction=1 AND @@TRANCOUNT>0
	BEGIN
		DROP TABLE #docs
		ROLLBACK
	END
	RETURN 1
cr_ok:
	CLOSE cr
	DEALLOCATE cr
	UPDATE dbo.LOAN_OPS
	SET DOC_REC_ID = @doc_rec_id
	WHERE OP_ID=@op_id
END
ELSE
BEGIN
	SELECT * FROM #docs
END

GOTO ret

ret_select:
	SELECT * FROM #docs
	DROP TABLE #docs

IF @simulate = 0 AND @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)

ret:
	DROP TABLE #docs

IF @simulate = 0 AND @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)
GO
