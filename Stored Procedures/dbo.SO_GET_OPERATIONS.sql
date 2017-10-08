SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SO_GET_OPERATIONS]
  @rec_id int = NULL,
  @task_id int = NULL,
  @date datetime = NULL
AS

SET NOCOUNT ON

IF (@rec_id IS NULL AND (@task_id IS NULL OR @date IS NULL))
BEGIN
	RAISERROR ('ÐÒÏÝÄÃÖÒÉÓ ÂÀÌÏÞÀáÄÁÀ ÀÒÀÓßÏÒÉ ÐÀÒÀÌÄÔÒÄÁÉÈ (ÓÀÁÖÈÉÓ ÍÏÌÄÒÉ ÀÍ ÃÀÅÀËÄÁÉÓ ÍÏÌÄÒÉ ÃÀ ÈÀÒÉÙÉ ÖÍÃÀ ÉÚÏÓ ÛÄÅÓÄÁÖËÉ)!', 16, 1)	
	RETURN 1
END

IF (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'SERVER_STATE') <> 0
BEGIN
	RAISERROR ('ÌÉÌÃÉÍÀÒÄÏÁÓ ÃÙÉÓ ÃÀáÖÒÅÀ/ÂÀáÓÍÀ. ÂÈáÏÅÈ ÃÀÉÝÀÃÏÈ', 16, 1)	
	RETURN 1
END

IF (@rec_id IS NULL)
	SET @rec_id = (SELECT TOP 1 DOC_REC_ID FROM dbo.SO_SCHEDULES WHERE TASK_ID = @task_id AND [DATE] = @date)

SELECT REC_ID, OP_CODE, DEBIT, CREDIT, ISO, AMOUNT, DESCRIP, DOC_DATE, DOC_TYPE
FROM dbo.DOCS (NOLOCK)
WHERE REC_ID = @rec_id OR RELATION_ID = @rec_id
ORDER BY REC_ID

IF @@ROWCOUNT = 0
	RETURN -1
	
RETURN 0;
GO
