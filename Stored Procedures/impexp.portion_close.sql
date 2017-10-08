SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[portion_close]
	@date smalldatetime, 
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_out_nbg @date, @por, @user_id, 1, default, default, 'ÃÀáÖÒÅÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

IF EXISTS(SELECT * FROM impexp.DOCS_OUT_NBG WHERE PORTION_DATE = @date AND PORTION = @por AND ISNULL(GIK, '') <> '' AND impexp.check_tax_code (GIK) <> 0)
BEGIN
	ROLLBACK 
	RAISERROR ('ÀÒÓÄÁÏÁÓ ÓÀÁÖÈÉ ÀÒÀÓßÏÒÉ ÂÀÌÂÆÀÅÍÉÓ ÓÀÉÃÄÍÔÉ×ÉÊÀÝÉÏ ÊÏÃÉÈ. ÐÏÒÝÉÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
	RETURN 1
END

UPDATE impexp.PORTIONS_OUT_NBG 
SET STATE = 2, CLOSE_TIME = GETDATE() -- Closed
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT
GO
