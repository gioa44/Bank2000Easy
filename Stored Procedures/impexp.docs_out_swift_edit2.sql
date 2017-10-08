SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[docs_out_swift_edit2]
	@doc_rec_id int,
	@uid int,
	@user_id int
AS

DECLARE
	@rec_uid int,
	@correspondent_bank_id int

BEGIN TRAN

SELECT @rec_uid = UID, @correspondent_bank_id = CORRESPONDENT_BANK_ID
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
	FINALYZE_DATE = NULL,
	FINALYZE_BANK_ID = @correspondent_bank_id,
	FINALYZE_ACC_ID = NULL,
	FINALYZE_AMOUNT = NULL,
	FINALYZE_ISO = NULL,
	[STATE] = 12 --psUpdated
WHERE DOC_REC_ID = @doc_rec_id and UID = @uid
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES(DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES(@doc_rec_id, @user_id, 5, 'ÓÀÁÖÈÉÓ ÃÀÓÔÖÒÉ ÛÄÝÅËÉÓ ÂÀÒÄÛÄ (SWIFT ×ÏÒÌÀÔÉ)')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT

SELECT *
FROM impexp.V_DOCS_OUT_SWIFT
WHERE DOC_REC_ID = @doc_rec_id

RETURN 0

GO
