SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[portion_authorize_in_nbg]
	@date smalldatetime, 
	@por int,
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

EXEC dbo.GET_SETTING_ACC 'NBG_RECV_ACC', @debit OUTPUT
EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NP', @credit OUTPUT
IF @debit = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ËÀÒÉÓ ÜÀÒÉÝáÅÄÁÉ ÌÏÅÉÃÄÓ ÛÄÌÃÄÂÉ ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÃÀÍ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	IF @@TRANCOUNT > 0 ROLLBACK
	RETURN 1 
END
IF @credit = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌËÉÃÀÍÀÝ ÌÏáÃÄÁÀ ÜÀÒÉÝáÅÄÁÉ ÓáÅÀ ÁÀÍÊÄÁÉÃÀÍ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)
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

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_in_nbg @date, @por, @user_id, 1, default, default, 'ÀÅÔÏÒÉÆÀÝÉÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE @amount money, @count int

SELECT @amount = AMOUNT, @count = [COUNT]
FROM impexp.PORTIONS_IN_NBG 
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

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
  ,@op_code = '*NBG+'
  ,@parent_rec_id = 0
  ,@dept_no = @head_branch_id
  ,@flags = 0
  ,@check_saldo = 0
  ,@add_tariff = 0
  ,@channel_id = 500
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

UPDATE impexp.PORTIONS_IN_NBG 
SET STATE = 2, DOC_REC_ID = @rec_id -- Closed
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT
GO
