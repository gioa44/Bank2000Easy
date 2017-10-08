SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[docs_out_swift_finalyze_edit]
	@doc_rec_id int,
	@uid int,
	@user_id int,
    @finalyze_date smalldatetime,
    @finalyze_bank_id int,
    @finalyze_amount money
AS

DECLARE
	@rec_uid int,
	@ref_num varchar(32),
	@iso TISO,
	@amount money,
	@doc_credit_id int,
	@finalyze_doc_rec_id int,
	@finalyze_date_old smalldatetime,
	@finalyze_acc_id_old int,
	@finalyze_amount_old money,
	@finalyze_iso_old TISO

BEGIN TRAN

SELECT @rec_uid = [UID], @ref_num = REF_NUM, @iso = ISO, @doc_credit_id = DOC_CREDIT_ID, @amount = AMOUNT,
	@finalyze_doc_rec_id = FINALYZE_DOC_REC_ID,
	@finalyze_date_old = FINALYZE_DATE, @finalyze_acc_id_old = FINALYZE_ACC_ID,
	@finalyze_amount_old = FINALYZE_AMOUNT, @finalyze_iso_old = FINALYZE_ISO
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
	@rec_id int,
	@rec_id_2 int,
	@today smalldatetime,
	@descrip varchar(150),
	@head_branch_id int,
	@finalyze_acc_id int,
	@finalyze_iso TISO

SET @head_branch_id = dbo.bank_head_branch_id()

SET @today = convert(smalldatetime,floor(convert(real,getdate())))
SET @descrip = 'ÓÀÊÏÒÄÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÓßÏÒÄÁÀ. ÒÄ×. #' + CONVERT(varchar(20),@ref_num)

IF @finalyze_doc_rec_id IS NOT NULL
BEGIN
	IF @finalyze_date_old >= dbo.bank_open_date()
	BEGIN
		EXECUTE @r = dbo.DELETE_DOC
		   @rec_id = @finalyze_doc_rec_id
		  ,@uid = NULL
		  ,@user_id = 6 -- NBG
		  ,@check_saldo = 0
		  ,@dont_check_up = 1
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
	END
	ELSE
	BEGIN
		IF @finalyze_iso_old = @iso
		BEGIN
			EXECUTE @r = dbo.ADD_DOC4
				@rec_id = @rec_id OUTPUT
				,@user_id = 6	-- NBG
				,@doc_type = 95	-- Memo
				,@doc_date = @today
				,@doc_date_in_doc = @today
				,@debit_id = @finalyze_acc_id_old
				,@credit_id = @doc_credit_id
				,@iso = @iso
				,@amount = @finalyze_amount_old
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
			EXEC @r = dbo.ADD_CONV_DOC4
				@rec_id_1 = @rec_id OUTPUT
				,@rec_id_2 = @rec_id_2 OUTPUT
				,@user_id = 6	-- NBG
				,@iso_d = @finalyze_iso_old
				,@iso_c = @iso
				,@amount_d = @finalyze_amount_old
				,@amount_c = @amount
				,@debit_id = @finalyze_acc_id_old
				,@credit_id = @doc_credit_id
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
	END
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
		,@debit_id = @doc_credit_id
		,@credit_id = @finalyze_acc_id
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
	EXEC @r = dbo.ADD_CONV_DOC4
		@rec_id_1 = @rec_id OUTPUT
		,@rec_id_2 = @rec_id_2 OUTPUT
		,@user_id = 6	-- NBG
		,@iso_d = @iso
		,@iso_c = @finalyze_iso
		,@amount_d = @amount
		,@amount_c = @finalyze_amount
		,@debit_id = @doc_credit_id
		,@credit_id = @finalyze_acc_id
		,@doc_date = @finalyze_date
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

SET @finalyze_doc_rec_id = @rec_id

UPDATE impexp.DOCS_OUT_SWIFT
SET UID = UID + 1,
	FINALYZE_DATE = @finalyze_date,
	FINALYZE_BANK_ID = @finalyze_bank_id,
	FINALYZE_ACC_ID = @finalyze_acc_id,
	FINALYZE_AMOUNT = @finalyze_amount,
	FINALYZE_ISO = @finalyze_iso,
	FINALYZE_DOC_REC_ID = @finalyze_doc_rec_id
WHERE DOC_REC_ID = @doc_rec_id and UID = @uid
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES(DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES(@doc_rec_id, @user_id, 80, 'ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÃÀáÖÒÅÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT

SELECT *
FROM impexp.V_DOCS_OUT_SWIFT
WHERE DOC_REC_ID = @doc_rec_id

RETURN 0
GO
