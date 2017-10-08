SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[LOAN_SP_PROCESS_BEFORE_OP_ACCOUNTING]
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
	@loan_id int,
	@op_type smallint,
	@op_date smalldatetime,
	@op_amount money

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
	@branch_id int,
	@dept_no int,
	@agreement_no varchar(100),
	@disburse_type int,
	@loan_amount money,
	@loan_iso TISO
SELECT
	@branch_id		= BRANCH_ID,
	@dept_no		= DEPT_NO,
	@agreement_no	= AGREEMENT_NO,
	@disburse_type	= DISBURSE_TYPE,
	@loan_amount	= AMOUNT,
	@loan_iso		= ISO
FROM dbo.LOANS (NOLOCK)
WHERE LOAN_ID = @loan_id
SET @r = @@ROWCOUNT
IF @@ERROR<>0 OR @r<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

CREATE TABLE #docs(
	REC_ID		int PRIMARY KEY NOT NULL IDENTITY (1,1),
	DOC_DATE		smalldatetime	NOT NULL,
	DEBIT_ID		int,
	DEBIT			decimal(15,0)	NOT NULL,
	CREDIT_ID		int,
	CREDIT		decimal(15,0)	NOT NULL,
	ISO			char(3)			NOT NULL,
	AMOUNT		money			NOT NULL,
	DOC_TYPE		smallint		NOT NULL,
	OP_CODE		char(5)			collate database_default NOT NULL,
	DESCRIP		varchar(150)	collate database_default NOT NULL,
	FOREIGN_ID	int				NULL,
	TYPE_ID		int)

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
	@foreign_id		int,
	@type_id		int

SET @rec_state = 20 --ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÉÓ ßÉÍ ÓÀÁÖÈÄÁÉÓ ÀÅÔÏÒÉÆÀÝÉÉÓ ÃÏÍÄ(ÓÀàÉÒÏÄÁÉÓ ÛÄÌÈáÅÄÅÀÛÉ ÛÄÓÀÞËÄÁÄËÉÀ ÐÀÒÀÌÄÔÒÄÁÛÉ ÂÀÔÀÍÀ)


DECLARE
	@acc_id		int,
	@acc_added	bit,
	@bal_acc	TBAL_ACC

IF @op_type IN (dbo.loan_const_op_payment(), dbo.loan_const_op_overdue(), dbo.loan_const_op_writeoff(), dbo.loan_const_op_guar_payment())
-- ÏÐÄÒÀÝÉÄÁÉ ÒÏÌËÉÓ ßÉÍÀÝ ÀÖÝÉËÄÁËÀÃ ÖÍÃÀ ÛÄÓÒÖËÃÄÓ ÃÀÒÉÝáÅÀ: ÓÄÓáÉÓ ÃÀ×ÀÒÅÀ, ÓÄÓáÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ, ÓÄÓáÉÓ ÜÀÌÏßÄÒÀ.
BEGIN
	EXEC @r = dbo.LOAN_SP_ACCRUAL_INTEREST_INTERNAL
		@accrue_date					= @doc_date,
		@loan_id						= @loan_id,
		@user_id						= @user_id,
		@create_table					= 1,
		@simulate						= @simulate
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END

IF @op_type = dbo.loan_const_op_writeoff()
-- ÏÐÄÒÀÝÉÄÁÉ ÒÏÌËÉÓ ßÉÍÀÝ ÀÖÝÉËÄÁËÀÃ ÖÍÃÀ ÛÄÓÒÖËÃÄÓ ÒÄÆÄÒÅÉÓ ÃÀÒÉÝáÅÀ: ÓÄÓáÉÓ ÃÀ×ÀÒÅÀ, ÓÄÓáÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ, ÓÄÓáÉÓ ÜÀÌÏßÄÒÀ.
BEGIN
	EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
		@accrue_date					= @doc_date,
		@loan_id						= @loan_id,
		@user_id						= @user_id,
		@create_table					= 1,
		@simulate						= @simulate
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END
END

IF @simulate = 0
BEGIN
	DECLARE 
		@rec_id int,
		@parent_rec_id int

	SET @parent_rec_id = 0
	IF (SELECT COUNT(*) FROM #docs) > 1
		SET @parent_rec_id = -1

	SET @doc_num = 1
	SET @doc_rec_id = NULL

	DECLARE cr CURSOR FOR
	SELECT DOC_DATE, DEBIT_ID, CREDIT_ID, ISO, AMOUNT, DOC_TYPE, OP_CODE, DESCRIP, FOREIGN_ID, TYPE_ID
	FROM #docs
	ORDER BY REC_ID

	OPEN cr
	FETCH NEXT FROM cr
	INTO @doc_date, @debit_id, @credit_id, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id

	WHILE @@FETCH_STATUS = 0
	BEGIN
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

		IF @@ERROR<>0 OR @r <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÀÓÄÓáÏ ÍÀÛÈÉÓ ÝÅËÉËÄÁÉÓÀÓ!!!', 16, 1) RETURN (1) END

		FETCH NEXT FROM cr
		INTO @doc_date, @debit_id, @credit_id, @iso, @amount, @doc_type, @op_code, @descrip, @foreign_id, @type_id
	END
GOTO cr_ok
cr_ret:
	CLOSE cr
	DEALLOCATE cr
	IF @internal_transaction=1 AND @@TRANCOUNT>0
	BEGIN
		DROP TABLE #docs
		ROLLBACK
		RETURN 1
	END
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
