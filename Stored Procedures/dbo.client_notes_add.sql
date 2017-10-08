SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[client_notes_add] 
	@client_no int,
	@note_type int, -- ÛÄÍÉÛÅÍÀ = 0
					-- ÊÏÍÔÒÏËÆÄ ÀÚÅÀÍÀ = 1
					-- ÛÀÅ ÓÉÀÛÉ ÛÄÚÅÀÍÀ = 3
	@user_id int,
	@comment varchar(250),
	@prod_id int = null,
	@foreign_id int = null,
	
	@client_note_id int = null OUTPUT -- ÀÁÒÖÍÄÁÓ ÃÀÌÀÔÄÁÖËÉ ÛÄÍÉÛÅÍÉÓ ID-Ó
AS

SET NOCOUNT ON;

BEGIN TRAN

INSERT INTO dbo.CLIENT_NOTES (CLIENT_NO,DATE,NOTE_TYPE,[USER_ID],COMMENT,REC_STATE,PROD_ID,FOREIGN_ID)
VALUES (@client_no,GETDATE(),@note_type,@user_id,@comment,0,@prod_id,@foreign_id)

SET @client_note_id = SCOPE_IDENTITY()

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

IF @note_type = 1
BEGIN
	UPDATE dbo.CLIENTS
	SET IS_CONTROL = 1
	WHERE CLIENT_NO = @client_no AND IS_CONTROL = 0

	DELETE FROM dbo.CLIENT_ATTRIBUTES
	WHERE CLIENT_NO = @client_no AND ATTRIB_CODE = '$IS_CONTROL_COMMENT'

	INSERT INTO dbo.CLIENT_ATTRIBUTES (CLIENT_NO,ATTRIB_CODE,ATTRIB_VALUE)
	VALUES (@client_no,'$IS_CONTROL_COMMENT',@new_comment)
END
ELSE
IF @note_type = 3
BEGIN
	UPDATE dbo.CLIENTS
	SET IS_IN_BLACK_LIST = 1
	WHERE CLIENT_NO = @client_no AND IS_IN_BLACK_LIST = 0

	DELETE FROM dbo.CLIENT_ATTRIBUTES
	WHERE CLIENT_NO = @client_no AND ATTRIB_CODE = '$IS_IN_BLACK_LIST_COMMENT'

	INSERT INTO dbo.CLIENT_ATTRIBUTES (CLIENT_NO,ATTRIB_CODE,ATTRIB_VALUE)
	VALUES (@client_no,'$IS_IN_BLACK_LIST_COMMENT',@new_comment)
END

CLOSE cc
DEALLOCATE cc

COMMIT
GO
