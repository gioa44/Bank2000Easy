SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













CREATE PROCEDURE [dbo].[AUTHORIZE_INCASSO]
	@rec_id int,
	@user_id int
AS
SET NOCOUNT ON

DECLARE
	@r int,
	@incasso_id int,
	@op_type smallint,
	@doc_date smalldatetime,
	@rec_state smallint,
	@amount money,
	@bank_tech_account_id int,
	@pending bit,
	@dept_no int,
	@acc_id_ofb int,
	@doc_rec_id int

IF NOT EXISTS(SELECT * FROM dbo.INCASSO_OPS(NOLOCK) WHERE REC_ID = @rec_id)
	BEGIN RAISERROR ('ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÀ ÀÒ ÌÏÉÞÄÁÍÀ.',16,1) RETURN 1 END

SELECT	
	@incasso_id = INCASSO_ID, 
	@op_type = OP_TYPE, 
	@doc_date = convert(smalldatetime,floor(convert(real,DATE_TIME))), 
	@rec_state = REC_STATE, 
	@amount = AMOUNT 
FROM dbo.INCASSO_OPS (NOLOCK)
WHERE REC_ID = @rec_id

IF NOT EXISTS(SELECT * FROM dbo.INCASSO(NOLOCK) WHERE REC_ID = @incasso_id)
	BEGIN RAISERROR ('ÉÍÊÀÓÏ ÀÒ ÌÏÉÞÄÁÍÀ.',16,1) RETURN 2 END


DECLARE
	@descrip varchar(150),
	@incasso_num varchar(20),
	@issue_date smalldatetime,
	@suspended_amount money,
	@old_state tinyint,
	@tr_amount money

SELECT 
	@old_state = REC_STATE,
	@acc_id_ofb = ACC_ID_OFB, 
	@pending = PENDING, 
	@incasso_num = INCASSO_NUM, 
	@issue_date = ISSUE_DATE, 
	@suspended_amount = ISNULL(SUSPENDED_AMOUNT, $0.00),
	@tr_amount = ISNULL(BALANCE, $0.00) + ISNULL(SUSPENDED_AMOUNT, $0.00)
FROM dbo.INCASSO (NOLOCK)
WHERE REC_ID = @incasso_id

IF @pending = 0
BEGIN 
	RAISERROR ('ÀÌ ÉÍÊÀÓÏÆÄ ÏÐÄÒÀÝÉÉÓ ÜÀÔÀÒÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ. ÀÒ ÀØÅÓ ÛÄÓÀÁÀÌÉÓÉ ÓÔÀÔÖÓÉ.',16,1) 
	RETURN 3 
END

SET @dept_no = dbo.acc_get_dept_no(@acc_id_ofb)
IF @dept_no IS NULL
BEGIN 
	RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÛÄÓÀÁÀÌÉÓÉ ÂÀÍÚÏ×ÉËÄÁÀ(×ÉËÉÀËÉ) ÀÒ ÌÏÉÞÄÁÍÀ',16,1) 
	RETURN 4 
END

DECLARE
	@inc_tech_branch_id int,
	@inc_tech_acc TACCOUNT

--EXEC dbo.GET_SETTING_ACC 'INC_TECH_ACC', @inc_tech_acc OUTPUT
SELECT @inc_tech_acc = CONVERT(decimal(15,0), VALS)
FROM dbo.INI_INT (NOLOCK)
WHERE IDS = 'INC_TECH_ACC'

--EXEC dbo.GET_SETTING_INT 'INC_TECH_ACC_BRANCH', @inc_tech_branch_id OUTPUT
SELECT @inc_tech_branch_id = CONVERT(int, VALS)
FROM dbo.INI_INT (NOLOCK)
WHERE IDS = 'INC_TECH_ACC_BRANCH'

IF @inc_tech_acc IS NULL
	SET @inc_tech_acc = 0
IF @inc_tech_branch_id IS NULL
	SET @inc_tech_branch_id = dbo.dept_branch_id(@dept_no)

SET @bank_tech_account_id = dbo.acc_get_acc_id(@inc_tech_branch_id, @inc_tech_acc,'GEL')

