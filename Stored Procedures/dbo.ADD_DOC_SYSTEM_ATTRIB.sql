SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ADD_DOC_SYSTEM_ATTRIB]
	@user_id int,
	@rec_id int,
	@attrib_code varchar(20),
	@is_arc bit = 0

AS

SET NOCOUNT ON

DECLARE
	@sql nvarchar(4000),
	@count int


IF @is_arc = 1 
BEGIN
	IF EXISTS(SELECT * FROM dbo.DOC_ATTRIBUTES_ARC (NOLOCK) WHERE REC_ID = @rec_id AND ATTRIB_CODE = @attrib_code)
		RETURN 0
END
ELSE
BEGIN
	IF EXISTS(SELECT * FROM dbo.DOC_ATTRIBUTES (NOLOCK) WHERE REC_ID = @rec_id AND ATTRIB_CODE = @attrib_code)
		RETURN 0
END

BEGIN TRAN

IF @is_arc = 0
BEGIN
	INSERT INTO dbo.DOC_ATTRIBUTES VALUES(@rec_id, @attrib_code, 1)
	IF @@ERROR <> 0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ. ÓÉÓÔÄÌÖÒÉ ÀÔÒÉÁÖÔÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) RETURN 2 END

	INSERT INTO dbo.DOC_CHANGES (DOC_REC_ID,[USER_ID],DESCRIP) 
	VALUES (@rec_id, @user_id, 'ÓÉÓÔÄÌÖÒÉ ÀÔÒÉÁÖÔÉÓ ÃÀÌÀÔÄÁÀ')
	IF @@ERROR <> 0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ. ÓÀÁÖÈÉÓ ÝÅËÉËÄÁÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) RETURN 3 END
END
ELSE
BEGIN
	INSERT INTO dbo.DOC_ATTRIBUTES_ARC VALUES(@rec_id, @attrib_code, 1)
	IF @@ERROR <> 0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ. ÓÉÓÔÄÌÖÒÉ ÀÔÒÉÁÖÔÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) RETURN 2 END

	DECLARE @max_id int
	SELECT @max_id = MAX(REC_ID) + 1
	FROM dbo.DOC_CHANGES_ARC (NOLOCK)
	WHERE DOC_REC_ID = @rec_id
	
	SET @max_id = ISNULL(@max_id, 1)

	INSERT INTO dbo.DOC_CHANGES_ARC (DOC_REC_ID,REC_ID,[USER_ID],DESCRIP,TIME_OF_CHANGE) 
	VALUES (@rec_id, @max_id, @user_id, 'ÓÉÓÔÄÌÖÒÉ ÀÔÒÉÁÖÔÉÓ ÃÀÌÀÔÄÁÀ',GETDATE())
	IF @@ERROR <> 0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ. ÓÀÁÖÈÉÓ ÝÅËÉËÄÁÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) RETURN 3 END
END

COMMIT

RETURN 0
GO
