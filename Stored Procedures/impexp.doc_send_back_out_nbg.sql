SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[doc_send_back_out_nbg]
	@doc_id int,
	@uid int,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE 
	@date smalldatetime,
	@por int,
	@amount money,
	@doc_date smalldatetime,
	@old_flags int,
	@old_uid int

SELECT @old_uid = UID, @date = PORTION_DATE, @por = PORTION, @doc_date = DOC_DATE, @amount = [SUM], @old_flags = OLD_FLAGS
FROM impexp.DOCS_OUT_NBG O
WHERE O.DOC_REC_ID = @doc_id

IF @uid <> @old_uid
BEGIN
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

BEGIN TRAN

DECLARE @r int, @state int
EXEC @r = impexp.check_portion_state_out_nbg @date, @por, @user_id, 1, 4, 99, 'ÓÀÁÖÈÉÓ ÝÅËÉËÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ', @state OUTPUT
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE 
	@debit TACCOUNT,
	@credit TACCOUNT,
	@debit_id int,
	@credit_id int,
	@head_branch_id int,
	@error_msg varchar(200)

EXEC dbo.GET_SETTING_ACC 'NBG_SEND_ACC', @debit OUTPUT
EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @credit OUTPUT
IF ISNULL(@debit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ËÀÒÉÓ ÂÀÃÀÒÉÝáÅÄÁÉ ßÀÅÉÃÄÓ ÛÄÌÃÄÂÉ ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÃÀÍ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END
IF ISNULL(@credit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌÄËÆÄÝ ßÀÅÀ ÂÀÃÀÒÉÝáÅÄÁÉ ÓáÅÀ ÁÀÍÊÛÉ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END

SET @head_branch_id = dbo.bank_head_branch_id()
SET @debit_id = dbo.acc_get_acc_id(@head_branch_id, @debit, 'GEL')
SET @credit_id = dbo.acc_get_acc_id(@head_branch_id, @credit, 'GEL')

IF @debit_id IS NULL OR @debit = 0
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @debit) + '/GEL' + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK
	RETURN 1 
END
IF @credit_id IS NULL OR @credit = 0
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @credit) + '/GEL' + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END


IF @state = 4 -- Finished
BEGIN
	DECLARE 
		@rec_id int,
		@today smalldatetime,
		@descrip varchar(150)

	SET @today = convert(smalldatetime,floor(convert(real,getdate())))
	SET @descrip = 'ÄÒÏÅÍÖË ÁÀÍÊÛÉ ÂÀÃÀÒÉÝáÖËÉ ÓÀÁÖÈÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ. ÐÏÒÝÉÀ #' + CONVERT(varchar(20),@por)


	-- კორ. ანგარიშის გასწორება
	EXECUTE @r = dbo.ADD_DOC4
	   @rec_id = @rec_id OUTPUT
	  ,@user_id = 6	-- NBG
	  ,@doc_type = 95	-- Memo
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
	  ,@doc_num = @por
	  ,@dept_no = @head_branch_id
	  ,@flags = 1
	  ,@check_saldo = 0
	  ,@add_tariff = 0
	  ,@channel_id = 500
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

IF @doc_date >= dbo.bank_open_date() -- The document is still in open day
BEGIN
	EXEC @r = dbo.CHANGE_DOC_STATE
		@rec_id = @doc_id,		-- საბუთის შიდა №
		@uid = null,			-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
		@user_id = @user_id,	-- ვინ ცვლის საბუთს
		@new_rec_state = 15,	-- საბუთის ახალი სტატუსი
		@check_saldo = 0		-- შეამოწმოს თუ არა მინ. ნაშთი
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

	UPDATE dbo.OPS_0000
	SET FLAGS = @old_flags, UID = UID + 1
	WHERE REC_ID = @doc_id
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END
ELSE
BEGIN
	SET @debit_id = @credit_id

	SELECT @credit_id = DEBIT_ID
	FROM dbo.DOCS_ARC
	WHERE REC_ID = @doc_id AND DOC_DATE = @doc_date

	-- Add returning document
	EXEC @r = dbo.ADD_DOC4
	   @rec_id = @rec_id OUTPUT
	  ,@user_id = 6	-- NBG
	  ,@doc_type = 95	-- Memo
	  ,@doc_num = @por
	  ,@doc_date = @date
	  ,@doc_date_in_doc = @doc_date
	  ,@debit_id = @debit_id
	  ,@credit_id = @credit_id
	  ,@iso = 'GEL'
	  ,@amount = @amount
	  ,@rec_state = 20
	  ,@descrip = @descrip
	  ,@op_code = '*NBG#'
	  ,@parent_rec_id = 0
	  ,@dept_no = @head_branch_id
	  ,@flags = 0
	  ,@check_saldo = 0
	  ,@add_tariff = 0
	  ,@channel_id = 500
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
END

DELETE FROM impexp.DOCS_OUT_NBG
WHERE DOC_REC_ID = @doc_id
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT
GO