IF @bank_tech_account_id IS NULL
BEGIN 
	RAISERROR ('ÂÀÍÚÏ×ÉËÄÁÉÓ(×ÉËÉÀËÉÓ) ÔÄØÍÉÊÖÒÉ ÀÍÂÀÒÉÛÉ ÂÀÒÄÁÀËÀÍÓÉÓÀÈÅÉÓ ÀÒ ÌÏÉÞÄÁÍÀ',16,1)
	RETURN 5 
END

SET @descrip = ', ÉÍÊÀÓÏ # ' + @incasso_num + ', ' + CONVERT(varchar(10), @issue_date, 103)

BEGIN TRAN

UPDATE dbo.INCASSO_OPS
SET	REC_STATE = 1, OLD_REC_STATE = @old_state
WHERE REC_ID = @rec_id
IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÉÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 6; END

DECLARE @new_balance money

IF @op_type = 0 --ინკასოს თანხის გადახდა
BEGIN
	DECLARE @payed_count smallint

	UPDATE	dbo.INCASSO
	SET		PENDING = 0,
			@new_balance = BALANCE = BALANCE - @amount,
			REC_STATE = CASE WHEN @new_balance + @suspended_amount <= $0.00 THEN 9 WHEN @new_balance <= 0 AND @suspended_amount > $0.00 THEN 2 ELSE REC_STATE END,
			PAYED_AMOUNT = PAYED_AMOUNT + @amount,
			@payed_count = PAYED_COUNT = ISNULL(PAYED_COUNT, 0) + 1
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 9; END

	SET @descrip = 'ÉÍÊÀÓÏÓ ÂÀÍÀÙÃÄÁÀ' + @descrip + ', ÒÉÂÉÈÉ # ' + CONVERT(varchar(10), @payed_count) +
		', ÂÀÍÀÙÃÄÁÖËÉ ÈÀÍáÀ: ' + CONVERT(varchar(20), @amount) + ', ÃÀÒÜÄÍÉËÉ ÍÀÛÈÉ: ' + CONVERT(varchar(15), @new_balance)

	EXEC @r = dbo.ADD_DOC4 @rec_id=@doc_rec_id OUTPUT,@user_id=@user_id,@doc_date=@doc_date,@doc_date_in_doc=@issue_date,@iso='GEL',@amount=@amount,@op_code='*INK',
		@debit_id=@bank_tech_account_id,@credit_id=@acc_id_ofb,@rec_state=20,@descrip=@descrip,@owner=@user_id,@doc_type=200,@channel_id=0,@dept_no=@dept_no,
		@foreign_id=@rec_id,@check_saldo=0,@add_tariff=0,@flags=6 
	IF @@ERROR<>0 OR @r<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÓÀÁÖÈÉÓ ÂÀÔÀÒÄÁÉÓÀÓ.',16,1); RETURN 10; END	

	INSERT INTO dbo.INCASSO_OPS_ID(INCASSO_OP_ID, DOC_REC_ID)
	VALUES (@rec_id, @doc_rec_id)
	IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÄÁÉÓ ID-ÄÁÉÓ ÜÀßÄÒÉÓÀÓ.',16,1); RETURN 99; END

	IF @new_balance <= $0.000
	BEGIN
		EXEC @r = dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 0
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 8; END
	END
END
ELSE
IF @op_type = 1 --ინკასო ახალი გახსნილია
BEGIN
	UPDATE	dbo.INCASSO
	SET		@new_balance = BALANCE = @amount,
			REC_STATE = 1,
			PENDING = 0
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÍÀÛÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 9; END
	
	SET @descrip = 'ÉÍÊÀÓÏÓ ÂÀáÓÍÀ' + @descrip

	EXEC @r = dbo.ADD_DOC4 @rec_id=@doc_rec_id OUTPUT,@user_id=@user_id,@doc_date=@doc_date,@doc_date_in_doc=@issue_date,@iso='GEL',@amount=@amount,@op_code='*INK',
		@debit_id=@acc_id_ofb,@credit_id=@bank_tech_account_id,@rec_state=20,@descrip=@descrip,@owner=@user_id,@doc_type=200,@channel_id=0,@dept_no=@dept_no,
		@foreign_id=@rec_id,@check_saldo=0,@add_tariff=0,@flags=6
	IF @@ERROR<>0 OR @r<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÓÀÁÖÈÉÓ ÂÀÔÀÒÄÁÉÓÀÓ.',16,1); RETURN 10; END	

	INSERT INTO dbo.INCASSO_OPS_ID(INCASSO_OP_ID, DOC_REC_ID)
	VALUES (@rec_id, @doc_rec_id)
	IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÄÁÉÓ ID-ÄÁÉÓ ÜÀßÄÒÉÓÀÓ.',16,1); RETURN 99; END
