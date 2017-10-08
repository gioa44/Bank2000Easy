SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[docs_in_swift_finalyze_edit]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
    @finalyze_date smalldatetime,
    @finalyze_bank_id int,
    @finalyze_amount money,
	@user_id int
AS

SET NOCOUNT ON

BEGIN TRAN

DECLARE
	@date2 smalldatetime,
	@rec_uid int,
	@ref_num varchar(32),
	@iso TISO,
	@amount money,
	@finalyze_doc_rec_id int,
	@finalyze_date_old smalldatetime,
	@finalyze_acc_id_old int,
	@finalyze_amount_old money,
	@finalyze_iso_old TISO

SELECT @rec_uid = [UID], @ref_num = REF_NUM, @date2 = DATE, @iso = ISO, @amount = AMOUNT,
	@finalyze_doc_rec_id = FINALYZE_DOC_REC_ID,
	@finalyze_date_old = FINALYZE_DATE, @finalyze_acc_id_old = FINALYZE_ACC_ID,
	@finalyze_amount_old = FINALYZE_AMOUNT, @finalyze_iso_old = FINALYZE_ISO
FROM impexp.DOCS_IN_SWIFT (UPDLOCK)
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

DECLARE
	@return_row bit

SET @return_row = 1

IF @finalyze_date IS NULL
BEGIN
	SET @finalyze_date = @date2
	SET @return_row = 0
END

IF @finalyze_amount IS NULL
	SELECT @finalyze_amount = @amount

DECLARE 
	@credit TACCOUNT,
	@credit_id int,
	@head_branch_id int,
	@error_msg varchar(200)

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VP', @credit OUTPUT
IF @credit = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌËÉÃÀÍÀÝ ÌÏáÃÄÁÀ ÜÀÒÉÝáÅÄÁÉ ÓáÅÀ ÁÀÍÊÄÁÉÃÀÍ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END

SET @head_branch_id = dbo.bank_head_branch_id()
SET @credit_id = dbo.acc_get_acc_id(@head_branch_id, @credit, @iso)

IF @credit_id IS NULL
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @credit) + '/' + @iso + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END


DECLARE
	@r int,
	@rec_id int,
	@rec_id_2 int,
	@today smalldatetime,
	@descrip varchar(150),
	@finalyze_acc_id int,
	@finalyze_iso TISO

SET @head_branch_id = dbo.bank_head_branch_id()

SET @today = convert(smalldatetime,floor(convert(real,getdate())))
SET @descrip = 'ÓÀÊÏÒÄÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÓßÏÒÄÁÀ. ÒÄ×. #' + CONVERT(varchar(20),@ref_num)

IF @finalyze_doc_rec_id IS NOT NULL
BEGIN
	EXECUTE @r = dbo.DELETE_DOC
	   @rec_id = @finalyze_doc_rec_id
	  ,@uid = NULL
	  ,@user_id = 6 -- NBG
	  ,@check_saldo = 0
	  ,@dont_check_up = 1
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

SELECT @finalyze_acc_id = dbo.acc_get_acc_id(@head_branch_id, NOSTRO_ACCOUNT, ISO), @finalyze_iso = ISO
FROM dbo.CORRESPONDENT_BANKS
WHERE REC_ID = @finalyze_bank_id

SET @descrip = 'ÓÀÊÏÒÄÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÃÀáÖÒÅÀ. ÒÄ×. #' + CONVERT(varchar(20),@ref_num)

SET @rec_id = NULL

IF @finalyze_iso = @iso
BEGIN
	EXECUTE @r = dbo.ADD_DOC4
		@rec_id = @rec_id OUTPUT
		,@user_id = 6	-- NBG
		,@doc_type = 95	-- Memo
		,@doc_date = @finalyze_date
		,@doc_date_in_doc = @today
		,@debit_id = @finalyze_acc_id
		,@credit_id = @credit_id
		,@iso = @iso
		,@amount = @amount
		,@rec_state = 20
		,@descrip = @descrip
		,@op_code = '*SWT'
		,@parent_rec_id = 0
		,@dept_no = @head_branch_id
		,@channel_id = 600
		,@flags = 6
		,@check_saldo = 0
		,@add_tariff = 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END
ELSE
BEGIN
	EXEC @r = dbo.ADD_CONV_DOC4
		@rec_id_1 = @rec_id OUTPUT
		,@rec_id_2 = @rec_id_2 OUTPUT
		,@user_id = 6	-- NBG
		,@iso_d = @finalyze_iso
		,@iso_c = @iso
		,@amount_d = @finalyze_amount
		,@amount_c = @amount
		,@debit_id = @finalyze_acc_id
		,@credit_id = @credit_id
		,@doc_date = @finalyze_date
		,@op_code = '*FX_SW'
		,@rec_state = 20
		,@descrip1 = @descrip
		,@descrip2 = @descrip
		,@dept_no = @head_branch_id
		,@channel_id = 600
		,@flags = 6
		,@check_saldo = 0
		,@add_tariff = 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

SET @finalyze_doc_rec_id = @rec_id

DECLARE @tbl TABLE (REC_ID int NOT NULL, [USER_ID] int NOT NULL, DATE_TIME smalldatetime NOT NULL, CHANGE_TYPE int NOT NULL, DESCRIP varchar(255))

INSERT INTO @tbl (REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM impexp.DOCS_IN_SWIFT_CHANGES
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_SWIFT
SET UID = UID + 1,
	IS_FINALYZED = 1,
	FINALYZE_DATE = @finalyze_date,
	FINALYZE_BANK_ID = @finalyze_bank_id,
	FINALYZE_ACC_ID = @finalyze_acc_id,
	FINALYZE_AMOUNT = @finalyze_amount,
	FINALYZE_ISO = @finalyze_iso,
	FINALYZE_DOC_REC_ID = @finalyze_doc_rec_id
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 80, 'ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÃÀáÖÒÅÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT

IF @return_row = 1
	SELECT *
	FROM impexp.V_DOCS_IN_SWIFT
	WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

RETURN 0
GO
