SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[doc_generate_revert_in_nbg_unknown_arc]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE 
	@doc_rec_id int,
	@old_uid int,
	@rec_state tinyint,
	@finalyze_doc_rec_id int,
	@r int

SELECT @doc_rec_id = DOC_REC_ID, @finalyze_doc_rec_id = FINALYZE_DOC_REC_ID, @old_uid = UID
FROM impexp.DOCS_IN_NBG_ARC (UPDLOCK)
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

IF @uid <> @old_uid
BEGIN
	ROLLBACK 
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

IF @finalyze_doc_rec_id IS NOT NULL AND @finalyze_doc_rec_id <> @doc_rec_id
BEGIN
	SELECT @rec_state = REC_STATE
	FROM dbo.OPS_0000
	WHERE REC_ID = @finalyze_doc_rec_id

	IF @rec_state IS NULL
	BEGIN
		RAISERROR ('ÀÌ ÓÀÁÖÈÉÓ ÛÄÓÀÁÀÌÉÓÉ ÖÊÀÍ ÃÀÓÀÁÒÖÍÄÁÄËÉ ÓÀÂÀÃÀÓÀáÀÃÏ ÃÀÅÀËÄÁÀ ÀÒØÉÅÛÉÀ. 2-Ä ÓÀÁÖÈÉÓ ÂÄÍÄÒÀÝÉÉÓ ÛÄØÝÄÅÀ ÀÒ ÛÄÉÞËÄÁÀ.', 16, 1)
		IF @@TRANCOUNT > 0 ROLLBACK 
		RETURN 1
	END

	IF @rec_state >= 10
	BEGIN
		RAISERROR ('ÀÌ ÓÀÁÖÈÉÓ ÛÄÓÀÁÀÌÉÓÉ ÖÊÀÍ ÃÀÓÀÁÒÖÍÄÁÄËÉ ÓÀÂÀÃÀÓÀáÀÃÏ ÃÀÅÀËÄÁÀ ÀÅÔÏÒÉÆÄÁÖËÉÀ. 2-Ä ÓÀÁÖÈÉÓ ÂÄÍÄÒÀÝÉÉÓ ÛÄØÝÄÅÀ ÀÒ ÛÄÉÞËÄÁÀ.', 16, 1)
		IF @@TRANCOUNT > 0 ROLLBACK 
		RETURN 1
	END

	EXECUTE @r = dbo.DELETE_DOC
	   @rec_id = @finalyze_doc_rec_id
	  ,@uid = NULL
	  ,@user_id = @user_id
	  ,@check_saldo = 0
	  ,@dont_check_up = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

UPDATE impexp.DOCS_IN_NBG_ARC
SET FINALYZE_DOC_REC_ID = NULL, UID = UID + 1
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
