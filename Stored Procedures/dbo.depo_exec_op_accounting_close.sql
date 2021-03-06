SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_exec_op_accounting_close]
	@doc_rec_id int OUTPUT,
	@user_id int,
	@did int,
	@oid int,
	@acc_id int,
	@dno varchar(50),
	@dt smalldatetime,
	@op_type int,
	@amount money,
	@iso TISO,
	@client_no int,
	@dept_no int
AS

SET NOCOUNT ON

DECLARE @r int
    
DECLARE
    @_is_cash bit,
    @credit_id int,
    @debit_id int,
    @descrip varchar(150),
	@blocked_amount money,
	@rec_state tinyint

DECLARE
    @first_name varchar(50),
    @last_name varchar(50), 
    @fathers_name varchar(50), 
    @birth_date smalldatetime, 
    @birth_place varchar(100), 
    @address_jur varchar(100), 
    @address_lat varchar(100),
    @country varchar(2), 
    @passport_type_id tinyint, 
    @passport varchar(50), 
    @personal_id varchar(20),
    @reg_organ varchar(50),
    @passport_issue_dt smalldatetime,
    @passport_end_date smalldatetime

DECLARE
	@rec_id int

DECLARE
	@doc_type smallint
	

SELECT @blocked_amount = ISNULL(BLOCKED_AMOUNT, $0.00), @rec_state = REC_STATE
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

