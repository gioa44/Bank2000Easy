SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [impexp].[doc_send_swift_finalyze]
	@doc_rec_id int,
	@new_state int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@r int,
	@rec_uid int,
	@ref_num varchar(32),
	@doc_date smalldatetime,
	@old_flags int,
	@amount money,
	@iso TISO,
	@finalyze_doc_rec_id int,
	@new_rec_state tinyint,
	@new_doc_rec_id int

BEGIN TRAN

SELECT @rec_uid = [UID], @finalyze_doc_rec_id = FINALYZE_DOC_REC_ID
FROM impexp.DOCS_OUT_SWIFT (UPDLOCK)
WHERE DOC_REC_ID = @doc_rec_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

SET @new_rec_state = CASE WHEN @new_state = 9 THEN 20 ELSE 10 END
EXEC @r = dbo.CHANGE_DOC_STATE
	@rec_id = @finalyze_doc_rec_id,
	@user_id = @user_id,
	@new_rec_state = @new_rec_state
IF @r <> 0 OR @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

EXEC @r = impexp.doc_send_swift_finalyze_on_user
	@doc_rec_id = @doc_rec_id,
	@finalyze_doc_rec_id = @finalyze_doc_rec_id,
	@new_state = @new_state,
	@user_id = @user_id,
	@new_doc_rec_id = @new_doc_rec_id OUTPUT
IF @r <> 0 OR @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

IF @new_doc_rec_id <> 0 OR @new_state = 4 --psFinished
BEGIN
	IF @new_state = 4 -- წავშალოთ დამოკიდებული საბუთი თუ ასეთი არსებობს
	BEGIN
		SET @new_doc_rec_id = NULL

		SELECT @new_doc_rec_id = REC_ID 
		FROM dbo.OPS_0000 (NOLOCK)
		WHERE PARENT_REC_ID = @finalyze_doc_rec_id AND CHANNEL_ID = 605

		IF @new_doc_rec_id IS NOT NULL
		BEGIN
			EXEC @r = dbo.DELETE_DOC @rec_id = @new_doc_rec_id, @user_id = @user_id
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
		END

		IF NOT EXISTS(SELECT * FROM dbo.OPS_0000 WHERE PARENT_REC_ID = @finalyze_doc_rec_id)
		BEGIN
			UPDATE dbo.OPS_0000
			SET PARENT_REC_ID = 0
			WHERE REC_ID = @finalyze_doc_rec_id
			IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
		END
	END
	ELSE
	BEGIN
		UPDATE dbo.OPS_0000
		SET PARENT_REC_ID = -1
		WHERE REC_ID = @finalyze_doc_rec_id
		IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
	END
END

UPDATE impexp.DOCS_OUT_SWIFT
SET [UID] = [UID] + 1,
	STATE = @new_state -- psFinished OR psFinished2
WHERE DOC_REC_ID = @doc_rec_id and UID = @uid
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

IF @new_state = 9 
	INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES(DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
	VALUES(@doc_rec_id, @user_id, 80, 'ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÃÀáÖÒÅÉÓ ÃÀÓÔÖÒÉ')
ELSE
	INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES(DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
	VALUES(@doc_rec_id, @user_id, 81, 'ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÃÀáÖÒÅÉÓ ÂÀÖØÌÄÁÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
