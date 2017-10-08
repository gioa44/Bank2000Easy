SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_ACCRUAL_RISK]
/*
1. ÃÀÀÁÒÖÍÏÓ ÐÀÒÀÌÄÔÒÄÁÛÉ ÃÀÒÉÝáÅÉÓ ÌÏÍÀÝÄÌÄÁÉ -> @return_params
2. ÛÄØÌÍÀÓ ÃÏÊÖÌÄÍÔÄÁÉÓ ÓÉÀ -> @create_table
3. ÛÄÀÅÓÏÓ ÃÏÊÖÌÄÍÔÄÁÉÓ ÓÉÀ -> @return_params == FALSE
4. ÃÀÀÌÀÔÏÓ ÓÀÁÖÈÄÁÉ ÀÍ ÂÀÀÊÄÈÏÓ ÓÉÌÖËÀÝÉÀ -> @simulate
5. ÃÀÀÓÄËÄØÔÏÓ ÃÏÊÖÌÄÍÔÄÁÉÓ ÓÉÀ -> @select_list
6. ÀÒ ÂÀÀÊÄÈÏÓ ÀÒÀ×ÄÒÉ -> @accrue
*/

	@doc_rec_id						int OUTPUT,
	@accrue_date					smalldatetime,
	@doc_date						smalldatetime,
	@loan_id						int,
	@user_id						int,
	@return_params					bit = 0,
	@create_table					bit = 1,
	@simulate						bit = 0,
	@select_list					bit = 0,
	@accrue							bit = 1,
	@risk_category_date				smalldatetime OUTPUT,
	@risk_category_1_balance		money OUTPUT,
	@risk_category_1_balance_		money OUTPUT,
	@risk_category_2_balance		money OUTPUT,
	@risk_category_2_balance_		money OUTPUT,
	@risk_category_3_balance		money OUTPUT,
	@risk_category_3_balance_		money OUTPUT,
	@risk_category_4_balance		money OUTPUT,
	@risk_category_4_balance_		money OUTPUT,
	@risk_category_5_balance		money OUTPUT,
	@risk_category_5_balance_		money OUTPUT,
	@risk_category_balance			money OUTPUT,
	@risk_category_balance_			money OUTPUT,
	@risk_accrue					money OUTPUT
AS
SET NOCOUNT ON

IF @accrue = 0
	RETURN (0)

DECLARE
	@type_id int
SELECT @risk_category_date = RISK_CATEGORY_DATE,
	@risk_category_balance = ISNULL(RISK_CATEGORY_BALANCE, $0.00),
	@risk_category_1_balance = ISNULL(RISK_CATEGORY_1_BALANCE, $0.00),
	@risk_category_2_balance = ISNULL(RISK_CATEGORY_2_BALANCE, $0.00),
	@risk_category_3_balance = ISNULL(RISK_CATEGORY_3_BALANCE, $0.00),
	@risk_category_4_balance = ISNULL(RISK_CATEGORY_4_BALANCE, $0.00),
	@risk_category_5_balance = ISNULL(RISK_CATEGORY_5_BALANCE, $0.00)
FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK)
WHERE LOAN_ID = @loan_id

SELECT @risk_category_1_balance_ = ISNULL(CATEGORY_1, $0.00),
	@risk_category_2_balance_ = ISNULL(CATEGORY_2, $0.00),
	@risk_category_3_balance_ = ISNULL(CATEGORY_3, $0.00),
	@risk_category_4_balance_ = ISNULL(CATEGORY_4, $0.00),
	@risk_category_5_balance_ = ISNULL(CATEGORY_5, $0.00)
FROM dbo.LOAN_DETAILS (NOLOCK)
WHERE LOAN_ID = @loan_id --AND CALC_DATE <= @accrue_date

DECLARE
	@r int

