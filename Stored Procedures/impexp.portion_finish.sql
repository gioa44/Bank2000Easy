SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[portion_finish] 
	@date smalldatetime, 
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_out_nbg @date, @por, @user_id, 3, default, default, 'ÃÀÓÒÖËÄÁÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE 
	@debit TACCOUNT,
	@credit TACCOUNT,
	@debit_id int,
	@credit_id int,
	@head_branch_id int,
	@error_msg varchar(200)

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @debit OUTPUT
EXEC dbo.GET_SETTING_ACC 'NBG_SEND_ACC', @credit OUTPUT
IF ISNULL(@debit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌÄËÆÄÝ ßÀÅÀ ÂÀÃÀÒÉÝáÅÄÁÉ ÓáÅÀ ÁÀÍÊÛÉ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	IF @@TRANCOUNT > 0 ROLLBACK
	RETURN 1 
END
IF ISNULL(@credit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ËÀÒÉÓ ÂÀÃÀÒÉÝáÅÄÁÉ ßÀÅÉÃÄÓ ÛÄÌÃÄÂÉ ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÃÀÍ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END

SET @head_branch_id = dbo.bank_head_branch_id()
SET @debit_id = dbo.acc_get_acc_id(@head_branch_id, @debit, 'GEL')
SET @credit_id = dbo.acc_get_acc_id(@head_branch_id, @credit, 'GEL')

IF @debit_id IS NULL
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @debit) + '/GEL' + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END
IF @credit = 0
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @credit) + '/GEL' + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END

DECLARE @amount money, @count int

SELECT @amount = AMOUNT, @count = COUNT
FROM impexp.PORTIONS_OUT_NBG 
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

DECLARE 
	@rec_id int,
	@today smalldatetime,
	@descrip varchar(150)

SET @today = convert(smalldatetime,floor(convert(real,getdate())))
SET @descrip = 'ÄÒÏÅÍÖË ÁÀÍÊÛÉ ÂÀÃÀÒÉÝáÅÀ. ÐÏÒÝÉÀ #' + CONVERT(varchar(20),@por)

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
  ,@flags = 6 -- Cannot delete or edit
  ,@check_saldo = 0
  ,@add_tariff = 0
  ,@channel_id = 500
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

UPDATE impexp.PORTIONS_OUT_NBG 
SET STATE = 4, DOC_REC_ID = @rec_id, FINISH_TIME = GETDATE() -- Finished
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

EXECUTE @r = impexp.on_user_after_portion_out_nbg_finished @date, @por
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT
GO
