SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CHANGE_DOC_DATE]
	@rec_id int,					-- საბუთის შიდა №
	@uid int = null,				-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
	@user_id int,					-- ვინ ცვლის საბუთს
	@new_doc_date smalldatetime		-- ახალი თარიღი
AS

SET NOCOUNT ON

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE 
	@r int,
	@parent_rec_id int

UPDATE dbo.OPS_0000
SET UID = UID + 1, DOC_DATE = @new_doc_date, @parent_rec_id = PARENT_REC_ID
WHERE REC_ID = @rec_id AND (@uid IS NULL OR UID = @uid)
IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @parent_rec_id = -1
BEGIN
	UPDATE dbo.OPS_0000
	SET UID = UID + 1, DOC_DATE = @new_doc_date 
	WHERE PARENT_REC_ID = @rec_id
	IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END
END

EXEC @r = dbo.ON_USER_CHECK_DOC @rec_id, @user_id, 0
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 51 END

DECLARE @descrip varchar(100)
SET @descrip = 'ÓÀÁÖÈÉÓ ÈÀÒÉÙÉÓ ÛÄÝÅËÀ : '+ convert(varchar(20), @new_doc_date, 103)

INSERT INTO dbo.DOC_CHANGES (DOC_REC_ID, [USER_ID], DESCRIP)
VALUES ( @rec_id, @user_id, @descrip)
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN 0
GO