DECLARE -- Loan Data
	@branch_id int,
	@dept_no int,
	@agreement_no varchar(100),
	@loan_iso TISO,
	@guarantee bit,
	@guarantee_internat bit,
	@guarantee_purpose_code varchar(15),	
	@client_descrip varchar(100)
SELECT
	@branch_id		= L.BRANCH_ID,
	@dept_no		= L.DEPT_NO,
	@agreement_no	= L.AGREEMENT_NO,
	@loan_iso		= L.ISO,
	@guarantee		= L.GUARANTEE,
	@guarantee_internat = LA1.ATTRIB_VALUE,
	@guarantee_purpose_code = LA2.ATTRIB_VALUE,
	@client_descrip	= C.DESCRIP
FROM dbo.LOANS L (NOLOCK)
	INNER JOIN dbo.CLIENTS C (NOLOCK) ON L.CLIENT_NO = C.CLIENT_NO
	LEFT JOIN dbo.LOAN_ATTRIBUTES LA1 (NOLOCK) ON L.LOAN_ID = LA1.LOAN_ID AND LA1.ATTRIB_CODE = 'GUARTYPE'
	LEFT JOIN dbo.LOAN_ATTRIBUTES LA2 (NOLOCK) ON L.LOAN_ID = LA2.LOAN_ID AND LA2.ATTRIB_CODE = 'PURPCODE'		
WHERE L.LOAN_ID = @loan_id
SELECT @r = @@ROWCOUNT
IF @@ERROR<>0 OR @r<>1 RETURN 11 

DECLARE
	@perc_rate_1 smallmoney, 
	@perc_rate_2 smallmoney, 
	@perc_rate_3 smallmoney, 
	@perc_rate_4 smallmoney, 
	@perc_rate_5 smallmoney

SELECT @perc_rate_1 = RISK_PERC_RATE_1, @perc_rate_2 = RISK_PERC_RATE_2, @perc_rate_3 = RISK_PERC_RATE_3, @perc_rate_4 = RISK_PERC_RATE_4, @perc_rate_5 = RISK_PERC_RATE_5
FROM dbo.LOANS (NOLOCK)
WHERE LOAN_ID = @loan_id


SET @risk_category_1_balance_ = dbo.get_equ(@risk_category_1_balance_, @loan_iso, @accrue_date)
IF @@ERROR <> 0	RETURN 1001
SET @risk_category_2_balance_ = dbo.get_equ(@risk_category_2_balance_, @loan_iso, @accrue_date)
IF @@ERROR <> 0	RETURN 1001
SET @risk_category_3_balance_ = dbo.get_equ(@risk_category_3_balance_, @loan_iso, @accrue_date)
IF @@ERROR <> 0	RETURN 1001
SET @risk_category_4_balance_ = dbo.get_equ(@risk_category_4_balance_, @loan_iso, @accrue_date)
IF @@ERROR <> 0	RETURN 1001
SET @risk_category_5_balance_ = dbo.get_equ(@risk_category_5_balance_, @loan_iso, @accrue_date)
IF @@ERROR <> 0	RETURN 1001

SET @risk_category_1_balance_ = ROUND(ISNULL(@risk_category_1_balance_, $0.00) * @perc_rate_1 / $100.00, 2, 1)
SET @risk_category_2_balance_ = ROUND(ISNULL(@risk_category_2_balance_, $0.00) * @perc_rate_2 / $100.00, 2, 1)
SET @risk_category_3_balance_ = ROUND(ISNULL(@risk_category_3_balance_, $0.00) * @perc_rate_3 / $100.00, 2, 1)
SET @risk_category_4_balance_ = ROUND(ISNULL(@risk_category_4_balance_, $0.00) * @perc_rate_4 / $100.00, 2, 1)
SET @risk_category_5_balance_ = ROUND(ISNULL(@risk_category_5_balance_, $0.00) * @perc_rate_5 / $100.00, 2, 1)

