SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_INCASSO_OUT_OFF_BAL_DOC]
	@rec_id int, @user_id int
AS
SET NOCOUNT ON

DECLARE
	@r int,
	@debit_id int,
	@credit_id int,
	@dept_no int,
	@client_no int,
	@doc_date smalldatetime,
	@amount TAMOUNT,
	@acc_template varchar(20),
	@bal_acc_alt int,
	@account TACCOUNT

SET @bal_acc_alt = 901

SELECT	@client_no = CLIENT_NO, @debit_id = ACC_ID, @doc_date = DOC_DATE, @amount = AMOUNT
FROM	dbo.INCASSO(NOLOCK)
WHERE	REC_ID = @rec_id

SET @dept_no = dbo.acc_get_dept_no(@debit_id)

EXEC dbo.GET_SETTING_STR 'ACC_INCASSO_TEMPLATE', @acc_template OUTPUT

EXEC @r = dbo.GET_NEXT_ACC_NUM_NEW
		@bal_acc = @bal_acc_alt,
		@branch_id = @dept_no,
		@client_no = @client_no,
		@iso = 'GEL', 
		@template = @acc_template,
		@acc = @account OUTPUT,
		@user_id = @user_id,
		@return_row = 0
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÀÍÂÀÒÉÛÉÓ ÃÀÂÄÍÄÒÉÒÄÁÉÓÀÓ.',16,1) END RETURN 1 END

SELECT @debit_id = ACC_ID FROM dbo.ACCOUNTS(NOLOCK) WHERE ACCOUNT = @account AND ISO = 'GEL' AND DEPT_NO = @dept_no

IF ISNULL(@debit_id, 0) = 0
BEGIN
	EXEC  @r = dbo.ADD_ACCOUNT @debit_id OUTPUT, @user_id=@user_id, @dept_no=@dept_no, @account=@account, @iso='GEL', @bal_acc_alt=@bal_acc_alt,
		@act_pas=2,	@client_no=@client_no
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ.',16,1) END RETURN 2 END
END

UPDATE INCASSO
SET REC_STATE = 1
WHERE REC_ID = @rec_id

IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ',16,1) END RETURN 3 END

SELECT TOP 1 @credit_id = ACC_ID FROM dbo.ACCOUNTS(NOLOCK) WHERE ACCOUNT = '1' AND ISO = 'GEL' AND DEPT_NO = @dept_no

EXEC @r=dbo.ADD_DOC4 @rec_id=@rec_id OUTPUT,@user_id=@user_id,@doc_date=@doc_date,@iso='GEL',@amount=@amount,@op_code='INCAS',@debit_id=@debit_id,
	@credit_id=@credit_id,@rec_state=0,@descrip='ÉÍÊÀÓÏÓ ÀÚÅÀÍÀ ÂÀÒÄÁÀËÀÍÓÖÒÆÄ',@owner=@user_id,@doc_type=200,@channel_id=0,@dept_no=@dept_no,@check_saldo=-1
IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÓÀÁÖÈÉÓ ÂÀÔÀÒÄÁÉÓÀÓ.',16,1) END RETURN 4 END

RETURN 0
GO
