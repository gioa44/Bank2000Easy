SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ON_AFTER_AUTHORIZE_DOC]
	@doc_rec_id int,
	@user_id int,
	@new_rec_state tinyint,
	@old_rec_state tinyint
AS

SET NOCOUNT ON

DECLARE 
	@r int,
	@channel_id int,
	@is_online bit,
	@lock_flag int,
	@waiting_flag int,
	@pendig_rec_state int,
	@foreign_id int,
	@rec_id int,
	@rec_state int

SELECT @channel_id = CHANNEL_ID, @foreign_id = FOREIGN_ID
FROM dbo.OPS_0000 (NOLOCK)
WHERE REC_ID = @doc_rec_id

DECLARE @internal_transaction bit

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

IF @channel_id = 778 AND @foreign_id = 0	-- Main document
BEGIN
	SELECT @pendig_rec_state = REC_STATE, @is_online = IS_ONLINE, @waiting_flag = WAITING_FLAG
	FROM dbo.PENDING_PAYMENTS(NOLOCK)
	WHERE DOC_REC_ID = @doc_rec_id
	
	-- ავტორიზაცია
	IF @old_rec_state < 20 AND @new_rec_state >= 20
	BEGIN
		IF @is_online = 1
			EXEC @r = dbo.CHANGE_PAYMENT_DOC_STATE @doc_rec_id=@doc_rec_id,
						@rec_state=1,@lock_flag = 0, @waiting_flag = @waiting_flag, @user_id=@user_id,
						@descrip ='ÂÀÃÀÓÀáÀÃÉ ÂÀÃÀáÃÉËÉÀ'
		ELSE
			EXEC @r = dbo.CHANGE_PAYMENT_DOC_STATE @doc_rec_id=@doc_rec_id,
						@rec_state=3,@lock_flag = 0, @waiting_flag = @waiting_flag, @user_id=@user_id,
						@descrip ='ÂÀÃÀÓÀáÀÃÉ ÂÀÃÀáÃÉËÉÀ'
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
	ELSE
	-- ავტორიზაციის მოხსნა
	IF @old_rec_state >= 20 AND @new_rec_state < 20
	BEGIN
	    IF (@is_online = 1) AND (@pendig_rec_state = 1 AND @lock_flag = 1)
		BEGIN
			RAISERROR('ÀÌ ÓÀÁÖÈÆÄ ÀÒ ÛÄÉÞËÄÁÀ ÀÅÔÏÒÉÆÀÝÉÉÓ ÌÏáÓÍÀ, ÌÉÌÃÉÍÀÒÄÏÁÓ ÂÀÂÆÀÅÍÀ!', 16, 1)
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
			RETURN 1
		END
		IF (@is_online = 1) AND (@pendig_rec_state = 3)
		BEGIN
			RAISERROR('ÀÌ ÓÀÁÖÈÆÄ ÀÒ ÛÄÉÞËÄÁÀ ÀÅÔÏÒÉÆÀÝÉÉÓ ÌÏáÓÍÀ, ÈÀÍáÀ ÖÊÅÄ ÂÀÂÆÀÅÍÉËÉÀ!', 16, 1)
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
			RETURN 1
		END

		IF (@is_online = 0) AND (@pendig_rec_state = 3)
		BEGIN
			SELECT @rec_id = REC_ID, @rec_state = REC_STATE
			FROM dbo.OPS_0000 (NOLOCK)
			WHERE FOREIGN_ID = @doc_rec_id
			
			IF @rec_id IS NULL
			BEGIN
				RAISERROR('ÂÀÃÀÓÀÒÉÝáÉ ÓÀÂÀÃÀÓÀáÀÃÏ ÃÀÅÀËÄÁÀ ÀÒ ÌÏÉÞÄÁÍÀ!', 16, 1)
				IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
				RETURN 1
			END
			IF @rec_state >= 20
			BEGIN
				RAISERROR('ÂÀÃÀÓÀÒÉÝáÉ ÓÀÂÀÃÀÓÀáÀÃÏ ÃÀÅÀËÄÁÀ ÀÒÉÓ ÀÅÔÏÒÉÆÉÒÄÁÖËÉ!', 16, 1)
				IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
				RETURN 1
			END

			UPDATE dbo.OPS_0000
			SET REC_STATE = 0, UID = UID + 1
			WHERE REC_ID = @rec_id

			IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

			EXEC @r = dbo.DELETE_DOC @rec_id = @rec_id, @user_id = @user_id, @dont_check_up = 1
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END

		EXEC @r = dbo.CHANGE_PAYMENT_DOC_STATE @doc_rec_id=@doc_rec_id,
							@rec_state=0, @lock_flag = 0, @waiting_flag = @waiting_flag, @user_id=@user_id,
							@descrip ='ÂÀÃÀÓÀáÀÃÉ ÂÀÃÀáÃÉËÉÀ'
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END

EXEC @r = dbo.ON_USER_AFTER_AUTHORIZE_DOC @doc_rec_id, @user_id, @new_rec_state, @old_rec_state
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN 0
GO