SET @risk_category_balance = @risk_category_balance + (ISNULL(@risk_category_1_balance, $0.00) + ISNULL(@risk_category_2_balance, $0.00) + ISNULL(@risk_category_3_balance, $0.00) + ISNULL(@risk_category_4_balance, $0.00) + ISNULL(@risk_category_5_balance, $0.00))
SET @risk_category_balance_ = (ISNULL(@risk_category_1_balance_, $0.00) + ISNULL(@risk_category_2_balance_, $0.00) + ISNULL(@risk_category_3_balance_, $0.00) + ISNULL(@risk_category_4_balance_, $0.00) + ISNULL(@risk_category_5_balance_, $0.00))
SET @risk_accrue = @risk_category_balance_ - @risk_category_balance

IF @return_params = 1
	RETURN (0)

IF @risk_accrue = $0.00
	RETURN (0)

DECLARE
	@internal_transaction bit

SET @internal_transaction = 0
IF @simulate = 0 AND @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

IF @create_table = 1
BEGIN
	CREATE TABLE #docs(
		REC_ID		int PRIMARY KEY NOT NULL IDENTITY (1,1),
		DOC_DATE		smalldatetime	NOT NULL,
		DEBIT_ID		int NULL,
		DEBIT			decimal(15,0)	NOT NULL,
		CREDIT_ID		int NULL,
		CREDIT		decimal(15,0)	NOT NULL,
		ISO			char(3)			NOT NULL,
		AMOUNT		money			NOT NULL,
		DOC_TYPE		smallint		NOT NULL,
		OP_CODE		char(5)			collate database_default NOT NULL,
		DESCRIP		varchar(150)	collate database_default NOT NULL,
		FOREIGN_ID	int				NULL,
		TYPE_ID		int				NOT NULL)
END

DECLARE
	@doc_num		int,
	@debit_id		int,
	@debit			TACCOUNT,
	@credit_id		int,
	@credit			TACCOUNT,
	@iso			TISO,
	@amount			money,
	@doc_type		smallint,
	@op_code		TOPCODE,
	@rec_state		tinyint,
	@descrip		TDESCRIP, 
	@foreign_id		int

DECLARE
	@product_id		int,
	@template_41	varchar(150),
	@template_85	varchar(150),
	@account_41		TACCOUNT,
	@acc_id_41		int,
	@account_85		TACCOUNT,
	@acc_id_85		int
DECLARE
	@acc_id		int,
	@acc_added	bit,
	@bal_acc	TBAL_ACC
SELECT @product_id = PRODUCT_ID FROM dbo.LOANS (NOLOCK) WHERE LOAN_ID = @loan_id

IF EXISTS(SELECT * FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = 8000)
	SELECT @template_41 = TEMPLATE FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = 8000
ELSE
	SELECT @template_41 = TEMPLATE FROM dbo.LOAN_COMMON_ACCOUNT_TEMPLATES (NOLOCK) WHERE ACC_TYPE_ID = 8000

IF EXISTS(SELECT * FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = 9000)
	SELECT @template_85 = TEMPLATE FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = 9000
ELSE
	SELECT @template_85 = TEMPLATE FROM dbo.LOAN_COMMON_ACCOUNT_TEMPLATES (NOLOCK) WHERE ACC_TYPE_ID = 9000


SET @iso		= 'GEL'
SET @doc_type	= 42

