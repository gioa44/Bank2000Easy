SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[LOAN_SP_ACCRUAL_INTEREST]
/*1. ÃÀÀÁÒÖÍÏÓ ÐÀÒÀÌÄÔÒÄÁÛÉ ÃÀÒÉÝáÅÉÓ ÌÏÍÀÝÄÌÄÁÉ -> @return_params
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
	@accrue_type					tinyint = 1, -- 1 == ÃÀÒÉÝáÅÀ ÌÏÃÖËÉÃÀÍ; 2 == ÃÀÒÉÝáÅÀ ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÉÓÀÓ; 3 == ÃÀÒÉÝáÅÀ ÐÒÏÝÄÓÉÍÂÉÓ ÃÒÏÓ
	@accrue							bit = 1,
	@interest_date					smalldatetime OUTPUT,
	@interest_balance				TAMOUNT OUTPUT,
	@interest_balance_				TAMOUNT OUTPUT,
	@interest2accrue				TAMOUNT OUTPUT,
	@overdue_interest_date			smalldatetime OUTPUT,
	@overdue_interest_balance		TAMOUNT OUTPUT,
	@overdue_interest30_date		smalldatetime OUTPUT,
	@overdue_interest30_balance		TAMOUNT OUTPUT,
	@overdue_interest30_balance_	TAMOUNT OUTPUT,
	@overdue_interest302accrue		TAMOUNT OUTPUT,
	@penalty_date					smalldatetime OUTPUT,
	@penalty_balance				TAMOUNT OUTPUT,
	@penalty_balance_				TAMOUNT OUTPUT,
	@penalty2accrue					TAMOUNT OUTPUT,
	@writeoff_date					smalldatetime OUTPUT,
	@writeoff_balance				TAMOUNT OUTPUT,
	@writeoff_balance_				TAMOUNT OUTPUT,
	@writeoff2accrue				TAMOUNT OUTPUT
AS
SET NOCOUNT ON

IF (@accrue = 0)
	RETURN (0)

SELECT
	@interest_date = INTEREST_DATE, @interest_balance = ISNULL(INTEREST_BALANCE, $0.00),
	@overdue_interest_date = OVERDUE_INTEREST_DATE, @overdue_interest_balance = ISNULL(OVERDUE_INTEREST_BALANCE, $0.00),
	@overdue_interest30_date = OVERDUE_INTEREST30_DATE, @overdue_interest30_balance = ISNULL(OVERDUE_INTEREST30_BALANCE, $0.00),
	@penalty_date = PENALTY_DATE, @penalty_balance = ISNULL(PENALTY_BALANCE, $0.00),
	@writeoff_date = WRITEOFF_DATE, @writeoff_balance = ISNULL(WRITEOFF_BALANCE, $0.00)
FROM dbo.LOAN_ACCOUNT_BALANCE
WHERE LOAN_ID = @loan_id

SELECT
	@interest_balance_ = ISNULL(NU_INTEREST, $0.00) + ISNULL(INTEREST, $0.00) + ISNULL(OVERDUE_PRINCIPAL_INTEREST, $0.00) + ISNULL(CALLOFF_PRINCIPAL_INTEREST, $0.00) + ISNULL(DEFERABLE_INTEREST, $0.00),
	@penalty_balance_ = ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00) + ISNULL(OVERDUE_PERCENT_PENALTY, $0.00) + ISNULL(CALLOFF_PRINCIPAL_PENALTY, $0.00) + ISNULL(CALLOFF_PERCENT_PENALTY, $0.00) + ISNULL(DEFERABLE_PENALTY, $0.00),
	@writeoff_balance_ = ISNULL(WRITEOFF_PRINCIPAL_PENALTY, $0.00) + ISNULL(WRITEOFF_PERCENT, $0.00) + ISNULL(WRITEOFF_PERCENT_PENALTY, $0.00) + ISNULL(WRITEOFF_PENALTY, $0.00)
FROM dbo.LOAN_DETAILS
WHERE LOAN_ID = @loan_id

SELECT @overdue_interest30_balance_ = ISNULL(SUM(ISNULL(OVERDUE_PERCENT, $0.00)), $0.00)
FROM dbo.LOAN_DETAIL_OVERDUE
WHERE LOAN_ID = @loan_id AND DATEDIFF(dd, OVERDUE_DATE, @accrue_date) > 30

SET @interest2accrue			= ISNULL(@interest_balance_, $0.00) - ISNULL(@interest_balance, $0.00)
SET @overdue_interest302accrue	= ISNULL(@overdue_interest30_balance_, $0.00) - ISNULL(@overdue_interest30_balance, $0.00)
SET @penalty2accrue				= ISNULL(@penalty_balance_, $0.00) - ISNULL(@penalty_balance, $0.00)
SET @writeoff2accrue			= ISNULL(@writeoff_balance_, $0.00) - ISNULL(@writeoff_balance, $0.00)

IF @return_params = 1
	RETURN (0)

DECLARE
	@accrue_interest bit,
	@accrue_overdue_interest30 bit,
	@accrue_penalty	bit,
	@accrue_writeoff bit

SET	@accrue_interest	= 1
SET	@accrue_overdue_interest30	= 0 --giorgia change 1 to 0
SET	@accrue_penalty		= 1
SET	@accrue_writeoff	= 1

IF (@interest2accrue = $0.00) AND (@accrue_interest = 1)
	SET @accrue_interest = 0
IF (@overdue_interest302accrue = $0.00) AND (@accrue_overdue_interest30 = 1)
	SET @accrue_overdue_interest30 = 0
IF (@penalty2accrue = $0.00) AND (@accrue_penalty = 1)
	SET @accrue_penalty = 0
IF (@writeoff2accrue = $0.00) AND (@accrue_writeoff = 1)
	SET @accrue_writeoff = 0

IF (@accrue_interest = 0) AND (@accrue_overdue_interest30 = 0) AND (@accrue_penalty = 0) AND (@accrue_writeoff = 0)
	RETURN (0)


DECLARE
	@r int

DECLARE -- Loan Data
	@head_branch_id int,
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
	@client_descrip = C.DESCRIP
FROM dbo.LOANS L (NOLOCK)
	INNER JOIN dbo.CLIENTS C (NOLOCK) ON L.CLIENT_NO = C.CLIENT_NO
	LEFT JOIN dbo.LOAN_ATTRIBUTES LA1 (NOLOCK) ON L.LOAN_ID = LA1.LOAN_ID AND LA1.ATTRIB_CODE = 'GUARTYPE'
	LEFT JOIN dbo.LOAN_ATTRIBUTES LA2 (NOLOCK) ON L.LOAN_ID = LA2.LOAN_ID AND LA2.ATTRIB_CODE = 'PURPCODE'
WHERE L.LOAN_ID = @loan_id
SELECT @r = @@ROWCOUNT
IF @@ERROR<>0 OR @r<>1 RETURN 11 

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
		[REC_ID]		int PRIMARY KEY NOT NULL IDENTITY (1,1),
		[DOC_DATE]		smalldatetime	NOT NULL,
		[DEBIT_ID]		int NULL,
		[DEBIT]			decimal(15,0)	NOT NULL,
		[CREDIT_ID]		int NULL,
		[CREDIT]		decimal(15,0)	NOT NULL,
		[ISO]			char(3)			NOT NULL,
		[AMOUNT]		money			NOT NULL,
		[DOC_TYPE]		smallint		NOT NULL,
		[OP_CODE]		char(5)			collate database_default NOT NULL,
		[DESCRIP]		varchar(150)	collate database_default NOT NULL,
		[FOREIGN_ID]	int				NULL,
		[TYPE_ID]		int				NOT NULL)
END

DECLARE
	@doc_num		int,
	@debit_id		int,
	@debit			TACCOUNT,
	@credit_id		int,
	@credit			TACCOUNT,
	@iso			TISO,
	@amount			TAMOUNT,
	@doc_type		smallint,
	@op_code		TOPCODE,
	@rec_state		tinyint,
	@descrip		TDESCRIP,
	@foreign_id		int,
	@type_id		int

DECLARE
	@account_tmp_1	TACCOUNT,
	@account_tmp_2	TACCOUNT

DECLARE
	@acc_id int,
	@acc_id_tmp_1 int,
	@acc_id_tmp_2 int,
	@acc_added	bit,
	@bal_acc	TBAL_ACC

DECLARE
	@l_technical_999 TACCOUNT,
	@l_technical_999_id int

EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO', @head_branch_id OUTPUT	--ÓÀÈÀÏ ×ÉËÉÀËÉÓ ÍÏÌÄÒÉ

EXEC dbo.GET_SETTING_INT 'L_TECHNICAL_999', @l_technical_999 OUTPUT	--ÔÄØÍÉÊÖÒÉ ÀÍÂÀÒÉÛÉ ÂÀÒÄÁÀËÀÍÓÄÁÉÓÈÅÉÓ
SET @l_technical_999_id = dbo.acc_get_acc_id(@head_branch_id, @l_technical_999, @loan_iso)

IF @accrue_interest = 1
BEGIN
	SET @account_tmp_1 = NULL
	SET @account_tmp_2 = NULL
	SET @acc_id_tmp_1 = NULL
	SET @acc_id_tmp_2 = NULL
	SET @bal_acc = NULL

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @acc_id_tmp_1 OUTPUT,
		@account	= @account_tmp_1 OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 1030,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @acc_id_tmp_2 OUTPUT,
		@account	= @account_tmp_2 OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 1130,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @debit_id		= CASE WHEN @interest2accrue > 0 THEN @acc_id_tmp_1 ELSE @acc_id_tmp_2 END
	SET @debit			= CASE WHEN @interest2accrue > 0 THEN @account_tmp_1 ELSE @account_tmp_2 END
	SET @credit_id		= CASE WHEN @interest2accrue > 0 THEN @acc_id_tmp_2 ELSE @acc_id_tmp_1 END
	SET @credit			= CASE WHEN @interest2accrue > 0 THEN @account_tmp_2 ELSE @account_tmp_1 END
	SET @iso			= @loan_iso
	SET @amount			= @interest2accrue
	SET @doc_type		= 40
	IF @guarantee = 0
	BEGIN
		SET @op_code		= CASE WHEN @amount > $0.00 THEN '*LI+' ELSE '*LI-' END
		SET @descrip		= CASE WHEN @amount > $0.00 THEN 'ÃÀÂÒÏÅÉËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÃÀÒÉÝáÅÀ' ELSE 'ÃÀÒÉÝáÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÛÄÌÝÉÒÄÁÀ' END + ' (áÄËÛ. ' + @agreement_no + ')'
	END
	ELSE
	BEGIN
		SET @op_code		= CASE WHEN @amount > $0.00 THEN '*GI+' ELSE '*GI-' END

		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip + CASE WHEN @amount > $0.00 THEN ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÌÉáÄÃÅÉÈ ÐÒÏÝÄÍÔÖËÉ ÛÄÌÏÓÀÅËÄÁÉÓ ÀÙÉÀÒÄÁÀ' ELSE ')-ÆÄ ÂÀÝÄÌÖËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÌÉáÄÃÅÉÈ ÐÒÏÝÄÍÔÖËÉ ÛÄÌÏÓÀÅËÄÁÉÓ ÛÄÌÝÉÒÄÁÀ' END
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ-ÆÄ (' + @client_descrip + CASE WHEN @amount > $0.00 THEN ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÌÉáÄÃÅÉÈ ÐÒÏÝÄÍÔÖËÉ ÛÄÌÏÓÀÅËÄÁÉÓ ÀÙÉÀÒÄÁÀ' ELSE ') ÂÀÝÄÌÖËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÌÉáÄÃÅÉÈ ÐÒÏÝÄÍÔÖËÉ ÛÄÌÏÓÀÅËÄÁÉÓ ÛÄÌÝÉÒÄÁÀ' END
	END
	SET @foreign_id		= CONVERT(int, @interest_date)
	SET @type_id		= 1030 * SIGN(@amount)

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID])
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END

IF @accrue_overdue_interest30 = 1
BEGIN
	SET @account_tmp_1 = NULL
	SET @account_tmp_2 = NULL
	SET @acc_id_tmp_1 = NULL
	SET @acc_id_tmp_2 = NULL
	SET @bal_acc = NULL

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @acc_id_tmp_1 OUTPUT,
		@account	= @account_tmp_1 OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 60,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	IF @bal_acc > 999.99
	BEGIN 
		EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
			@acc_id		= @acc_id_tmp_2 OUTPUT,
			@account	= @account_tmp_2 OUTPUT,
			@acc_added	= @acc_added OUTPUT,
			@bal_acc	= @bal_acc OUTPUT,
			@type_id	= 1160,
			@loan_id	= @loan_id,
			@iso		= @loan_iso,
			@user_id	= @user_id,
			@simulate	= @simulate,
			@guarantee	= @guarantee
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

		SET @doc_type		= 40
	END
	ELSE
	BEGIN
		SET @acc_id_tmp_2 = @l_technical_999_id
		SET @account_tmp_2	= @l_technical_999
		SET @doc_type		= 240
	END

	SET @debit_id		= @acc_id_tmp_2 
	SET @debit			= @account_tmp_2
	SET @credit_id		= @acc_id_tmp_1 
	SET @credit			= @account_tmp_1
	SET @iso			= @loan_iso
	SET @amount			= @overdue_interest302accrue
	SET @doc_type		= @doc_type
	IF @guarantee = 0
	BEGIN
		SET @op_code		= '*LOI-'
		SET @descrip		= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÉÓ ÛÄÌÝÉÒÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
	END
	ELSE
	BEGIN
		SET @op_code		= '*GOI-'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ') ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÄÁÉÓ ÜÀÌÏßÄÒÀ ÁÀËÀÍÓÉÃÀÍ'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ-ÆÄ (' + @client_descrip + ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÏÌÓÀáÖÒÄÁÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÄÁÉÓ ÜÀÌÏßÄÒÀ ÁÀËÀÍÓÉÃÀÍ'
	END
	SET @foreign_id		= CONVERT(int, @overdue_interest_date)
	SET @type_id		= -1160

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID])
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @account_tmp_1 = NULL
	SET @account_tmp_2 = NULL
	SET @acc_id_tmp_1 = NULL
	SET @acc_id_tmp_2 = NULL
	SET @bal_acc = NULL

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @acc_id_tmp_1 OUTPUT,
		@account	= @account_tmp_1 OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 2060,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @acc_id_tmp_2 = @l_technical_999_id
	SET @account_tmp_2	= @l_technical_999
	SET @doc_type		= 240

	SET @debit_id		= @acc_id_tmp_1 
	SET @debit			= @account_tmp_1
	SET @credit_id		= @acc_id_tmp_2 
	SET @credit			= @account_tmp_2
	SET @iso			= @loan_iso
	SET @amount			= @overdue_interest302accrue
	SET @doc_type		= @doc_type
	IF @guarantee = 0
	BEGIN
		SET @op_code		= '*L30+'
		SET @descrip		= '30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÉÈ ÌÉÖÙÄÁÄËÉ ÓÀÐÒÏÝÄÍÔÏ ÃÀÅÀËÉÀÍÄÁÀ (áÄËÛ. ' + @agreement_no + ')'
	END
	ELSE
	BEGIN
		SET @op_code		= '*G30+'
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip +  ') ÁÀËÀÍÓÉÃÀÍ ÜÀÌÏßÄÒÉËÉ ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ %'
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ-ÆÄ (' + @client_descrip + ') ÁÀËÀÍÓÉÃÀÍ ÜÀÌÏßÄÒÉËÉ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ 30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ %'
	END

	SET @foreign_id		= CONVERT(int, @overdue_interest30_date)
	SET @type_id		= 2060

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID])
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END

IF @accrue_penalty = 1
BEGIN
	SET @account_tmp_1 = NULL
	SET @account_tmp_2 = NULL
	SET @acc_id_tmp_1 = NULL
	SET @acc_id_tmp_2 = NULL
	SET @bal_acc = NULL

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT
		@acc_id		= @acc_id_tmp_1 OUTPUT,
		@account	= @account_tmp_1 OUTPUT,
		@acc_added	= @acc_added OUTPUT,
		@bal_acc	= @bal_acc OUTPUT,
		@type_id	= 2000,
		@loan_id	= @loan_id,
		@iso		= @loan_iso,
		@user_id	= @user_id,
		@simulate	= @simulate,
		@guarantee	= @guarantee
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	SET @acc_id_tmp_2	= @l_technical_999_id
	SET @account_tmp_2	= @l_technical_999
	SET @doc_type		= 240
	SET @amount			= @penalty2accrue


	SET @debit_id		= CASE WHEN @amount > 0 THEN @acc_id_tmp_1 ELSE @acc_id_tmp_2 END
	SET @debit			= CASE WHEN @amount > 0 THEN @account_tmp_1 ELSE @account_tmp_2 END
	SET @credit_id		= CASE WHEN @amount > 0 THEN @acc_id_tmp_2 ELSE @acc_id_tmp_1 END
	SET @credit			= CASE WHEN @amount > 0 THEN @account_tmp_2 ELSE @account_tmp_1 END

	SET @iso			= @loan_iso
	SET @doc_type		= @doc_type

	IF @guarantee = 0
	BEGIN
		SET @op_code		= CASE WHEN @amount > $0.00 THEN '*LPI+' ELSE '*LPI-' END
		SET @descrip		= CASE WHEN @amount > $0.00 THEN 'ÃÀÂÒÏÅÉËÉ ãÀÒÉÌÉÓ ÃÀÒÉÝáÅÀ' ELSE 'ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÛÄÌÝÉÒÄÁÀ' END + ' (áÄËÛ. ' + @agreement_no + ')'
	END
	ELSE
	BEGIN
		SET @op_code		= CASE WHEN @amount > $0.00 THEN '*GPI+' ELSE '*GPI-' END
		IF @guarantee_internat = 1
			SET @descrip = @agreement_no + '/' + @guarantee_purpose_code +  ' (' + @client_descrip + CASE WHEN @amount > $0.00 THEN ') ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ ÌÉÓÀÙÄÁÉ ãÀÒÉÌÉÓ ÃÀÒÉÝáÅÀ' ELSE ') ÓÀÄÒÈÀÛÏÒÉÓÏ ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ ÌÉÓÀÙÄÁÉ ãÀÒÉÌÉÓ ÛÄÌÝÉÒÄÁÀ' END
		ELSE
			SET @descrip		= @agreement_no + '/09/ÊÁ-ÆÄ (' + @client_descrip + CASE WHEN @amount > $0.00 THEN ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ ÌÉÓÀÙÄÁÉ ãÀÒÉÌÉÓ ÃÀÒÉÝáÅÀ' ELSE ') ÓÀÁÀÍÊÏ ÂÀÒÀÍÔÉÉÓ ÌÉáÄÃÅÉÈ ÌÉÓÀÙÄÁÉ ãÀÒÉÌÉÓ ÛÄÌÝÉÒÄÁÀ' END
	END

	SET @foreign_id		= CONVERT(int, @interest_date)
	SET @type_id		= 2000 * SIGN(@amount)

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID])
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, ABS(@amount), @doc_type, @op_code, @descrip, @foreign_id, @type_id)
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END

IF (@simulate = 0)
	SET @doc_rec_id = NULL

IF @simulate = 0 AND @create_table = 1
BEGIN
	DECLARE 
		@rec_id int,
		@parent_rec_id int

	EXEC dbo.GET_SETTING_INT 'L_ACCR_INT_DOC_STATE', @rec_state OUTPUT

	SET @rec_state = CASE WHEN @rec_state < 10 OR @rec_state > 20 THEN 10 ELSE @rec_state END 

	SET @parent_rec_id = 0
	IF (SELECT COUNT(*) FROM #docs) > 1
		SET @parent_rec_id = -1

	SET @doc_num = 1
	SET @doc_rec_id = NULL

	DECLARE cr CURSOR FOR
	SELECT DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID]
	FROM #docs
	ORDER BY REC_ID

	OPEN cr
	FETCH NEXT FROM cr
	INTO @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id

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
		INTO @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id
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
