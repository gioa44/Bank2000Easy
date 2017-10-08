SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_assign_acc_id_in_swift]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@acc_id int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@rec_uid int,
	@old_acc_id int,
	@old_account varchar(150),
	@new_account varchar(150),
	@iso TISO

IF @acc_id IS NULL
	SET @new_account = '(ÝÀÒÉÄËÉ)'
ELSE
	SELECT @new_account = CONVERT(varchar(10), BRANCH_ID) + ' - '+ CONVERT(varchar(20), ACCOUNT) + '/' + ISO + ' "' + DESCRIP_LAT + '"'
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @acc_id

BEGIN TRAN

SELECT @rec_uid = UID, @old_acc_id = ACC_ID, @old_account = ISNULL(CONVERT(varchar(50),ACCOUNT), '(ÝÀÒÉÄËÉ)'), @iso = ISO
FROM impexp.DOCS_IN_SWIFT (UPDLOCK)
WHERE ROW_ID = @row_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

IF @old_acc_id IS NOT NULL
	SELECT @old_account = CONVERT(varchar(10), BRANCH_ID) + ' - '+ CONVERT(varchar(20), ACCOUNT) + '/' + ISO + ' "' + DESCRIP_LAT + '"'
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @old_acc_id

DECLARE @tbl TABLE (REC_ID int NOT NULL, [USER_ID] int NOT NULL, DATE_TIME smalldatetime NOT NULL, CHANGE_TYPE int NOT NULL, DESCRIP varchar(255))

INSERT INTO @tbl (REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM impexp.DOCS_IN_SWIFT_CHANGES
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_SWIFT
SET [UID] = [UID] + 1, ACC_ID = @acc_id, IS_MODIFIED = 1 --, ACCOUNT = dbo.acc_get_account(@acc_id)
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, CASE WHEN @acc_id IS NULL THEN 3 ELSE 2 END, 'ÀÍÂÀÒÉÛÉÓ ÌÉÍÉàÄÁÀ: ' + @old_account + CASE WHEN @acc_id IS NULL THEN '/' + @iso ELSE '' END + ' -> ' + @new_account)
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