IF (@template_41 IS NOT NULL) AND (@template_85 IS NOT NULL)
BEGIN
	SET @amount = @risk_accrue
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

	SET @debit		= CASE WHEN @amount > $0.00 THEN @account_85 ELSE @account_41 END
	SET @debit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_85 ELSE @acc_id_41 END
	SET @credit		= CASE WHEN @amount > $0.00 THEN @account_41 ELSE @account_85 END
	SET @credit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_41 ELSE @acc_id_85 END
	
	IF @guarantee = 0
	BEGIN
		SET @op_code = CASE WHEN @amount > $0.00 THEN '*LRS+' ELSE '*LRS-' END
		SET @descrip = CASE WHEN @amount > $0.00 THEN 'ÃÀÒÉÝáÅÀ ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÛÉ' ELSE 'ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÉÓ ÛÄÌÝÉÒÄÁÀ' END + ' (áÄËÛ. ' + @agreement_no + ')'
	END
	ELSE
	BEGIN
		SET @op_code = CASE WHEN @amount > $0.00 THEN '*GRS+' ELSE '*GRS-' END

		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip + CASE WHEN @amount > $0.00 THEN ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÂÀÒÀÍÔÉÉÓ ÒÄÆÄÒÅÉÓ ÛÄØÌÍÀ' ELSE ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÂÀÒÀÍÔÉÉÓ ÒÄÆÄÒÅÉÓ ÛÄÌÝÉÒÄÁÀ' END
		ELSE
			SET @descrip = @agreement_no + '/09/ÊÁ-ÆÄ (' + @client_descrip + CASE WHEN @amount > $0.00 THEN ') ÂÀÝÄÌÖËÉ ÂÀÒÀÍÔÉÉÓ ÒÄÆÄÒÅÉÓ ÛÄØÌÍÀ' ELSE ') ÂÀÝÄÌÖËÉ ÂÀÒÀÍÔÉÉÓ ÒÄÆÄÒÅÉÓ ÛÄÌÝÉÒÄÁÀ' END
	END
	
	SET @foreign_id	= CONVERT(int, @risk_category_date)
	SET @type_id	= 8000 * SIGN(@amount)

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, TYPE_ID)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END
ELSE
BEGIN
	SET @amount = @risk_category_1_balance_ - @risk_category_1_balance
	IF @amount <> $0.00
	BEGIN
		SET @account_41 = NULL
		SET @type_id = 8000
		IF @template_41 IS NULL
			SET @type_id = 8010
		
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_41 OUTPUT,
			@account	= @account_41 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @account_85 = NULL
		SET @type_id = 9000
		IF @template_85 IS NULL
			SET @type_id = 9010
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_85 OUTPUT,
			@account	= @account_85 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit		= CASE WHEN @amount > $0.00 THEN @account_85 ELSE @account_41 END
		SET @debit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_85 ELSE @acc_id_41 END
		SET @credit		= CASE WHEN @amount > $0.00 THEN @account_41 ELSE @account_85 END
		SET @credit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_41 ELSE @acc_id_85 END
		SET @op_code	= CASE WHEN @amount > $0.00 THEN '*LR1+' ELSE '*LR1-' END
		SET @descrip	= CASE WHEN @amount > $0.00 THEN 'ÃÀÒÉÝáÅÀ ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÛÉ (1 ÊÀÔÄÂÏÒÉÀ)' ELSE 'ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÉÓ ÛÄÌÝÉÒÄÁÀ (1 ÊÀÔÄÂÏÒÉÀ)' END + ' (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id	= CONVERT(int, @risk_category_date)
		SET @type_id	= 8010 * SIGN(@amount)

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, TYPE_ID)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END

	SET @amount = @risk_category_2_balance_ - @risk_category_2_balance
	IF @amount <> $0.00
	BEGIN
		SET @account_41 = NULL
		SET @type_id = 8000
		IF @template_41 IS NULL
			SET @type_id = 8020
		
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_41 OUTPUT,
			@account	= @account_41 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @account_85 = NULL
		SET @type_id = 9000
		IF @template_85 IS NULL
			SET @type_id = 9020
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_85 OUTPUT,
			@account	= @account_85 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit		= CASE WHEN @amount > $0.00 THEN @account_85 ELSE @account_41 END
		SET @debit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_85 ELSE @acc_id_41 END
		SET @credit		= CASE WHEN @amount > $0.00 THEN @account_41 ELSE @account_85 END
		SET @credit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_41 ELSE @acc_id_85 END
		SET @op_code	= CASE WHEN @amount > $0.00 THEN '*LR2+' ELSE '*LR2-' END
		SET @descrip	= CASE WHEN @amount > $0.00 THEN 'ÃÀÒÉÝáÅÀ ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÛÉ (2 ÊÀÔÄÂÏÒÉÀ)' ELSE 'ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÉÓ ÛÄÌÝÉÒÄÁÀ (2 ÊÀÔÄÂÏÒÉÀ)' END + ' (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id	= CONVERT(int, @risk_category_date)
		SET @type_id	= 8020 * SIGN(@amount)

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, TYPE_ID)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
	SET @amount = @risk_category_3_balance_ - @risk_category_3_balance
	IF @amount <> $0.00
	BEGIN
		SET @account_41 = NULL
		SET @type_id = 8000
		IF @template_41 IS NULL
			SET @type_id = 8030
		
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_41 OUTPUT,
			@account	= @account_41 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @account_85 = NULL
		SET @type_id = 9000
		IF @template_85 IS NULL
			SET @type_id = 9030
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_85 OUTPUT,
			@account	= @account_85 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit		= CASE WHEN @amount > $0.00 THEN @account_85 ELSE @account_41 END
		SET @debit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_85 ELSE @acc_id_41 END
		SET @credit		= CASE WHEN @amount > $0.00 THEN @account_41 ELSE @account_85 END
		SET @credit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_41 ELSE @acc_id_85 END
		SET @op_code	= CASE WHEN @amount > $0.00 THEN '*LR3+' ELSE '*LR3-' END
		SET @descrip	= CASE WHEN @amount > $0.00 THEN 'ÃÀÒÉÝáÅÀ ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÛÉ (3 ÊÀÔÄÂÏÒÉÀ)' ELSE 'ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÉÓ ÛÄÌÝÉÒÄÁÀ (3 ÊÀÔÄÂÏÒÉÀ)' END + ' (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id	= CONVERT(int, @risk_category_date)
		SET @type_id	= 8030 * SIGN(@amount)

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, TYPE_ID)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
	SET @amount = @risk_category_4_balance_ - @risk_category_4_balance
	IF @amount <> $0.00
	BEGIN
		SET @account_41 = NULL
		SET @type_id = 8000
		IF @template_41 IS NULL
			SET @type_id = 8040
		
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_41 OUTPUT,
			@account	= @account_41 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @account_85 = NULL
		SET @type_id = 9000
		IF @template_85 IS NULL
			SET @type_id = 9040
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_85 OUTPUT,
			@account	= @account_85 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit		= CASE WHEN @amount > $0.00 THEN @account_85 ELSE @account_41 END
		SET @debit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_85 ELSE @acc_id_41 END
		SET @credit		= CASE WHEN @amount > $0.00 THEN @account_41 ELSE @account_85 END
		SET @credit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_41 ELSE @acc_id_85 END
		SET @op_code	= CASE WHEN @amount > $0.00 THEN '*LR4+' ELSE '*LR4-' END
		SET @descrip	= CASE WHEN @amount > $0.00 THEN 'ÃÀÒÉÝáÅÀ ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÛÉ (4 ÊÀÔÄÂÏÒÉÀ)' ELSE 'ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÉÓ ÛÄÌÝÉÒÄÁÀ (4 ÊÀÔÄÂÏÒÉÀ)' END + ' (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id	= CONVERT(int, @risk_category_date)
		SET @type_id	= 8040 * SIGN(@amount)

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, TYPE_ID)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
	SET @amount = @risk_category_5_balance_ - @risk_category_5_balance
	IF @amount <> $0.00
	BEGIN
		SET @account_41 = NULL
		SET @type_id = 8000
		IF @template_41 IS NULL
			SET @type_id = 8050
		
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_41 OUTPUT,
			@account	= @account_41 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @account_85 = NULL
		SET @type_id = 9000
		IF @template_85 IS NULL
			SET @type_id = 9050

		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_85 OUTPUT,
			@account	= @account_85 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= @type_id,
			@loan_id	= @loan_id,
			@iso		= 'GEL',
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @debit		= CASE WHEN @amount > $0.00 THEN @account_85 ELSE @account_41 END
		SET @debit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_85 ELSE @acc_id_41 END
		SET @credit		= CASE WHEN @amount > $0.00 THEN @account_41 ELSE @account_85 END
		SET @credit_id	= CASE WHEN @amount > $0.00 THEN @acc_id_41 ELSE @acc_id_85 END
		SET @op_code	= CASE WHEN @amount > $0.00 THEN '*LR5+' ELSE '*LR5-' END
		SET @descrip	= CASE WHEN @amount > $0.00 THEN 'ÃÀÒÉÝáÅÀ ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÛÉ (5 ÊÀÔÄÂÏÒÉÀ)' ELSE 'ÓÀÒÄÆÄÒÅÏ ×ÏÍÃÉÓ ÛÄÌÝÉÒÄÁÀ (5 ÊÀÔÄÂÏÒÉÀ)' END + ' (áÄËÛ. ' + @agreement_no + ')'
		SET @foreign_id	= CONVERT(int, @risk_category_date)
		SET @type_id	= 8050 * SIGN(@amount)

		INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, TYPE_ID)
		VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
	END
