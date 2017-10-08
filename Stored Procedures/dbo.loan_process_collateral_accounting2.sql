SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[loan_process_collateral_accounting2]
	@op_id int,
	@user_id int,
	@doc_date smalldatetime,
	@l_technical_999 TACCOUNT,
	@head_branch_id int,
	@only_close bit,
	@by_processing bit = 0,
	@simulate bit = 0
AS
SET NOCOUNT ON;

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

DECLARE -- Op Data
	@credit_line_id int,
	@op_type smallint,
	@op_date smalldatetime,
	@op_amount TAMOUNT

SELECT
	@credit_line_id = CREDIT_LINE_ID,
	@op_type = OP_TYPE,
	@op_date = OP_DATE,
	@op_amount = AMOUNT
FROM dbo.LOAN_GEN_AGREE_OPS (NOLOCK)
WHERE OP_ID = @op_id

SELECT @r = @@ROWCOUNT
IF @@ERROR<>0 OR @r<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

IF @doc_date IS NULL
	SET @doc_date = @op_date

DECLARE -- Credit Line Data
	@l_technical_999_id int,
	@branch_id int,
	@dept_no int,
	@agreement_no varchar(100),
	@product_id int,
	@disburse_type int,
	@loan_amount TAMOUNT,
	@credit_line_iso TISO,
	@writeoff_date smalldatetime,
	@client_descrip varchar(100),
	@client_no int

SELECT
	@branch_id			= L.BRANCH_NO,
	@dept_no			= L.DEPT_NO,
	@agreement_no		= L.AGREEMENT_NO,
	@loan_amount		= L.AMOUNT,
	@credit_line_iso	= L.ISO,
	@client_descrip		= C.DESCRIP,
	@client_no			= L.CLIENT_NO
FROM dbo.LOAN_CREDIT_LINES L (NOLOCK)
	INNER JOIN dbo.CLIENTS C (NOLOCK) ON L.CLIENT_NO = C.CLIENT_NO
WHERE L.CREDIT_LINE_ID = @credit_line_id
SET @r = @@ROWCOUNT
IF @@ERROR<>0 OR @r<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END


DECLARE
	@rec_state tinyint,
	@debit_id int,
	@debit TACCOUNT,
	@credit_id int,
	@credit TACCOUNT,
	@acc_id int,
	@acc_added bit,
	@bal_acc TBAL_ACC,
	@acc_type_id int,
	@account_type_descrip varchar(150),
	@doc_type smallint,
	@op_code TOPCODE,
	@descrip TDESCRIP,
	@foreign_id int,
	@type_id int,
	@check_saldo bit

	SET @rec_state = 20

IF @by_processing = 1
	SET @rec_state = 20
ELSE
	SELECT @rec_state = DOC_REC_STATE FROM dbo.LOAN_GEN_AGREE_OP_TYPES (NOLOCK) WHERE [TYPE_ID] = @op_type


DECLARE
	@collateral_id int,
	@iso TISO,
	@collateral_type int,
	@amount money 

DECLARE cr CURSOR FAST_FORWARD FOR
SELECT COLLATERAL_ID, ISO, COLLATERAL_TYPE, AMOUNT FROM dbo.LOAN_VW_OP_LOAN_COLLATERALS2 (NOLOCK)
WHERE OP_ID = @op_id AND IS_LINKED = 0

OPEN cr

