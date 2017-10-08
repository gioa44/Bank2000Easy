SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_set_is_authorized_in_nbg]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@is_authorized bit,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE 
	@old_uid int,
	@old_is_auth bit

BEGIN TRAN

SELECT @old_uid = UID, @old_is_auth = IS_AUTHORIZED
FROM impexp.DOCS_IN_NBG (UPDLOCK)
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

IF @uid <> @old_uid
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

DECLARE @tbl TABLE (REC_ID int NOT NULL, [USER_ID] int NOT NULL, DATE_TIME smalldatetime NOT NULL, CHANGE_TYPE int NOT NULL, DESCRIP varchar(255))

INSERT INTO @tbl (REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM impexp.DOCS_IN_NBG_CHANGES
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_NBG
SET IS_AUTHORIZED = @is_authorized, UID = UID + 1
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_NBG_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_NBG_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 36 - @is_authorized, 'ÓÀÁÖÈÉÓ ÀÅÔÏÒÉÆÀÝÉÉÓ ÛÄÝÅËÀ: ' + CONVERT(varchar(10), @old_is_auth) + ' -> ' + CONVERT(varchar(10), @is_authorized))
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
