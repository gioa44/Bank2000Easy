SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INCASSO_DOCS_GENERATOR]
	@user_id int
AS
SET NOCOUNT ON

DECLARE
	@r int,
	@rec_id int,	
	@doc_date smalldatetime,
	@aut_level int
	
	SET @doc_date = GETDATE()
	SET @aut_level = 0

SET NOCOUNT ON

DECLARE cur CURSOR LOCAL FOR
	SELECT I.REC_ID
	FROM dbo.INCASSO I
		INNER JOIN dbo.INCASSO_ISSUER II ON II.REC_ID = I.INCASSO_ISSUER
	WHERE I.REC_STATE = 1
	ORDER BY II.PRIORITY_ORDER, I.REC_DATE_TIME, INCASSO_NUM
	  FOR READ ONLY

OPEN cur
IF @@ERROR <> 0  GOTO RollBackThisTrans1

FETCH NEXT FROM cur INTO @rec_id
IF @@ERROR <> 0 GOTO RollBackThisTrans1

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRAN
	EXEC @r = dbo.INCASSO_DOC_GENERATOR @rec_id=@rec_id, @user_id=@user_id, @doc_date=@doc_date, @aut_level=@aut_level
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÓÀÁÖÈÉÓ ÂÀÔÀÒÄÁÉÓÀÓ.',16,1) END RETURN 1 END
	COMMIT
	FETCH NEXT FROM cur INTO @rec_id
	IF @@ERROR <> 0 GOTO RollBackThisTrans1
END

RollBackThisTrans1:

CLOSE cur
DEALLOCATE cur

RETURN 0
GO