FETCH NEXT FROM cr INTO @collateral_id, @iso, @collateral_type, @amount 

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @debit_id = NULL
	SET @debit = NULL
	SET @credit_id = NULL
	SET @credit = NULL
	SET @l_technical_999_id = NULL

	SET @acc_type_id = 10000 + @collateral_type 

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT2
		@acc_id			= @credit_id OUTPUT,
		@account		= @credit OUTPUT,
		@acc_added		= @acc_added OUTPUT,
		@bal_acc		= @bal_acc OUTPUT,
		@type_id		= @acc_type_id,
		@credit_line_id	= @credit_line_id,
		@iso			= @iso,
		@user_id		= @user_id,
		@simulate		= 0,
		@guarantee		= 0
	IF @@ERROR<>0 OR @r<>0 GOTO cr_ret_cr

	SET @l_technical_999_id = dbo.acc_get_acc_id(@head_branch_id, @l_technical_999, @iso)
	SET @debit_id = @l_technical_999_id
	IF @debit_id IS NULL
	BEGIN
		SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
		RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
		GOTO cr_ret_cr
	END
	SET @debit			= @l_technical_999

	SET @iso			= @iso
	SET @amount			= @amount
	SET @doc_type		= 240
	SET @op_code		= '*LC-'
	SET @descrip		= @client_descrip + ' (' + Convert(varchar(20), @client_no) + ') ÊËÉÄÍÔÆÄ ÃÀÌÔÊÉÝÄÁÖËÉ ÂÄÍ.áÄËÛÄÊÒÖËÄÁÉÓ ÖÆÒÖÍÅÄËÚÏ×À'
	SET @foreign_id		= NULL
	SET @type_id		= 0
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 GOTO cr_ret_cr

	FETCH NEXT FROM cr INTO @collateral_id, @iso, @collateral_type, @amount 
END

CLOSE cr
DEALLOCATE cr

IF @only_close = 1
	GOTO ret

DECLARE cr2 CURSOR FAST_FORWARD FOR
SELECT COLLATERAL_ID, ISO, COLLATERAL_TYPE, AMOUNT FROM dbo.LOAN_COLLATERALS (NOLOCK)
WHERE CREDIT_LINE_ID = @credit_line_id

OPEN cr2

FETCH NEXT FROM cr2 INTO @collateral_id, @iso, @collateral_type, @amount 

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @debit_id = NULL
	SET @debit = NULL
	SET @credit_id = NULL
	SET @credit = NULL
	SET @l_technical_999_id = NULL

	SET @acc_type_id = 10000 + @collateral_type 

	EXEC @r = dbo.LOAN_SP_GET_ACCOUNT2
		@acc_id			= @debit_id OUTPUT,
		@account		= @debit OUTPUT,
		@acc_added		= @acc_added OUTPUT,
		@bal_acc		= @bal_acc OUTPUT,
		@type_id		= @acc_type_id,
		@credit_line_id	= @credit_line_id,
		@iso			= @iso,
		@user_id		= @user_id,
		@simulate		= 0,
		@guarantee		= 0
	IF @@ERROR<>0 OR @r<>0 GOTO cr_ret_cr2

	SET @l_technical_999_id = dbo.acc_get_acc_id(@head_branch_id, @l_technical_999, @iso)
	SET @credit_id = @l_technical_999_id
	IF @credit_id IS NULL
	BEGIN
		SELECT @account_type_descrip = convert(varchar(50), @l_technical_999) 
		RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
		GOTO cr_ret_cr2
	END
	SET @credit			= @l_technical_999

	SET @iso			= @iso
	SET @amount			= @amount
	SET @doc_type		= 240
	SET @op_code		= '*LC+'
	SET @descrip		= @client_descrip + ' (' + Convert(varchar(20), @client_no) + ') ÊËÉÄÍÔÆÄ ÃÀÌÔÊÉÝÄÁÖËÉ ÂÄÍ.áÄËÛÄÊÒÖËÄÁÉÓ ÖÆÒÖÍÅÄËÚÏ×À'
	SET @foreign_id		= NULL
	SET @type_id		= 0
	SET @check_saldo	= 0

	INSERT INTO #docs(DOC_DATE, DEBIT_ID, DEBIT, CREDIT_ID, CREDIT, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, [TYPE_ID], CHECK_SALDO)
	VALUES (@doc_date, @debit_id, @debit, @credit_id, @credit, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id, @check_saldo)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 GOTO cr_ret_cr2
	
	FETCH NEXT FROM cr2 INTO @collateral_id, @iso, @collateral_type, @amount
END

CLOSE cr2
DEALLOCATE cr2

GOTO ret

cr_ret_cr:
	CLOSE cr
	DEALLOCATE cr
	IF @internal_transaction=1 AND @@TRANCOUNT>0
		ROLLBACK
	RETURN 1

cr_ret_cr2:
	CLOSE cr2
	DEALLOCATE cr2
	IF @internal_transaction=1 AND @@TRANCOUNT>0
		ROLLBACK
	RETURN 1

ret:

IF @simulate = 0 AND @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN (0)

GO
