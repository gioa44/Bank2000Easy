SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[docs_in_swift_edit]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@user_id int,
	@finalyze_bank_id int,
	@sender_bank_code varchar(37),
	@sender_bank_name varchar(100),
	@sender_acc varchar(37),
	@sender_acc_name varchar(100),
	@intermed_bank_code  varchar(37),
	@intermed_bank_name  varchar(100),
	@cor_bank_code varchar(37),
	@cor_bank_name varchar(100),
	@descrip  varchar(150),
	@extra_info varchar(255),
	@extra_info_descrip bit
AS

BEGIN TRAN

DECLARE
	@rec_uid int

SELECT @rec_uid = UID
FROM impexp.DOCS_IN_SWIFT (UPDLOCK)
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

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
SET UID = UID + 1, IS_MODIFIED = 1,
	FINALYZE_BANK_ID = @finalyze_bank_id,
    SENDER_BANK_CODE = @sender_bank_code,
    SENDER_BANK_NAME = @sender_bank_name,
    SENDER_ACC = @sender_acc,
    SENDER_ACC_NAME = @sender_acc_name,
    INTERMED_BANK_CODE = @intermed_bank_code,
    INTERMED_BANK_NAME = @intermed_bank_name,
    COR_BANK_CODE = @cor_bank_code,
    COR_BANK_NAME = @cor_bank_name,
    DESCRIP = @descrip,
    EXTRA_INFO = @extra_info,
    EXTRA_INFO_DESCRIP = @extra_info_descrip
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 5, 'ÓÀÁÖÈÉÓ ÛÄÝÅËÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT

SELECT *
FROM impexp.V_DOCS_IN_SWIFT
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

RETURN 0
GO
