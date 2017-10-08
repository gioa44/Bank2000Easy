SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[_GET_OPERATION]
  @rec_id int
AS

SET NOCOUNT ON

IF (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'SERVER_STATE') <> 0
BEGIN
	RAISERROR ('ÌÉÌÃÉÍÀÒÄÏÁÓ ÃÙÉÓ ÃÀáÖÒÅÀ/ÂÀáÓÍÀ. ÂÈáÏÅÈ ÃÀÉÝÀÃÏÈ', 16, 1)	
	RETURN 1
END


SELECT REC_ID, OP_CODE, DEBIT, CREDIT, ISO, AMOUNT, DESCRIP, DOC_DATE, DOC_TYPE
FROM dbo.DOCS (NOLOCK)
WHERE REC_ID = @rec_id OR PARENT_REC_ID = @rec_id
ORDER BY REC_ID
GO