END
ELSE
IF @op_type = 2 --ინკასოს შეჩერება
BEGIN
	UPDATE	dbo.INCASSO
	SET		@new_balance = BALANCE = BALANCE - @amount,
			REC_STATE = CASE WHEN @new_balance <= $0.00 THEN 2 ELSE REC_STATE END,
			PENDING = 0,
			SUSPENDED_AMOUNT = SUSPENDED_AMOUNT + @amount
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 9; END

	IF @new_balance <= $0.00
	BEGIN
		EXEC @r = dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 0
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 8; END
	END
END
ELSE
--IF @op_type = 3 --
--BEGIN
--	UPDATE	dbo.INCASSO
--	SET		@new_balance = BALANCE = BALANCE - @amount,
--			REC_STATE = CASE WHEN @new_balance <= $0.00 THEN 3 ELSE REC_STATE END,
--			PENDING = 0,
--			SUSPENDED_AMOUNT = SUSPENDED_AMOUNT + @amount
--	WHERE	REC_ID = @incasso_id
--	IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÍÀÛÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 9; END
--
--	IF @new_balance <= $0.00
--	BEGIN
--		EXEC @r = dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 0
--		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 8; END
--	END
--END
--ELSE
IF @op_type = 4 --ინკასოს გაწვევა
BEGIN
	UPDATE	dbo.INCASSO
	SET		@new_balance = BALANCE = BALANCE - @amount,
			REC_STATE = 9,
			PENDING = 0
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÍÀÛÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 9; END

	IF @new_balance > $0.00
	BEGIN
		RAISERROR('ÉÍÊÀÓÏÆÄ ÃÀÒÜÀ ÀØÔÉÖÒÉ ÍÀÛÈÉ. ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
		RETURN 1
	END

	IF @amount > $0.00
	BEGIN
		SET @descrip = 'ÉÍÊÀÓÏÓ ÃÀáÖÒÅÀ' + @descrip

		EXEC @r = dbo.ADD_DOC4 @rec_id=@doc_rec_id OUTPUT,@user_id=@user_id,@doc_date=@doc_date,@doc_date_in_doc=@issue_date,@iso='GEL',@amount=@tr_amount,@op_code='*INK',
			@debit_id=@bank_tech_account_id,@credit_id=@acc_id_ofb,@rec_state=20,@descrip=@descrip,@owner=@user_id,@doc_type=200,@channel_id=0,@dept_no=@dept_no,
			@foreign_id=@rec_id,@check_saldo=0,@add_tariff=0,@flags=6 
		IF @@ERROR<>0 OR @r<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÓÀÁÖÈÉÓ ÂÀÔÀÒÄÁÉÓÀÓ.',16,1); RETURN 7; END

		INSERT INTO dbo.INCASSO_OPS_ID(INCASSO_OP_ID, DOC_REC_ID)
		VALUES (@rec_id, @doc_rec_id)
		IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÄÁÉÓ ID-ÄÁÉÓ ÜÀßÄÒÉÓÀÓ.',16,1); RETURN 99; END
	END

	EXEC @r = dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 0
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 8; END
END
ELSE
IF @op_type = 5 --ინკასოს აღდგენა
BEGIN
	UPDATE	dbo.INCASSO
	SET		REC_STATE = 1,
			PENDING = 0,
			SUSPENDED_AMOUNT = SUSPENDED_AMOUNT - @amount,
			@new_balance = BALANCE = BALANCE + @amount
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÍÀÛÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 9; END

	IF @new_balance - @amount <= $0.0 -- Old balance
	BEGIN
		EXEC @r = dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 1
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1); RETURN 8; END
	END
END

COMMIT TRAN

RETURN 0
GO
