SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DEL_INCASSO_OPS]
	@user_id int,
	@incasso_id int,
	@rec_id int
AS
SET NOCOUNT ON

DECLARE
	@incasso_ops_type int,
	@r int

SELECT	@incasso_ops_type = OP_TYPE
FROM	dbo.INCASSO_OPS(nolock)
WHERE	REC_ID = @rec_id

SELECT	@r = MAX(REC_ID)
FROM	dbo.INCASSO_OPS(NOLOCK)
WHERE	INCASSO_ID = @incasso_id

IF @r <> @rec_id
BEGIN
	RAISERROR ('ÛÄÝÃÏÌÀ. ÀÌ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÀ ÀÒ ÛÄÉÞËÄÁÀ.',16,1) 
	RETURN 3 
END

BEGIN TRAN

	IF @incasso_ops_type = 0
	BEGIN
		IF EXISTS(SELECT * FROM dbo.OPS_0000 (NOLOCK) WHERE DOC_TYPE BETWEEN 100 AND 129 AND REC_STATE >= 10 AND REC_ID IN (SELECT DOC_REC_ID FROM dbo.INCASSO_OPS_ID (NOLOCK) WHERE INCASSO_OP_ID = @rec_id))
		BEGIN 
			ROLLBACK 
			RAISERROR ('ÀÌ ÏÐÄÒÀÝÉÉÓ ßÀÛËÀ ÀÒ ÛÄÉÞËÄÁÀ. ÓÀÂÀÃÀÓÀáÀÃÏ ÃÀÅÀËÄÁÉÓ ÓÀÁÖÈÉ ÀÅÔÏÒÉÆÄÁÖËÉÀ.',16,1) 
			RETURN 2 
		END

		EXEC @r=dbo.DEAUTHORIZE_INCASSO @rec_id=@rec_id, @user_id=@user_id
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÓÀÁÖÈÄÁÉÓ ßÀÛËÉÓÀÓ.',16,1) END RETURN 3 END
	END

	IF @incasso_ops_type = 1
	BEGIN
		EXEC dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 0
		IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 8 END

		DELETE	dbo.INCASSO
		WHERE	REC_ID = @incasso_id
	END
	ELSE
		UPDATE	dbo.INCASSO
		SET		PENDING = 0
		WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) END RETURN 1 END

	DELETE	dbo.INCASSO_OPS
	WHERE	REC_ID = @rec_id
	IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÓÀÓ.',16,1) END RETURN 2 END
--ROLLBACK

COMMIT TRAN

RETURN 0
GO
