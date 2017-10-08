SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[send_doc_send2swift]
	@doc_rec_id int,
	@swift_filename varchar(255),
	@uid int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@rec_uid int,
	@doc_date smalldatetime,
	@ref_num varchar(32),
	@amount money,
	@iso TISO,
	@debit_id int,
	@correspondent_bank_id int,
	@finalyze_bank_id int

BEGIN TRAN

SELECT @rec_uid = UID, @doc_date = DOC_DATE, @ref_num = REF_NUM, @amount = AMOUNT, @iso = ISO, @debit_id = DOC_CREDIT_ID, @correspondent_bank_id = CORRESPONDENT_BANK_ID, @finalyze_bank_id = FINALYZE_BANK_ID
FROM impexp.DOCS_OUT_SWIFT (UPDLOCK)
WHERE DOC_REC_ID = @doc_rec_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

DECLARE
	@r int,
	@today smalldatetime, 
	@swift_msg varchar(4000)

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

EXEC @r = impexp.swift_message_builder
	@doc_rec_id = @doc_rec_id,
	@doc_date = @today,
	@swift_msg = @swift_msg OUTPUT
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE 
	@rec_id int,
	@descrip varchar(150),
	@credit_id int,
	@head_branch_id int,
	@finalyze_iso TISO,
	@finalyze_amount money

SET @head_branch_id = dbo.bank_head_branch_id()

SELECT @credit_id = dbo.acc_get_acc_id(@head_branch_id, NOSTRO_ACCOUNT, ISO), @finalyze_iso = ISO
FROM dbo.CORRESPONDENT_BANKS (NOLOCK)
WHERE REC_ID = @finalyze_bank_id

SET @descrip = 'ÓÀÊÏÒÄÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÃÀáÖÒÅÀ. ÒÄ×. #' + CONVERT(varchar(20),@ref_num)

IF @finalyze_iso = @iso
BEGIN
	SET @finalyze_amount = @amount

	EXEC @r = dbo.ADD_DOC4
		@rec_id = @rec_id OUTPUT
		,@user_id = 6	-- NBG
		,@doc_type = 95	-- Memo
		,@doc_date = @today
		,@doc_date_in_doc = @today
		,@debit_id = @debit_id
		,@credit_id = @credit_id
		,@iso = @iso
		,@amount = @finalyze_amount
		,@rec_state = 10
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
	DECLARE
		@rec_id_2 int

	SET @finalyze_amount = dbo.get_cross_amount(@amount, @iso, @finalyze_iso, @today)

	EXEC @r = dbo.ADD_CONV_DOC4
		@rec_id_1 = @rec_id OUTPUT
		,@rec_id_2 = @rec_id_2 OUTPUT
		,@user_id = 6	-- NBG
		,@iso_d = @iso              
		,@iso_c = @finalyze_iso              
		,@amount_d = @amount          
		,@amount_c = @finalyze_amount
		,@debit_id = @debit_id
		,@credit_id = @credit_id
		,@doc_date = @today
		,@op_code = '*FX_SW'
		,@rec_state = 10
		,@descrip1 = @descrip
		,@descrip2 = @descrip
		,@dept_no = @head_branch_id
		,@channel_id = 600
		,@flags = 6
		,@check_saldo = 0
		,@add_tariff = 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

UPDATE impexp.DOCS_OUT_SWIFT
SET UID = UID + 1,
	STATE = 4, --psFinished
	EXPORT_TIME = GETDATE(),
	FINISH_TIME = GETDATE(),
	FINALYZE_DATE = @today,
	FINALYZE_ACC_ID = @credit_id,
	FINALYZE_AMOUNT = @finalyze_amount,
	FINALYZE_ISO = @finalyze_iso,
	FINALYZE_DOC_REC_ID = @rec_id,
	SWIFT_TEXT = @swift_msg,
	SWIFT_FILENAME = @swift_filename
WHERE DOC_REC_ID = @doc_rec_id and UID = @uid
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

IF @doc_date < dbo.bank_open_date()
	UPDATE dbo.DOC_DETAILS_ARC_VALPLAT
	SET SWIFT_TEXT = SUBSTRING(@swift_msg, 1, 4000)
	WHERE DOC_REC_ID = @doc_rec_id
ELSE
	UPDATE dbo.DOC_DETAILS_VALPLAT
	SET SWIFT_TEXT = SUBSTRING(@swift_msg, 1, 4000)
	WHERE DOC_REC_ID = @doc_rec_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES (DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@doc_rec_id, @user_id, 100, 'ÓÀÁÖÈÉÓ ÂÀÂÆÀÅÍÀ ÓÅÉ×ÔÛÉ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
