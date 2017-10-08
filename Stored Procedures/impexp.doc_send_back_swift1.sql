SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[doc_send_back_swift1]
	@doc_rec_id int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@rec_uid int,
	@ref_num varchar(32),
	@doc_date smalldatetime,
	@old_flags int,
	@amount money,
	@iso TISO

SELECT @rec_uid = UID, @doc_date = DOC_DATE, @old_flags = OLD_FLAGS, @ref_num = REF_NUM, @amount = AMOUNT, @iso = ISO
FROM impexp.DOCS_OUT_SWIFT
WHERE DOC_REC_ID = @doc_rec_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

BEGIN TRAN

DECLARE
	@r int

IF @doc_date >= dbo.bank_open_date() -- The document is still in open day
BEGIN
	EXEC @r = dbo.CHANGE_DOC_STATE
		@rec_id = @doc_rec_id,	-- საბუთის შიდა №
		@uid = null,			-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
		@user_id = @user_id,	-- ვინ ცვლის საბუთს
		@new_rec_state = 15,	-- საბუთის ახალი სტატუსი
		@check_saldo = 0		-- შეამოწმოს თუ არა მინ. ნაშთი
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

	UPDATE dbo.OPS_0000
	SET FLAGS = @old_flags, UID = UID + 1
	WHERE REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END
ELSE
BEGIN
	DECLARE
		@rec_id int,
		@head_branch_id int,
		@debit_id int,
		@credit_id int,
		@today smalldatetime,
		@descrip varchar(150)

	SET @today = convert(smalldatetime,floor(convert(real,getdate())))
	SET @descrip = 'ÓÅÉ×ÔÉÈ ÂÀÃÀÒÉÝáÖËÉ ÓÀÁÖÈÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ. ÒÄ×. #' + CONVERT(varchar(20), @ref_num)
	SET @head_branch_id = dbo.bank_head_branch_id()

	SELECT @credit_id = DEBIT_ID, @debit_id = CREDIT_ID
	FROM dbo.DOCS_ARC
	WHERE REC_ID = @doc_rec_id AND DOC_DATE = @doc_date

	-- Add returning document
	EXEC @r = dbo.ADD_DOC4
	   @rec_id = @rec_id OUTPUT
	  ,@user_id = 6	-- NBG
	  ,@doc_type = 95	-- Memo
	  ,@doc_num = 0
	  ,@doc_date = @today
	  ,@doc_date_in_doc = @doc_date
	  ,@debit_id = @debit_id
	  ,@credit_id = @credit_id
	  ,@iso = @iso
	  ,@amount = @amount
	  ,@rec_state = 20
	  ,@descrip = @descrip
	  ,@op_code = '*SWT#'
	  ,@parent_rec_id = 0
	  ,@dept_no = @head_branch_id
	  ,@flags = 0
	  ,@check_saldo = 0
	  ,@add_tariff = 0
	  ,@channel_id = 600
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

DELETE FROM impexp.DOCS_OUT_SWIFT
WHERE DOC_REC_ID = @doc_rec_id

IF @@ERROR <> 0
BEGIN
	RAISERROR ('ÛÄÝÃÏÌÀ ÓÀÁÖÈÉÓ ÃÀÁÒÖÍÄÁÉÓÀÓ!',16,1)
	IF @@TRANCOUNT > 0 ROLLBACK
	RETURN 1
END

COMMIT
GO
