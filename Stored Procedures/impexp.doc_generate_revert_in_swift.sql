SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_generate_revert_in_swift]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE 
	@doc_rec_id int,
	@old_uid int,
	@rec_state tinyint,
	@r int

SELECT @doc_rec_id = DOC_REC_ID, @old_uid = UID
FROM impexp.DOCS_IN_SWIFT
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

IF @uid <> @old_uid
BEGIN
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	ROLLBACK 
	RETURN 1
END


IF @doc_rec_id IS NOT NULL
BEGIN
	SELECT @rec_state = REC_STATE
	FROM dbo.OPS_0000
	WHERE REC_ID = @doc_rec_id
	
	IF @rec_state >= 10
	BEGIN
		RAISERROR ('ÀÌ ÓÀÁÖÈÉÓ ÛÄÓÀÁÀÌÉÓÉ ÓÀÂÀÃÀÓÀáÀÃÏ ÃÀÅÀËÄÁÀ ÀÅÔÏÒÉÆÄÁÖËÉÀ. ÓÀÁÖÈÉÓ ÀÙÃÂÄÍÀ ÀÒ ÛÄÉÞËÄÁÀ.', 16, 1)
		IF @@TRANCOUNT > 0 ROLLBACK 
		RETURN 1
	END

	EXECUTE @r = dbo.DELETE_DOC
	   @rec_id = @doc_rec_id
	  ,@uid = NULL
	  ,@user_id = @user_id
	  ,@check_saldo = 0
	  ,@dont_check_up = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

DECLARE @tbl TABLE (REC_ID int NOT NULL, [USER_ID] int NOT NULL, DATE_TIME smalldatetime NOT NULL, CHANGE_TYPE int NOT NULL, DESCRIP varchar(255))

INSERT INTO @tbl (REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM impexp.DOCS_IN_SWIFT_CHANGES
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_SWIFT
SET STATE = 21, DOC_REC_ID = NULL, UID = UID + 1
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 51, 'ÓÀÁÖÈÉÓ ÂÄÍÄÒÀÝÉÉÓ ÛÄØÝÄÅÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
