SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DELETE_INCASSO_OPS]
	@user_id int,
	@incasso_op_id int
AS
SET NOCOUNT ON

DECLARE
	@doc_rec_id int,
	@r int

--IF EXISTS(
--	SELECT *
--	FROM dbo.OPS_0000 O
--		INNER JOIN dbo.INCASSO_OPS_ID I ON I.DOC_REC_ID = O.REC_ID
--	WHERE INCASSO_OP_ID = @incasso_op_id AND O.DOC_TYPE BETWEEN 100 AND 109 AND REC_STATE >= 10
--)
--BEGIN
--	RAISERROR ('ÓÀÂÀÃÀÓÀáÀÃÏ ÃÀÅÀËÄÁÀ ÀÅÔÏÒÉÆÄÁÖËÉÀ. ÏÐÄÒÀÝÉÉÓ ßÀÛËÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
--	RETURN 1
--END

BEGIN TRAN

DECLARE cur CURSOR LOCAL FOR
	SELECT	DOC_REC_ID
	FROM	dbo.INCASSO_OPS_ID
	WHERE	INCASSO_OP_ID = @incasso_op_id
	ORDER BY DOC_REC_ID DESC
	FOR READ ONLY

OPEN cur
IF @@ERROR <> 0  GOTO RollBackThisTrans0

FETCH NEXT FROM cur INTO @doc_rec_id
IF @@ERROR <> 0 GOTO RollBackThisTrans0

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC @r=dbo.DELETE_DOC @rec_id=@doc_rec_id,@user_id=@user_id,@check_saldo=0
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÓÀÁÖÈÉÓ ßÀÛËÉÓÀÓ.',16,1) END RETURN 1 END

	FETCH NEXT FROM cur INTO @doc_rec_id
	IF @@ERROR <> 0 GOTO RollBackThisTrans0
END

RollBackThisTrans0:
CLOSE cur
DEALLOCATE cur

DELETE FROM dbo.INCASSO_OPS_ID
WHERE	INCASSO_OP_ID = @incasso_op_id
IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÄÁÉÓ ÏÐÄÒÀÝÉÄÁÉÓ ßÀÛËÉÓÀÓ.',16,1) END RETURN 2 END

COMMIT

RETURN 0
GO
