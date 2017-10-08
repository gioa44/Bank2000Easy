SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_assign_doc_date_in_swift]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@doc_date smalldatetime,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE
	@rec_uid int,
	@old_date smalldatetime

BEGIN TRAN

SELECT @rec_uid = [UID], @old_date = DOC_DATE
FROM impexp.DOCS_IN_SWIFT (UPDLOCK)
WHERE ROW_ID = @row_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

DECLARE @tbl TABLE (REC_ID int NOT NULL, [USER_ID] int NOT NULL, DATE_TIME smalldatetime NOT NULL, CHANGE_TYPE int NOT NULL, DESCRIP varchar(255))

INSERT INTO @tbl (REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM impexp.DOCS_IN_SWIFT_CHANGES
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_SWIFT
SET DOC_DATE = @doc_date, UID = UID + 1, IS_MODIFIED = 1
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 1, 'ÈÀÒÉÙÉÓ ÝÅËÉËÄÁÀ: ' + CONVERT(varchar(20), @old_date, 103) + ' -> ' + CONVERT(varchar(20), @doc_date, 103))
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
