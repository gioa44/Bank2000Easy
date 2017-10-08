SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[client_notes_remove]
	@client_no int,
	@client_note_id int,
	@user_id int,
	@comment varchar(250)
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE	@note_type int

UPDATE dbo.CLIENT_NOTES 
SET @note_type = NOTE_TYPE, REC_STATE = 1, COMMENT2 = @comment, USER_ID2 = @user_id
WHERE CLIENT_NO = @client_no AND REC_ID = @client_note_id 

IF @@ROWCOUNT = 0
BEGIN
	ROLLBACK
	RAISERROR ('ÛÄÍÉÛÅÍÀ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
	RETURN 1
END

DECLARE 
	@txt varchar(250),
	@new_comment varchar(1000)

SET @new_comment = ''

DECLARE cc CURSOR FOR
SELECT COMMENT
FROM dbo.CLIENT_NOTES
WHERE CLIENT_NO = @client_no AND REC_STATE = 0 AND NOTE_TYPE = @note_type
ORDER BY DATE

IF @note_type = 0 
	RETURN 0

OPEN cc
FETCH NEXT FROM cc into @txt

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @new_comment = @new_comment + ISNULL(@txt, '') + ','

	FETCH NEXT FROM cc into @txt
END

IF @new_comment <> ''
	SET @new_comment = LEFT(@new_comment, LEN(@new_comment) - 1);

DECLARE	@b bit	
SET @b = CASE WHEN @new_comment = '' THEN 0 ELSE 1 END
	
IF @note_type = 1
BEGIN
	UPDATE dbo.CLIENTS
	SET IS_CONTROL = @b
	WHERE CLIENT_NO = @client_no AND IS_CONTROL <> @b

	DELETE FROM dbo.CLIENT_ATTRIBUTES
	WHERE CLIENT_NO = @client_no AND ATTRIB_CODE = '$IS_CONTROL_COMMENT'

	IF @b <> 0
		INSERT INTO dbo.CLIENT_ATTRIBUTES (CLIENT_NO,ATTRIB_CODE,ATTRIB_VALUE)
		VALUES (@client_no,'$IS_CONTROL_COMMENT',@new_comment)
END
ELSE
IF @note_type = 3
BEGIN
	UPDATE dbo.CLIENTS
	SET IS_IN_BLACK_LIST = @b
	WHERE CLIENT_NO = @client_no AND IS_IN_BLACK_LIST <> @b

	DELETE FROM dbo.CLIENT_ATTRIBUTES
	WHERE CLIENT_NO = @client_no AND ATTRIB_CODE = '$IS_IN_BLACK_LIST_COMMENT'
	
	IF @b <> 0
		INSERT INTO dbo.CLIENT_ATTRIBUTES (CLIENT_NO,ATTRIB_CODE,ATTRIB_VALUE)
		VALUES (@client_no,'$IS_IN_BLACK_LIST_COMMENT',@new_comment)
END

CLOSE cc
DEALLOCATE cc

COMMIT
GO
