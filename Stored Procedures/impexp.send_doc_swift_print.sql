SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[send_doc_swift_print]
	@doc_rec_id int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@rec_uid int

BEGIN TRAN

SELECT @rec_uid = UID
FROM impexp.DOCS_OUT_SWIFT (UPDLOCK)
WHERE DOC_REC_ID = @doc_rec_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

UPDATE impexp.DOCS_OUT_SWIFT
SET UID = UID + 1,
	SWIFT_FLAGS_2 = 1
WHERE DOC_REC_ID = @doc_rec_id and UID = @uid
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES (DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@doc_rec_id, @user_id, 25, 'ÓÀÁÖÈÉÓ ÁÄàÃÅÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
