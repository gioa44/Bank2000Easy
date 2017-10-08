SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ADD_INCASSO_OPS]
	@rec_id int OUTPUT,
	@user_id int,
	@incasso_id int,
	@op_type smallint,
	@amount money,
	@doc_num varchar(20),
	@doc_date smalldatetime,
	@extra_date smalldatetime = null,
	@extra_rec_id int = null
AS
SET NOCOUNT ON

IF @op_type = 5 AND EXISTS(
	SELECT * FROM dbo.INCASSO_OPS (NOLOCK) 
	WHERE INCASSO_ID = @incasso_id AND ((OP_TYPE = 4) OR (ISNULL(@extra_rec_id, 0) > 0 AND EXTRA_REC_ID = ISNULL(@extra_rec_id, 0))))
BEGIN
	SET @rec_id = 0
	RETURN 0
END

BEGIN TRAN

	UPDATE	dbo.INCASSO
	SET		PENDING = 1
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) END RETURN 1 END

	INSERT INTO dbo.INCASSO_OPS(INCASSO_ID,OP_TYPE,[USER_ID],REC_STATE,AMOUNT,DOC_NUM,DOC_DATE,EXTRA_DATE,EXTRA_REC_ID)
	VALUES(@incasso_id,@op_type,@user_id,0,@amount,@doc_num,@doc_date,@extra_date,@extra_rec_id)
	IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) END RETURN 2 END

	SET @rec_id = SCOPE_IDENTITY()
COMMIT TRAN

RETURN 0
GO
