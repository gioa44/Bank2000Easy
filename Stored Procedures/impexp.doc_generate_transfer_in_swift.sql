SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[doc_generate_transfer_in_swift]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE 
	@debit TACCOUNT,
	@debit_id int,
	@head_branch_id int,
	@error_msg varchar(200)

IF dbo.sys_has_right(@user_id, 60, 8) = 0 AND 
  EXISTS(SELECT * FROM impexp.DOCS_IN_SWIFT_CHANGES WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id AND [USER_ID] = @user_id AND CHANGE_TYPE < 10)
BEGIN
	RAISERROR ('ÀÒ ÂÀØÅÈ ÈÅÄÍÓ ÌÉÄÒ ÛÄÝÅËÉËÉ ÓÀÁÖÈÉÓ ÂÄÍÄÒÀÝÉÉÓ Ö×ËÄÁÀ.', 16, 1)	
	RETURN 1
END

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VP', @debit OUTPUT
IF @debit = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌËÉÃÀÍÀÝ ÌÏáÃÄÁÀ ÜÀÒÉÝáÅÄÁÉ ÓáÅÀ ÁÀÍÊÄÁÉÃÀÍ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	RETURN 1
END

SET @head_branch_id = dbo.bank_head_branch_id()

DECLARE 
	@rec_uid int, 
	@iso TISO,
	@ref_num varchar(32),
	@bdate smalldatetime,
	@amount money,
	@descrip varchar(150),
	@sender_bank_code varchar(37),
	@sender_bank_name varchar(100),
	@sender_acc varchar(37),
	@sender_acc_name varchar(100),
	@receiver_bank_code varchar(37),
	@receiver_bank_name varchar(100),
	@receiver_acc varchar(37),
	@receiver_acc_name varchar(100),
	@intermed_bank_code varchar(37),
	@intermed_bank_name varchar(100),
	@cor_bank_code varchar(37),
	@cor_bank_name varchar(100),
	@correspondent_bank_id int,
	@cor_country char(2),
	@tag_53x_status char(1),
	@tag_53x_value varchar(37),
	@tag_54x_status char(1),
	@tag_54x_value varchar(35),
	@extra_info varchar(255),
	@extra_info_descrip bit,
	@det_of_charg char(3),
	@swift_text varchar(max),
	@state int,
	@is_ready bit ,
	@is_finalyzed bit,
	@account TACCOUNT,
	@acc_id int,
	@other_info varchar(250),
	@error_reason varchar(100),
	@swift_file_row_id int,
	@swift_filename varchar(100),
	@finalyze_date smalldatetime,
	@finalyze_bank_id int,
	@finalyze_acc_id int,
	@finalyze_amount money,
	@finalyze_iso TISO,
	@finalyze_doc_rec_id int,
	@doc_date smalldatetime,
	@doc_rec_id int,
	@r int

BEGIN TRAN

SELECT 
	@doc_date = DOC_DATE,
	@rec_uid = [UID], 
	@ref_num = REF_NUM, 
	@bdate = DATE, 
	@iso = ISO, 
	@amount = AMOUNT, 
	@descrip = DESCRIP, 
	@sender_bank_code = SENDER_BANK_CODE, 
	@sender_bank_name = SENDER_BANK_NAME, 
	@sender_acc= SENDER_ACC, 
	@sender_acc_name = SENDER_ACC_NAME, 
	@receiver_bank_code = RECEIVER_BANK_CODE, 
	@receiver_bank_name = RECEIVER_BANK_NAME, 
	@receiver_acc = RECEIVER_ACC, 
	@receiver_acc_name = RECEIVER_ACC_NAME, 
	@intermed_bank_code = INTERMED_BANK_CODE, 
	@intermed_bank_name = INTERMED_BANK_NAME, 
	@cor_bank_code = COR_BANK_CODE, 
	@cor_bank_name = COR_BANK_NAME, 
	@correspondent_bank_id = CORRESPONDENT_BANK_ID,
	@cor_country = COR_COUNTRY, 
	@tag_53x_status = TAG_53X_STATUS, 
	@tag_53x_value = TAG_53X_VALUE, 
	@tag_54x_status = TAG_54X_STATUS, 
	@tag_54x_value = TAG_54X_VALUE, 
	@extra_info = EXTRA_INFO, 
	@extra_info_descrip = EXTRA_INFO_DESCRIP, 
	@det_of_charg = DET_OF_CHARG, 
	@swift_text = SWIFT_TEXT, 
	@state = STATE, 
	@is_ready = IS_READY, 
	@is_finalyzed = IS_FINALYZED, 
	@account = ACCOUNT, 
	@acc_id = ACC_ID, 
	@other_info = OTHER_INFO, 
	@error_reason = ERROR_REASON, 
	@swift_file_row_id = SWIFT_FILE_ROW_ID, 
	@swift_filename = SWIFT_FILENAME, 
	@finalyze_date = FINALYZE_DATE, 
	@finalyze_bank_id = FINALYZE_BANK_ID, 
	@finalyze_acc_id = FINALYZE_ACC_ID, 
	@finalyze_amount = FINALYZE_AMOUNT, 
	@finalyze_iso = FINALYZE_ISO, 
	@finalyze_doc_rec_id = FINALYZE_DOC_REC_ID, 
	@doc_rec_id = DOC_REC_ID
