SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_reject_in_nbg]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE 
	@debit TACCOUNT,
	@credit TACCOUNT,
	@debit_id int,
	@credit_id int,
	@head_branch_id int,
	@error_msg varchar(200)

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NP', @debit OUTPUT
EXEC dbo.GET_SETTING_ACC 'NBG_RECV_ACC', @credit OUTPUT
IF ISNULL(@debit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌËÉÃÀÍÀÝ ÌÏáÃÄÁÀ ÜÀÒÉÝáÅÄÁÉ ÓáÅÀ ÁÀÍÊÄÁÉÃÀÍ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	RETURN 1 
END
IF ISNULL(@credit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ËÀÒÉÓ ÜÀÒÉÝáÅÄÁÉ ÌÏÅÉÃÄÓ ÛÄÌÃÄÂÉ ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÃÀÍ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	RETURN 1
END

SET @head_branch_id = dbo.bank_head_branch_id()
SET @debit_id = dbo.acc_get_acc_id(@head_branch_id, @debit, 'GEL')
SET @credit_id = dbo.acc_get_acc_id(@head_branch_id, @credit, 'GEL')

IF @debit_id IS NULL
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + ' - ' + convert(varchar(20), @debit) + '/GEL' + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	RETURN 1
END
IF @credit = 0
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + ' - ' + convert(varchar(20), @credit) + '/GEL' + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	RETURN 1
END

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_in_nbg @date, @por, @user_id, 2, default, default, 'ÃÀÁÒÀÊÅÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE 
	@amount money,
	@old_uid int

SELECT @amount = [SUM], @old_uid = UID
FROM impexp.DOCS_IN_NBG (UPDLOCK)
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

IF @uid <> @old_uid
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

DECLARE 
	@rec_id int,
	@today smalldatetime,
	@descrip varchar(150)

SET @today = convert(smalldatetime,floor(convert(real,getdate())))
SET @descrip = 'ÄÒÏÅÍÖËÉ ÁÀÍÊÉÃÀÍ ÜÀÒÉÝáÅÀ. ÐÏÒÝÉÀ #' + CONVERT(varchar(20),@por)

EXECUTE @r = dbo.ADD_DOC4
   @rec_id = @rec_id OUTPUT
  ,@user_id = 6	-- NBG
  ,@doc_type = 95	-- Memo
  ,@doc_num = @por
  ,@doc_date = @date
  ,@doc_date_in_doc = @today
  ,@debit_id = @debit_id
  ,@credit_id = @credit_id
  ,@iso = 'GEL'
  ,@amount = @amount
  ,@rec_state = 20
  ,@descrip = @descrip
  ,@op_code = '*NBG-'
  ,@parent_rec_id = 0
  ,@dept_no = @head_branch_id
  ,@flags = 0
  ,@check_saldo = 0
  ,@add_tariff = 0
  ,@channel_id = 500
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

DECLARE @tbl TABLE (REC_ID int NOT NULL, [USER_ID] int NOT NULL, DATE_TIME smalldatetime NOT NULL, CHANGE_TYPE int NOT NULL, DESCRIP varchar(255))

INSERT INTO @tbl (REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM impexp.DOCS_IN_NBG_CHANGES
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_NBG
SET STATE = 99, DOC_REC_ID = @rec_id, UID = UID + 1
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_NBG_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_NBG_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 60, 'ÓÀÁÖÈÉÓ ÃÀÁÒÀÊÅÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
