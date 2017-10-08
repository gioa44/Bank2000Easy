SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ADD_INCASSO]
	@rec_id int OUTPUT,
	@user_id int,
	@branch_id int,
	@client_no int,
	@incasso_num varchar(20),
	@issue_date smalldatetime,
	@rec_date_time smalldatetime,
	@activation_date_time smalldatetime,
	@rec_state int = 0,
	@acc_id int,
	@acc_id_ofb int = null,
	@incasso_amount money,
	@balance money = 0,
	@payed_amount money = 0,
	@suspended_amount money = 0,
	@payed_count smallint = 0,
	@receiver_bank_code TINTBANKCODE,
	@receiver_bank_name varchar(100),
	@receiver_acc TINTACCOUNT,
	@receiver_acc_name varchar(100),
	@receiver_tax_code varchar(11),
	@saxazkod varchar(9) = null,
	@descrip varchar(150),
	@incasso_issuer tinyint,
	@pending bit = 1,
	@iso TISO = 'GEL'
AS

SET NOCOUNT ON

DECLARE
	@r int,
	@incasso_ops_id int,
	@debit_id int,
	@credit_id int,
	@dept_no int,
	@acc_template varchar(20),
	@bal_acc_alt int,
	@account TACCOUNT,
	@branch_id2 int

SET @bal_acc_alt = 901

SET @branch_id2 = @branch_id

SELECT @branch_id = BRANCH_ID, @dept_no = DEPT_NO
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

BEGIN TRAN

IF ISNULL(@acc_id_ofb, 0) = 0
BEGIN
	EXEC dbo.GET_SETTING_STR 'ACC_INCASSO_TEMPLATE', @acc_template OUTPUT

	EXEC dbo.GET_SETTING_ACC 'AUTO_ACC_NUM_MIN_IC', @account OUTPUT
	EXEC @r = dbo.GET_NEXT_ACC_NUM_NEW
			@bal_acc = @bal_acc_alt,
			@branch_id = @branch_id,
			@dept_no = @dept_no,
			@client_no = @client_no,
			@iso = 'GEL', 
			@template = @acc_template,
			@acc = @account OUTPUT,
			@user_id = @user_id,
			@return_row = 0
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÀÍÂÀÒÉÛÉÓ ÃÀÂÄÍÄÒÉÒÄÁÉÓÀÓ.',16,1) END RETURN 1 END

	SELECT @acc_id_ofb = ACC_ID 
	FROM dbo.ACCOUNTS(NOLOCK) 
	WHERE BRANCH_ID = @branch_id AND ACCOUNT = @account AND ISO = 'GEL'

	IF ISNULL(@acc_id_ofb, 0) = 0
	BEGIN
		EXEC  @r = dbo.ADD_ACCOUNT @acc_id_ofb OUTPUT, @user_id=@user_id, @dept_no=@dept_no, @account=@account, @iso='GEL', @bal_acc_alt=@bal_acc_alt,
			@act_pas=2,	@client_no=@client_no, @is_incasso = 1
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ.',16,1) END RETURN 2 END
	END
END

INSERT INTO dbo.INCASSO(BRANCH_ID,CLIENT_NO,INCASSO_NUM,ISSUE_DATE,REC_DATE_TIME,ACTIVATION_DATE_TIME,REC_STATE,ACC_ID,ACC_ID_OFB,INCASSO_AMOUNT,BALANCE,PAYED_AMOUNT,PAYED_COUNT,RECEIVER_BANK_CODE,RECEIVER_BANK_NAME,RECEIVER_ACC,RECEIVER_ACC_NAME,RECEIVER_TAX_CODE,SAXAZKOD,DESCRIP,INCASSO_ISSUER,[USER_ID],PENDING,ISO)
VALUES(@branch_id2,@client_no,@incasso_num,@issue_date,@rec_date_time,@activation_date_time,@rec_state,@acc_id,@acc_id_ofb,@incasso_amount,@balance,@payed_amount,@payed_count,@receiver_bank_code,@receiver_bank_name,@receiver_acc,@receiver_acc_name,@receiver_tax_code,@saxazkod,@descrip,@incasso_issuer,@user_id,@pending,@iso)
IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) END RETURN 3 END

SET @rec_id = SCOPE_IDENTITY()

EXEC @r = dbo.ADD_INCASSO_OPS @rec_id = @incasso_ops_id OUTPUT, @user_id = @user_id, @incasso_id = @rec_id, 
	@op_type = 1, @amount = @incasso_amount, @doc_num = @incasso_num, @doc_date = @issue_date

IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) END RETURN 4 END

COMMIT TRAN

RETURN @@ERROR
GO