FROM impexp.DOCS_IN_SWIFT
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	IF @@TRANCOUNT > 0 ROLLBACK
	RETURN 1
END

SET @debit_id = dbo.acc_get_acc_id(@head_branch_id, @debit, @iso)

IF @debit_id IS NULL
BEGIN
	IF @@TRANCOUNT > 0 ROLLBACK
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @debit) + '/' + @iso + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	RETURN 1
END

IF @acc_id IS NULL
BEGIN
	DECLARE @credit TACCOUNT

	EXEC dbo.GET_SETTING_ACC 'TRANSIT_ACC_CREDIT_V', @credit OUTPUT
	IF @credit = 0
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK
		RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌËÉÃÀÍÀÝ ÌÏáÃÄÁÀ ÂÀÖÒÊÅÄÅÄËÉ ÈÀÍáÄÁÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
		RETURN 1
	END

	SET @acc_id = dbo.acc_get_acc_id(@head_branch_id, @credit, @iso)

	IF @acc_id IS NULL
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK
		SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @credit) + '/' + @iso + ' ÀÒ ÌÏÉÞÄÁÍÀ'
		RAISERROR (@error_msg , 16, 1)
		RETURN 1
	END
END

EXEC @r = dbo.ADD_DOC4
   @rec_id = @doc_rec_id OUTPUT
  ,@user_id = 6
  ,@owner = @user_id
  ,@doc_type = 114
  ,@doc_date = @doc_date
  ,@doc_date_in_doc = @bdate
  ,@debit_id = @debit_id
  ,@credit_id = @acc_id
  ,@iso = @iso
  ,@amount = @amount
  ,@rec_state = 20
  ,@descrip = @descrip
  ,@op_code = 'SWIFT'
  ,@flags = 6
  ,@doc_num = 0
  ,@dept_no = @head_branch_id
  
  ,@sender_bank_code = @sender_bank_code
  ,@sender_bank_name = @sender_bank_name
  ,@sender_acc = @sender_acc
  ,@sender_acc_name = @sender_acc_name
  
  ,@receiver_bank_code = @receiver_bank_code
  ,@receiver_bank_name = @receiver_bank_name
  ,@receiver_acc = @receiver_acc
  ,@receiver_acc_name = @receiver_acc_name

  ,@cor_bank_code = @cor_bank_code
  ,@cor_bank_name = @cor_bank_name
  ,@det_of_charg = @det_of_charg
  ,@extra_info_descrip = @extra_info_descrip
  
  ,@ref_num = @ref_num
  ,@extra_info = @extra_info 

  ,@swift_text = @swift_text

  ,@check_saldo = 0
  ,@add_tariff = 0
  ,@info = 0
  ,@channel_id = 600

IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE @tbl TABLE (REC_ID int NOT NULL, [USER_ID] int NOT NULL, DATE_TIME smalldatetime NOT NULL, CHANGE_TYPE int NOT NULL, DESCRIP varchar(255))

INSERT INTO @tbl (REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM impexp.DOCS_IN_SWIFT_CHANGES
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_SWIFT
SET UID = UID + 1, [STATE] = 4, DOC_REC_ID = @doc_rec_id
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 100, 'ÓÀÁÖÈÉÓ ÂÄÍÄÒÀÝÉÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
