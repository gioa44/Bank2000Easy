SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_PROCESS_OP_ACCOUNTING2]
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
	@account_type_descrip varchar(150)

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


DECLARE -- Loan Data
	@head_branch_id int,
	@branch_id int,
	@dept_no int,
	@credit_line_iso TISO,
	@client_descrip varchar(100)

SELECT
	@branch_id		= BRANCH_NO,
	@dept_no		= DEPT_NO,
	@credit_line_iso= ISO
FROM dbo.LOAN_CREDIT_LINES (NOLOCK)
WHERE CREDIT_LINE_ID = @credit_line_id
SET @r = @@ROWCOUNT
IF @@ERROR<>0 OR @r<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

SET @client_descrip = Null

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
	@l_technical_999_id int

SET @iso2 = NULL
SET @amount2 = NULL
SET @doc_rec_id2 = NULL


EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO', @head_branch_id OUTPUT	--ÓÀÈÀÏ ×ÉËÉÀËÉÓ ÍÏÌÄÒÉ

EXEC dbo.GET_SETTING_INT 'L_TECHNICAL_999', @l_technical_999 OUTPUT	--ÔÄØÍÉÊÖÒÉ ÀÍÂÀÒÉÛÉ ÂÀÒÄÁÀËÀÍÓÄÁÉÓÈÅÉÓ
SET @l_technical_999_id = dbo.acc_get_acc_id(@head_branch_id, @l_technical_999, @credit_line_iso)

IF @by_processing = 1
	SET @rec_state = 20
ELSE
	SELECT @rec_state = DOC_REC_STATE FROM dbo.LOAN_GEN_AGREE_OP_TYPES (NOLOCK) WHERE [TYPE_ID] = @op_type


DECLARE
	@acc_id		int,
	@acc_added	bit,
	@bal_acc	TBAL_ACC


IF @op_type IN (dbo.loan_const_gen_agree_op_approval(), dbo.loan_const_gen_agree_op_restruct_collat(), dbo.loan_const_gen_agree_op_correct_collat())
BEGIN
	EXEC @r = dbo.loan_process_collateral_accounting2
		@op_id = @op_id,
		@user_id = @user_id,
		@doc_date = @doc_date,
		@l_technical_999 = @l_technical_999,
		@head_branch_id = @head_branch_id,
		@only_close = 0,
		@by_processing = @by_processing,
		@simulate = @simulate
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END

IF @op_type = dbo.loan_const_gen_agree_op_close()
BEGIN
	EXEC @r = dbo.loan_process_collateral_accounting2
		@op_id = @op_id,
		@user_id = @user_id,
		@doc_date = @doc_date,
		@l_technical_999 = @l_technical_999,
		@head_branch_id = @head_branch_id,
		@only_close = 1,
		@by_processing = @by_processing,
		@simulate = @simulate
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END

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
	IF (SELECT COUNT(*) FROM #docs) > 1
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
				@account_extra		= @credit_line_id,
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
				@account_extra		= @credit_line_id,
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
	UPDATE dbo.LOAN_GEN_AGREE_OPS
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
