SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_reject_in_swift]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE
	@rec_uid int,
	@finalyze_doc_rec_id int,
	@doc_rec_id int

BEGIN TRAN

SELECT @rec_uid = [UID], @finalyze_doc_rec_id = FINALYZE_DOC_REC_ID, @doc_rec_id = DOC_REC_ID
FROM impexp.DOCS_IN_SWIFT (UPDLOCK)
WHERE ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

DECLARE	@r int

IF @finalyze_doc_rec_id IS NOT NULL
BEGIN
	EXEC @r = dbo.DELETE_DOC
	   @rec_id = @finalyze_doc_rec_id
	  ,@uid = NULL
	  ,@user_id = 6 -- NBG
	  ,@check_saldo = 0
	  ,@dont_check_up = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

IF @doc_rec_id IS NOT NULL
BEGIN
	EXEC @r = dbo.DELETE_DOC
	   @rec_id = @doc_rec_id
	  ,@uid = NULL
	  ,@user_id = 6 -- NBG
	  ,@check_saldo = 0
	  ,@dont_check_up = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

UPDATE impexp.DOCS_IN_SWIFT
SET  UID = UID + 1,
	FINALYZE_DATE = NULL,
	FINALYZE_BANK_ID = NULL,
	FINALYZE_ACC_ID = NULL,
	FINALYZE_AMOUNT = NULL,
	FINALYZE_ISO = NULL,
	FINALYZE_DOC_REC_ID = NULL,
	DOC_REC_ID = NULL,
	STATE = 99
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT

RETURN @@ERROR
GO
