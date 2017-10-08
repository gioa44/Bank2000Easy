SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_add_op_action]
	@op_id int,
	@op_type tinyint,	
	@depo_id int,
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

IF @op_type <> dbo.depo_fn_const_op_active()
BEGIN
	DECLARE
		@op_date smalldatetime,
		@depo_acc_id int
		
	SELECT @op_date = OP_DATE FROM dbo.DEPO_OP (NOLOCK) WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('DEPOSIT NOT FOUND', 16, 1); RETURN (1); END

	SELECT @depo_acc_id = DEPO_ACC_ID FROM dbo.DEPO_DEPOSITS (NOLOCK) WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('DEPOSIT NOT FOUND', 16, 1); RETURN (1); END
		

	IF EXISTS(SELECT * FROM dbo.DOC_DETAILS_PERC (NOLOCK) WHERE ACC_ID = @depo_acc_id AND ACCR_DATE > @op_date)
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
		RAISERROR('<ERR>ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÛÄÒÖËÄÁÉÓ ÃÒÏÓ, ÀÍÂÀÒÉÛÆÄ ÌÏáÃÀ ÃÀÒÉÝáÅÀ ÏÐÄÒÀÝÉÉÓ ÛÄÌÃÄÂÉ ÈÀÒÉÙÄÁÉÈ</ERR>', 16, 1);
		RETURN (1)
	END

	EXEC @r = dbo.depo_sp_check_depo_amount_sync
		@depo_id = @depo_id,
		@user_id = @user_id

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR SYNC', 16, 1); RETURN (1); END

	IF @r <> 0
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
		RAISERROR ('<ERR>ÃÄÓÉÍØÒÏÍÉÆÀÝÉÀ ÓÀÀÍÀÁÒÄ ÌÏÃÖËÓÀ ÃÀ ÁÀÍÊÉÓ ÏÐÄÒÀÝÉÖË ÃÙÄÓ ÛÏÒÉÓ, ÛÄÀÓÒÖËÄÈ ÓÉÍØÒÏÍÉÆÀÝÉÀ</ERR>', 16, 1)
		RETURN (1)
	END
END

IF @op_type = dbo.depo_fn_const_op_active()
BEGIN
	UPDATE dbo.DEPO_DEPOSITS WITH (UPDLOCK)
	SET [STATE] = 50
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATING DEPOSIT DATA', 16, 1); RETURN (1); END

	INSERT INTO dbo.DEPO_DEPOSIT_CHANGES(DEPO_ID, [USER_ID], DESCRIP)
	VALUES(@depo_id, @user_id, 'ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÀØÔÉÅÉÆÀÝÉÀ')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT CONTRACT LOG', 16, 1); RETURN (1); END
END;

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN 0
GO
