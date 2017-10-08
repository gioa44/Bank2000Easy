SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[portion_assign_out_nbg] 
	@doc_id int, 
	@date smalldatetime, 
	@por int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE 
	@old_date smalldatetime,
	@old_por int,
	@old_uid int

SELECT @old_uid = UID, @old_date = PORTION_DATE, @old_por = PORTION
FROM impexp.DOCS_OUT_NBG O
WHERE O.DOC_REC_ID = @doc_id

IF @uid <> @old_uid
BEGIN
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_out_nbg @old_date, @old_por, @user_id, 1, default, default, 'ÓÀÁÖÈÉÓ ÝÅËÉËÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

EXEC @r = impexp.check_portion_state_out_nbg @date, @por, @user_id, 1, default, default, 'ÓÀÁÖÈÉÓ ÝÅËÉËÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_OUT_NBG
SET PORTION_DATE = @date, PORTION = @por, UID = UID + 1
WHERE DOC_REC_ID = @doc_id
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT
GO
