SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_delete_deposit_contract]
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

DECLARE
	@state tinyint

SELECT @state = [STATE]
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR DELETING DEPOSIT!', 16, 1); RETURN (1); END

IF @state > 40
BEGIN
	IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; 
	RAISERROR ('ÀÍÀÁÀÒÆÄ ÀÒÓÄÁÏÁÓ ÛÄÓÒÖËÄÁÖËÉ ÏÐÄÒÀÝÉÄÁÉ, ßÀÛËÀ ÛÄÖÞËÄÁÄËÉÀ!', 16, 1)
	RETURN (1)
END


DECLARE
	@dt smalldatetime,
	@shadow_level smallint,
	@saldo money,
	@saldo_equ money

SET @dt = '20790101'
SET @shadow_level = 0

DECLARE
	@client_no int,
	@depo_acc_id int,
	@loss_acc_id int,
	@accrual_acc_id int,
	@interest_realize_adv_acc_id int

SELECT @depo_acc_id = DEPO_ACC_ID, @loss_acc_id = LOSS_ACC_ID, @accrual_acc_id = ACCRUAL_ACC_ID, @interest_realize_adv_acc_id = INTEREST_REALIZE_ADV_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DELETING DEPOSIT!</ERR>', 16, 1); RETURN (1); END

DELETE FROM dbo.DEPO_DEPOSITS
WHERE DEPO_ID = @depo_id

IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DELETING DEPOSIT!</ERR>', 16, 1); RETURN (1); END

DECLARE
	@delete_account bit
	
IF @depo_acc_id IS NOT NULL
BEGIN
	DECLARE
		@depo_acc_close_del int
		
	EXEC @r = dbo.GET_SETTING_INT 'DEPO_ACC_CLOSE_DEL', @depo_acc_close_del OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR REAGING SETTING</ERR>' , 16, 1); RETURN (1); END

	IF @depo_acc_close_del = 0
		SET @delete_account = 1
	ELSE 
		SET @delete_account = 0
		
	EXEC @r = dbo.depo_sp_delete_depo_account
		@acc_id = @depo_acc_id,
		@delete_account = @delete_account
	IF @@ERROR <> 0 OR (@r <> 0 AND @r <> 1) BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DELETING ACCOUNT (DEPOSIT)!</ERR>', 16, 1); RETURN (1); END

	IF @r = 1
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; 
		RAISERROR ('<ERR>ÓÀÀÍÀÁÒÄ ÀÍÂÀÒÉÛÆÄ ÀÒÉÓ ÀÒÀÍÖËÏÅÀÍÉ ÍÀÛÈÉ, ÀÍÂÀÒÉÛÉÓ ßÀÛËÀ ÛÄÖÞËÄÁÄËÉÀ!</ERR>', 16, 1)
		RETURN (1)
	END
	
	IF @depo_acc_close_del <> 0
	BEGIN
		DECLARE
			@rec_id int,
			@rec_state int
			
		SET @rec_state =
			CASE @depo_acc_close_del
				WHEN 1 THEN 2 --ÃÀáÖÒÖËÉ
				WHEN 2 THEN 128 --ÂÀÖØÌÄÁÀ
			END
			
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID REC_STATE (ÀÍÀÁÒÉÓ ÛÄÝÅËÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1, REC_STATE = @rec_state
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @depo_acc_id, @user_id
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROC: ON_USER_AFTER_EDIT_ACC</ERR>', 16, 1); RETURN (1); END
	END
END

SET @delete_account = 1

IF @interest_realize_adv_acc_id IS NOT NULL
BEGIN
	SET @client_no = NULL
	SELECT @client_no = CLIENT_NO
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @interest_realize_adv_acc_id
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR GETING ACCOUNT DATA!</ERR>', 16, 1); RETURN (1); END

	IF @client_no IS NOT NULL
	BEGIN
		EXEC @r = dbo.depo_sp_delete_depo_account
			@acc_id = @interest_realize_adv_acc_id,
			@delete_account = @delete_account
		IF @@ERROR <> 0 OR (@r <> 0 AND @r <> 1) BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DELETING ACCOUNT (INTEREST ADV)</ERR>!', 16, 1); RETURN (1); END

		IF @r = 1
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; 
			RAISERROR ('<ERR>ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÆÄ ÀÒÉÓ ÀÒÀÍÖËÏÅÀÍÉ ÍÀÛÈÉ, ÀÍÂÀÒÉÛÉÓ ßÀÛËÀ ÛÄÖÞËÄÁÄËÉÀ!</ERR>', 16, 1)
			RETURN (1)
		END
	END
END

IF @loss_acc_id IS NOT NULL
BEGIN
	SET @client_no = NULL
	SELECT @client_no = CLIENT_NO
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @loss_acc_id
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR GETING ACCOUNT DATA!</ERR>', 16, 1); RETURN (1); END

	IF @client_no IS NOT NULL
	BEGIN
		EXEC @r = dbo.depo_sp_delete_depo_account
			@acc_id = @loss_acc_id,
			@delete_account = @delete_account
		IF @@ERROR <> 0 OR (@r <> 0 AND @r <> 1) BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DELETING ACCOUNT (LOSS)!</ERR>', 16, 1); RETURN (1); END

		IF @r = 1
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; 
			RAISERROR ('<ERR>ÀÍÀÁÒÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÆÄ ÀÒÉÓ ÀÒÀÍÖËÏÅÀÍÉ ÍÀÛÈÉ, ÀÍÂÀÒÉÛÉÓ ßÀÛËÀ ÛÄÖÞËÄÁÄËÉÀ!</ERR>', 16, 1)
			RETURN (1)
		END
	END
END

IF @accrual_acc_id IS NOT NULL
BEGIN
	SET @client_no = NULL
	SELECT @client_no = CLIENT_NO
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @accrual_acc_id
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR GETING ACCOUNT DATA!</ERR>', 16, 1); RETURN (1); END

	IF @client_no IS NOT NULL
	BEGIN
		EXEC @r = dbo.depo_sp_delete_depo_account
			@acc_id = @accrual_acc_id,
			@delete_account = @delete_account
		
		IF @@ERROR <> 0 OR (@r <> 0 AND @r <> 1) BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DELETING ACCOUNT (ACCRUAL)!</ERR>', 16, 1); RETURN (1); END

		IF @r = 1
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; 
			RAISERROR ('<ERR>ÀÍÀÁÒÉÓ ÃÀÒÉÝáÅÉÓ ÀÍÂÀÒÉÛÆÄ ÀÒÉÓ ÀÒÀÍÖËÏÅÀÍÉ ÍÀÛÈÉ, ÀÍÂÀÒÉÛÉÓ ßÀÛËÀ ÛÄÖÞËÄÁÄËÉÀ!</ERR>', 16, 1)
			RETURN (1)
		END
	END
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN


RETURN 0
GO
