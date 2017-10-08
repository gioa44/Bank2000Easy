SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AUTO_RESTORE_INCASSOS]
	@user_id int
AS

SET NOCOUNT ON

BEGIN TRAN

DECLARE cur CURSOR LOCAL FOR
SELECT O1.REC_ID, O1.INCASSO_ID, O1.AMOUNT, O1.DOC_NUM, O1.DOC_DATE
FROM dbo.INCASSO_OPS O1
	INNER JOIN dbo.INCASSO INC ON INC.REC_ID = O1.INCASSO_ID
WHERE O1.REC_STATE = 1 AND INC.REC_STATE = 2 AND INC.PENDING = 0 AND O1.OP_TYPE = 2 AND O1.EXTRA_DATE <= GETDATE() AND 
	NOT EXISTS(SELECT * FROM dbo.INCASSO_OPS O2 WHERE O2.INCASSO_ID = O1.INCASSO_ID AND O1.REC_ID = O2.EXTRA_REC_ID)

OPEN cur
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK; RETURN 1; END

DECLARE
	@op_id int,
	@incasso_id int,
	@amount money,
	@doc_num varchar(20),
	@doc_date smalldatetime,
	@r int,
	@rec_id int

FETCH NEXT FROM cur INTO @op_id, @incasso_id, @amount, @doc_num, @doc_date
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK; RETURN 1; END

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC @r = dbo.ADD_INCASSO_OPS @rec_id=@rec_id OUTPUT, @user_id=@user_id, @incasso_id=@incasso_id,
			@op_type=5,	@amount=@amount, @doc_num=@doc_num, @doc_date=@doc_date, @extra_rec_id=@op_id
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1); END RETURN 1 END

	EXEC @r = dbo.AUTHORIZE_INCASSO @rec_id=@rec_id, @user_id=@user_id
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1); END RETURN 99 END

	FETCH NEXT FROM cur INTO @op_id, @incasso_id, @amount, @doc_num, @doc_date
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK; RETURN 1; END
END

CLOSE cur
DEALLOCATE cur

COMMIT
GO
