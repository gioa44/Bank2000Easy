SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_delete_deposit_op]
	@op_id int,
	@user_id int
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
	@op_type smallint, 
	@op_state bit,
	@doc_rec_id int,
	@accrue_doc_rec_id int

DECLARE
	@state tinyint

SELECT @depo_id = DEPO_ID, @op_date = OP_DATE, @op_type = OP_TYPE, @op_state = OP_STATE, @doc_rec_id = DOC_REC_ID, @accrue_doc_rec_id = ACCRUE_DOC_REC_ID
FROM dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
WHERE OP_ID = @op_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION NOT FOUND', 16, 1); RETURN (1); END

IF @op_state <> 0
BEGIN
	IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
	RAISERROR ('ÏÐÄÒÀÝÉÀ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ, ÂÀÍÀÀáËÄÈ ÌÏÍÀÝÄÌÄÁÉ!', 16, 1);
	RETURN (1);
END

IF dbo.bank_open_date() > @op_date
BEGIN
	IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; 
	RAISERROR ('ÏÐÄÒÀÝÉÉÓ ÈÀÒÉÙÉ ÃÀáÖÒÖËÉ ÃÙÄÀ!', 16, 1);
	RETURN (1);
END


DECLARE
	@doc_rec_state tinyint,
	@add_with_accounting bit,
	@accrue_before_add bit,
	@doc_type smallint,
	@op_add_doc_rec_state tinyint,
	@op_add_doc_rec_state_cash tinyint

SET @doc_rec_state = NULL
SET @op_add_doc_rec_state_cash = NULL

SELECT @add_with_accounting = ADD_WITH_ACCOUNTING, @op_add_doc_rec_state = ADD_DOC_REC_STATE, @op_add_doc_rec_state_cash = ADD_DOC_REC_STATE_CASH, @accrue_before_add = ACCRUE_BEFORE_ADD
FROM dbo.DEPO_OP_TYPES (NOLOCK)
WHERE [TYPE_ID] = @op_type
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION TYPE SETTINGS NOT FOUND', 16, 1); RETURN (1); END

IF @accrue_before_add = 1 AND @accrue_doc_rec_id IS NOT NULL
BEGIN
	EXECUTE @r = dbo.DELETE_DOC
		@rec_id = @accrue_doc_rec_id,
		@user_id = @user_id,
		@check_saldo = 0,
		@dont_check_up = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÀÓÈÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÄÁÉÓ ßÀÛËÉÓ ÃÒÏÓ', 16, 1); RETURN (1); END
END

IF @add_with_accounting = 1 AND @doc_rec_id IS NOT NULL
BEGIN
	SELECT @doc_type = DOC_TYPE, @doc_rec_state = REC_STATE
	FROM dbo.OPS_0000 WITH (ROWLOCK, UPDLOCK)
	WHERE REC_ID = @doc_rec_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR READING DOC DATA', 16, 1); RETURN (1); END

	IF @doc_rec_state IS NOT NULL
	BEGIN
		IF @doc_type = 120 --Cash Order
			SET @op_add_doc_rec_state = @op_add_doc_rec_state_cash

		IF @doc_rec_state > @op_add_doc_rec_state
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
	END
END


IF @op_type = dbo.depo_fn_const_op_active()
BEGIN
	SELECT @state = DEPO_PREV_STATE 
	FROM dbo.DEPO_VW_OP_DATA_ACTIVE (NOLOCK)
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR READING OPERATION DATA', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET [STATE] = @state
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATING DEPOSIT DATA', 16, 1); RETURN (1); END
END

DELETE dbo.DEPO_OP WITH (ROWLOCK)
WHERE OP_ID = @op_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR DELETING OPERATION', 16, 1); RETURN (1); END

UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
SET ROW_VERSION = ROW_VERSION + 1 
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATING DEPOSIT DATA', 16, 1); RETURN (1); END

INSERT INTO dbo.DEPO_DEPOSIT_CHANGES(DEPO_ID, [USER_ID], DESCRIP)
SELECT @depo_id, @user_id, 'ÏÐÄÒÀÝÉÉÓ ßÀÛËÀ: '  + DESCRIP
FROM dbo.DEPO_OP_TYPES (NOLOCK)
WHERE [TYPE_ID] = @op_type
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR OPERATION LOGGING', 16, 1); RETURN (1); END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN 0
GO
