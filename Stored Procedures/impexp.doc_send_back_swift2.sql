SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_send_back_swift2]
	@doc_rec_id int,
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
	@credit_id int,
	@finalyze_amount money,
	@finalyze_iso TISO,
	@finalyze_date smalldatetime,
	@finalyze_doc_rec_id int

BEGIN TRAN

SELECT @rec_uid = UID, @doc_date = DOC_DATE, @ref_num = REF_NUM, @amount = AMOUNT, @iso = ISO,
	@debit_id = FINALYZE_ACC_ID, @credit_id = DOC_CREDIT_ID,
	@finalyze_date = FINALYZE_DATE, @finalyze_iso = FINALYZE_ISO, @finalyze_amount = FINALYZE_AMOUNT,
	@finalyze_doc_rec_id = FINALYZE_DOC_REC_ID
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
	@today smalldatetime,
	@descrip varchar(150),
	@head_branch_id int

SET @head_branch_id = dbo.bank_head_branch_id()

SET @today = convert(smalldatetime,floor(convert(real,getdate())))
SET @descrip = 'ÓÀÊÏÒÄÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÓßÏÒÄÁÀ. ÒÄ×. #' + CONVERT(varchar(20),@ref_num)

IF @finalyze_doc_rec_id IS NOT NULL
BEGIN
	IF @finalyze_date >= dbo.bank_open_date()
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
		IF @finalyze_iso = @iso
		BEGIN
			EXECUTE @r = dbo.ADD_DOC4
				@rec_id = @rec_id OUTPUT
				,@user_id = 6	-- NBG
				,@doc_type = 95	-- Memo
				,@doc_date = @today
				,@doc_date_in_doc = @today
				,@debit_id = @debit_id
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
		DECLARE
			@rec_id_2 int

			EXEC @r = dbo.ADD_CONV_DOC4
				@rec_id_1 = @rec_id OUTPUT
				,@rec_id_2 = @rec_id_2 OUTPUT
				,@user_id = 6	-- NBG
				,@iso_d = @finalyze_iso
				,@iso_c = @iso
				,@amount_d = @finalyze_amount
				,@amount_c = @amount
				,@debit_id = @debit_id
				,@credit_id = @credit_id
				,@doc_date = @today
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
	END
END

UPDATE impexp.DOCS_OUT_SWIFT
SET UID = UID + 1,
	STATE = 14, --psPrepared
	EXPORT_TIME = NULL,
	FINISH_TIME = NULL,
	FINALYZE_DATE = NULL,
	FINALYZE_ACC_ID = NULL,
	FINALYZE_AMOUNT = NULL,
	FINALYZE_ISO = NULL,
	FINALYZE_DOC_REC_ID = NULL,
	SWIFT_TEXT = NULL,
	SWIFT_FILENAME = NULL
WHERE DOC_REC_ID = @doc_rec_id and UID = @uid
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

IF @doc_date < dbo.bank_open_date()
	UPDATE dbo.DOC_DETAILS_ARC_VALPLAT
	SET SWIFT_TEXT = NULL
	WHERE DOC_REC_ID = @doc_rec_id
ELSE
	UPDATE dbo.DOC_DETAILS_VALPLAT
	SET SWIFT_TEXT = NULL
	WHERE DOC_REC_ID = @doc_rec_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES (DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@doc_rec_id, @user_id, 60, 'ÓÀÁÖÈÉÓ ÃÀÁÒÖÍÄÁÀ ÓÅÉ×ÔÉÃÀÍ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT

RETURN @@ERROR
GO