IF @blocked_amount <> $0.00
BEGIN
	SET @doc_rec_id = 0

	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET END_DATE = @dt
	WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 RETURN(1)

	IF @rec_state = 4
	BEGIN
		UPDATE dbo.ACCOUNTS
		SET REC_STATE = 1
		WHERE ACC_ID = @acc_id
	    IF @@ERROR<>0 RETURN(1)

		INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP)
		VALUES (@acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : REC_STATE (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ)')
		IF @@ERROR<>0 RETURN(1)

		SET @rec_id = SCOPE_IDENTITY()
	
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @acc_id
		IF @@ERROR<>0 RETURN(1)
	END
	RETURN 0
END


SELECT @_is_cash = CASE WHEN ACC_TYPE & 0x02 = 0x02 THEN 1 ELSE 0 END
FROM dbo.ACCOUNTS 
WHERE ACC_ID = @credit_id

IF @_is_cash <> 0
	SELECT @first_name = FIRST_NAME, @last_name = LAST_NAME, @fathers_name = FATHERS_NAME, 
		@birth_date = BIRTH_DATE, @birth_place = BIRTH_PLACE, 
		@country = COUNTRY, @passport_type_id = PASSPORT_TYPE_ID, 
		@passport = PASSPORT, @personal_id = PERSONAL_ID, @reg_organ = REG_ORGAN,
		@passport_issue_dt = PASSPORT_ISSUE_DT, @passport_end_date = PASSPORT_END_DATE
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @client_no

SET @descrip = 'ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÅÀÃÉÓ ÂÀÓÅËÀ ('+ @dno + ')'

SELECT @debit_id = ACC_ID FROM dbo.DEPOS WHERE DEPO_ID = @did
SELECT @credit_id = EXT_ACC_ID FROM dbo.DEPO_OPS WHERE OP_ID = @oid

SET @amount = - dbo.acc_get_balance(@debit_id, @dt, 0, 0, 1)  

IF @_is_cash=1
BEGIN
	DECLARE @op_code varchar(5)
	SET @op_code = CASE @iso WHEN 'GEL' THEN '44' ELSE '62' END 

	EXEC @r = dbo.ADD_DOC4 @doc_rec_id OUTPUT, @user_id=@user_id, @doc_type=130, 
		@doc_date=@dt, @debit_id=@debit_id, @credit_id=@credit_id, @iso=@iso, 
		@amount=@amount, @descrip=@descrip, @op_code=@op_code,
		@first_name=@first_name,
		@last_name=@last_name,
		@fathers_name=@fathers_name,
		@birth_date=@birth_date,
		@birth_place=@birth_place,
		@address_jur=@address_jur,
		@address_lat=@address_lat,
		@country=@country,
		@passport_type_id=@passport_type_id,
		@passport=@passport,
		@personal_id=@personal_id,
		@reg_organ=@reg_organ,
		@passport_issue_dt=@passport_issue_dt,
		@passport_end_date=@passport_end_date,
		@account_extra=@acc_id,
		@channel_id=800,
		@rec_state = 20
	IF @@ERROR<>0 OR @r<>0 BEGIN SET @doc_rec_id = 0 RETURN(1) END
END
ELSE
BEGIN
	/*EXEC @r = dbo.ADD_DOC4 @doc_rec_id OUTPUT, @user_id=@user_id, @doc_type=98, 
		 @doc_date=@dt, @debit_id=@debit_id, @credit_id=@credit_id, @iso=@iso, 
		 @amount=@amount, @descrip = @descrip, @op_code= '*DCA*', 
		 @account_extra=@acc_id, @channel_id=800, @rec_state = 20*/

	DECLARE
		@sender_bank_code varchar(37),
		@sender_bank_name varchar(105),
		@sender_acc varchar(37),
		@sender_acc_name varchar(105),
		@sender_tax_code varchar(11),

		@receiver_bank_code varchar(37),
		@receiver_bank_name varchar(105),
		@receiver_acc varchar(37),
		@receiver_acc_name varchar(105),
		@receiver_tax_code varchar(11)

	SET @sender_bank_code = dbo.acc_get_bank_code(@debit_id)
	SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
	SET @sender_acc_name = dbo.acc_get_name(@debit_id)

	SET @sender_acc = dbo.acc_get_account(@debit_id)
	SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
	
	SET @receiver_bank_code = dbo.acc_get_bank_code(@credit_id)
	SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
	SET @receiver_acc_name = dbo.acc_get_name(@credit_id)
	SET @receiver_acc = dbo.acc_get_account(@credit_id)
	SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
	
	SET @op_code = '*DCA*'
	SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END

	EXEC @r = dbo.ADD_DOC4
		@rec_id = @doc_rec_id OUTPUT,
		@user_id = @user_id,
		@doc_type = @doc_type,
		@doc_date = @dt,
		@debit_id = @debit_id,
		@credit_id = @credit_id,
		@iso = @iso,
		@amount = @amount,
		@rec_state = 10,
		@descrip = @descrip,
		@op_code = @op_code,
		@account_extra = @acc_id,
		@dept_no = @dept_no,
		@channel_id = 800,
		@flags = 0x15F4,

		@sender_bank_code = @sender_bank_code,
		@sender_acc = @sender_acc,
		@sender_tax_code = @sender_tax_code,
		@receiver_bank_code = @receiver_bank_code,
		@receiver_acc = @receiver_acc,
		@receiver_tax_code = @receiver_tax_code,
		@sender_bank_name = @sender_bank_name,
		@receiver_bank_name = @receiver_bank_name,
		@sender_acc_name = @sender_acc_name,
		@receiver_acc_name = @receiver_acc_name

	IF @@ERROR<>0 OR @r<>0 BEGIN SET @doc_rec_id = 0 RETURN(1) END
END

UPDATE dbo.ACCOUNTS_CRED_PERC
SET END_DATE = @dt
WHERE ACC_ID = @acc_id
IF @@ERROR<>0 BEGIN SET @doc_rec_id = 0 RETURN(1) END

UPDATE dbo.ACCOUNTS
SET REC_STATE = 2, DATE_CLOSE = @dt
WHERE ACC_ID = @acc_id
IF @@ERROR<>0 BEGIN SET @doc_rec_id = 0 RETURN(1) END

INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP)
VALUES (@acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : REC_STATE DATE_CLOSE (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ)')
IF @@ERROR<>0 BEGIN SET @doc_rec_id = 0 RETURN(1) END
	
SET @rec_id = SCOPE_IDENTITY()
	
INSERT INTO dbo.ACCOUNTS_ARC
SELECT @rec_id, *
FROM dbo.ACCOUNTS
WHERE ACC_ID = @acc_id
IF @@ERROR<>0 BEGIN SET @doc_rec_id = 0 RETURN(1) END

RETURN(0)
GO
