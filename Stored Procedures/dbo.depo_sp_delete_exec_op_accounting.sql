SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_delete_exec_op_accounting]
	@doc_rec_id int,
	@accrue_doc_rec_id	int,
	@op_id int,
	@user_id int,
	@op_docs_deleted bit OUTPUT,
	@accrue_docs_deleted bit OUTPUT
AS
SET NOCOUNT ON;

DECLARE 
	@r int

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE
	@depo_id int,
	@op_date smalldatetime,
	@op_type smallint


SELECT @depo_id = DEPO_ID, @op_date = OP_DATE, @op_type = OP_TYPE
FROM dbo.DEPO_OP (NOLOCK)
WHERE OP_ID = @op_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION NOT FOUND', 16, 1); RETURN (1); END

IF dbo.bank_open_date() > @op_date
BEGIN
	IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; 
	RAISERROR ('ÏÐÄÒÀÝÉÉÓ ÈÀÒÉÙÉ ÃÀáÖÒÖËÉ ÃÙÄÀ!', 16, 1);
	RETURN (1);
END


DECLARE
	@doc_rec_state tinyint,
	@parent_rec_id int,
	@add_with_accounting bit,
	@accrue_before_add bit,
	@doc_type smallint,
	@op_doc_rec_state tinyint,
	@op_doc_rec_state_cash tinyint

IF (@op_type IN (dbo.depo_fn_const_op_realize_interest(), dbo.depo_fn_const_op_withdraw_interest_tax())) AND (@doc_rec_id IS NOT NULL)
BEGIN
	SELECT @parent_rec_id = PARENT_REC_ID
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE REC_ID = @doc_rec_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR READING DOC DATA', 16, 1); RETURN (1); END

	IF (ISNULL(@parent_rec_id, 0) > 0)
		UPDATE dbo.OPS_0000 WITH (UPDLOCK)
		SET [UID] = [UID] + 1, FLAGS = 0
		WHERE REC_ID = @parent_rec_id

	UPDATE dbo.OPS_0000 WITH (UPDLOCK)
	SET [UID] = [UID] + 1, FLAGS = 0
	WHERE REC_ID = @doc_rec_id
END

SET @op_doc_rec_state = NULL
SET @op_doc_rec_state_cash = NULL

SELECT @add_with_accounting = ADD_WITH_ACCOUNTING, @accrue_before_add = ACCRUE_BEFORE_ADD, @op_doc_rec_state = DOC_REC_STATE, @op_doc_rec_state_cash = DOC_REC_STATE_CASH
FROM dbo.DEPO_OP_TYPES (NOLOCK)
WHERE [TYPE_ID] = @op_type
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION TYPE SETTINGS NOT FOUND', 16, 1); RETURN (1); END

SET @op_docs_deleted = 0
SET @accrue_docs_deleted = 0

IF (@add_with_accounting = 0) AND (@doc_rec_id IS NOT NULL) --Document Added While Execute
BEGIN
	SELECT @doc_type = DOC_TYPE, @doc_rec_state = REC_STATE, @parent_rec_id = PARENT_REC_ID
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE REC_ID = @doc_rec_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR READING DOC DATA', 16, 1); RETURN (1); END

	IF (@doc_rec_state IS NOT NULL) AND (ISNULL(@parent_rec_id, 0) <= 0)
	BEGIN
		IF @doc_type = 120 --Cash Order
			SET @op_doc_rec_state = @op_doc_rec_state_cash

		IF @doc_rec_state > @op_doc_rec_state
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
			RAISERROR ('ÏÐÄÒÀÝÉÀÓÈÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÄÁÉÓ ÀÅÔÏÒÉÆÀÝÉÉÓ ÌÀÙÀËÉ ÃÏÍÄ, ÓÀàÉÒÏÀ ÓÀÁÖÈÄÁÉÓ ÃÄÀÅÔÏÒÉÆÀÝÉÀ!', 16, 1);
			RETURN (1);
		END

		EXECUTE @r = dbo.DELETE_DOC
			@rec_id = @doc_rec_id,
			@user_id = @user_id,
			@check_saldo = 0,
			@dont_check_up = 1
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÀÓÈÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÄÁÉÓ ßÀÛËÉÓ ÃÒÏÓ', 16, 1); RETURN (1); END

		SET @op_docs_deleted = 1
	END
END

IF (@accrue_before_add = 0) AND (@accrue_doc_rec_id IS NOT NULL)
BEGIN
	EXECUTE @r = dbo.DELETE_DOC
		@rec_id = @accrue_doc_rec_id,
		@user_id = @user_id,
		@check_saldo = 0,
		@dont_check_up = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÀÓÈÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÄÁÉÓ ßÀÛËÉÓ ÃÒÏÓ', 16, 1); RETURN (1); END
	SET @accrue_docs_deleted = 1
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN (0)

GO