END

IF (@simulate = 0)
	SET @doc_rec_id = NULL

IF @simulate = 0 AND @create_table = 1
BEGIN
	DECLARE 
		@rec_id int,
		@parent_rec_id int

	EXEC dbo.GET_SETTING_INT 'L_ACCR_RSK_DOC_STATE', @rec_state OUTPUT

	SET @rec_state = CASE WHEN @rec_state < 10 OR @rec_state > 20 THEN 10 ELSE @rec_state END 

	SET @parent_rec_id = 0
	IF (SELECT COUNT(*) FROM #docs) > 1
		SET @parent_rec_id = -1

	SET @doc_num = 1
	SET @doc_rec_id = NULL

	DECLARE cr CURSOR FOR
	SELECT DEBIT_ID, CREDIT_ID, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, TYPE_ID
	FROM #docs
	ORDER BY REC_ID

	OPEN cr
	FETCH NEXT FROM cr
	INTO @debit_id, @credit_id, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id

	WHILE @@FETCH_STATUS = 0
	BEGIN
        EXEC @r = dbo.ADD_DOC4
			@rec_id				= @rec_id OUTPUT,
			@user_id			= @user_id,
			@doc_type			= @doc_type, 
            @doc_num			= @doc_num,
			@doc_date			= @doc_date,
			@doc_date_in_doc	= @accrue_date,
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

			@check_saldo		= 0,
			@add_tariff			= 0,
			@info				= 0
		IF @@ERROR<>0 OR @r<>0 GOTO cr_ret

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
		IF @@ERROR<>0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÀÓÄÓáÏ ÍÀÛÈÉÓ ÝÅËÉËÄÁÉÓÀÓ!!!', 16, 1) RETURN (1) END

		FETCH NEXT FROM cr
		INTO @debit_id, @credit_id, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id
	END
GOTO cr_ok
cr_ret:
	CLOSE cr
	DEALLOCATE cr
	IF @internal_transaction=1 AND @@TRANCOUNT>0
	BEGIN
		IF @create_table = 1
			DROP TABLE #docs
		ROLLBACK
	END
	RETURN 1
cr_ok:
	CLOSE cr
	DEALLOCATE cr
END

IF @select_list = 1
	SELECT * FROM #docs
IF @create_table = 1
	DROP TABLE #docs

IF @simulate = 0 AND @create_table = 1 AND @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN (0)
GO
