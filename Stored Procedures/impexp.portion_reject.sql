SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[portion_reject] 
	@date smalldatetime, 
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_out_nbg @date, @por, @user_id, 3, 4, default, 'ÃÀÁÒÀÊÅÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE 
	@doc_rec_id int,
	@rec_state tinyint

SELECT @doc_rec_id = DOC_REC_ID
FROM impexp.PORTIONS_OUT_NBG 
WHERE PORTION_DATE = @date AND PORTION = @por

IF @doc_rec_id IS NOT NULL
BEGIN
	SELECT @rec_state = REC_STATE
	FROM dbo.OPS_0000
	WHERE REC_ID = @doc_rec_id
	
	IF @rec_state >= 10
	BEGIN
		RAISERROR ('ÀÌ ÐÏÒÝÉÉÓ ÛÄÓÀÁÀÌÉÓÉ ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ãÀÌÖÒÉ ÂÀÌÀÓßÏÒÄÁÄËÉ ÂÀÔÀÒÄÁÀ ÀÅÔÏÒÉÆÄÁÖËÉÀ. ÐÏÒÝÉÉÓ ÖÀÒÚÏ×À ÀÒ ÛÄÉÞËÄÁÀ.', 16, 1)
		IF @@TRANCOUNT > 0 ROLLBACK 
		RETURN 1
	END

	EXECUTE @r = dbo.DELETE_DOC
	   @rec_id = @doc_rec_id
	  ,@uid = NULL
	  ,@user_id = @user_id
	  ,@check_saldo = 0
	  ,@dont_check_up = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

UPDATE impexp.PORTIONS_OUT_NBG 
SET STATE = 99, DOC_REC_ID = NULL -- Rejected
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT
GO
