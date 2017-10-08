SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DEAUTHORIZE_INCASSO]
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
	@pending bit,
	@acc_id_ofb int,
	@extra_rec_id int,
	@old_state tinyint

IF NOT EXISTS(SELECT * FROM dbo.INCASSO_OPS(NOLOCK) WHERE REC_ID = @rec_id)
	BEGIN RAISERROR ('ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÀ ÀÒ ÌÏÉÞÄÁÍÀ.',16,1) RETURN 1 END

SELECT 
	@incasso_id = INCASSO_ID, 
	@old_state = OLD_REC_STATE,
	@op_type = OP_TYPE,
	@doc_date = DATE_TIME,
	@rec_state = REC_STATE,
	@amount = AMOUNT,
	@extra_rec_id = EXTRA_REC_ID
FROM dbo.INCASSO_OPS (NOLOCK)
WHERE REC_ID = @rec_id

SELECT @r = MAX(REC_ID)
FROM dbo.INCASSO_OPS (NOLOCK)
WHERE INCASSO_ID = @incasso_id

IF @r <> @rec_id
	BEGIN RAISERROR ('ÉÍÊÀÓÏÓ ÀÌ ÏÐÄÒÀÝÉÀÆÄ ÀÅÔÏÒÉÆÀÝÉÉÓ ÌÏáÍÀ ÀÒ ÛÄÉÞËÄÁÀ.',16,1) RETURN 2 END

SELECT	@acc_id_ofb = ACC_ID_OFB, @pending = PENDING
FROM	dbo.INCASSO (NOLOCK)
WHERE	REC_ID = @incasso_id

IF @pending = 1
	BEGIN RAISERROR ('ÀÌ ÉÍÊÀÓÏÆÄ ÏÐÄÒÀÝÉÉÓ ÜÀÔÀÒÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ. ÀÒ ÀØÅÓ ÛÄÓÀÁÀÌÉÓÉ ÓÔÀÔÖÓÉ.',16,1) RETURN 3 END

BEGIN TRAN

UPDATE dbo.INCASSO_OPS
SET	REC_STATE = 0
WHERE REC_ID = @rec_id
IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÉÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 6 END

DECLARE @new_balance money

IF @op_type = 0 --ინკასოს თანხის გადახდა
BEGIN
	UPDATE	dbo.INCASSO
	SET		REC_STATE = @old_state,
			PENDING = 0,
			@new_balance = BALANCE = BALANCE + @amount,
			PAYED_AMOUNT = PAYED_AMOUNT - @amount,
			PAYED_COUNT = PAYED_COUNT - 1
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 9 END

	EXEC @r = dbo.DELETE_INCASSO_OPS @user_id=@user_id, @incasso_op_id=@rec_id
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÀÁÖÈÄÁÉÓ ßÀÛËÉÓÀÓ.',16,1) END RETURN 7 END

	IF @new_balance - @amount <= $0.00
	BEGIN
		EXEC dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 1
		IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 8 END
	END
END
ELSE
IF @op_type = 1 --ინკასო ახალი გახსნილია
BEGIN
	UPDATE	dbo.INCASSO
	SET		BALANCE = $0,
			REC_STATE = 0,
			PENDING = 1
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÍÀÛÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 9 END

	EXEC @r = dbo.DELETE_INCASSO_OPS @user_id=@user_id, @incasso_op_id=@rec_id
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÀÁÖÈÄÁÉÓ ßÀÛËÉÓÀÓ.',16,1) END RETURN 7 END
END
ELSE
IF @op_type = 2 --ინკასოს შეჩერება
BEGIN
	UPDATE	dbo.INCASSO
	SET		PENDING = 1,
			REC_STATE = @old_state,
			@new_balance = BALANCE = BALANCE + @amount,
			SUSPENDED_AMOUNT = SUSPENDED_AMOUNT - @amount
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 9 END

	EXEC dbo.INCASSO_ACCOUNTS_SET_FLAG @rec_id, @user_id, 1
	IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 8 END

	IF @new_balance - @amount <= $0.00
	BEGIN
		EXEC dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 1
		IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 8 END
	END
END
ELSE
--IF @op_type = 3 --
--BEGIN
--	UPDATE	dbo.INCASSO
--	SET		PENDING = 1,
--			REC_STATE = @old_state,
--			@new_balance = BALANCE = BALANCE + @amount,
--			SUSPENDED_AMOUNT = SUSPENDED_AMOUNT - @amount
--	WHERE	REC_ID = @incasso_id
--	IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÍÀÛÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 9 END
--
--	IF @new_balance - @amount <= $0.00
--	BEGIN
--		EXEC dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 1
--		IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 8 END
--	END
--END
--ELSE
IF @op_type = 4 --ინკასოს გაწვევა
BEGIN
	EXEC dbo.INCASSO_ACCOUNTS_SET_FLAG @rec_id, @user_id, 1
	IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 8 END

	UPDATE	dbo.INCASSO
	SET		BALANCE = BALANCE + @amount,
			REC_STATE = @extra_rec_id,
			PENDING = 1
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÍÀÛÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 9 END

	IF @amount > $0.00
	BEGIN
		EXEC @r = dbo.DELETE_INCASSO_OPS @user_id=@user_id, @incasso_op_id=@rec_id
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÀÁÖÈÄÁÉÓ ßÀÛËÉÓÀÓ.',16,1) END RETURN 7 END

		EXEC dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 1
		IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 8 END
	END
END
ELSE
IF @op_type = 5 --ინკასოს აღდგენა
BEGIN
	UPDATE	dbo.INCASSO
	SET		PENDING = 1,
			REC_STATE = @old_state,
			SUSPENDED_AMOUNT = SUSPENDED_AMOUNT + @amount,
			@new_balance = BALANCE = BALANCE - @amount
	WHERE	REC_ID = @incasso_id
	IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÍÀÛÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 9 END

	IF @new_balance <= $0.0 -- Old balance
	BEGIN
		EXEC dbo.INCASSO_ACCOUNTS_SET_FLAG @incasso_id, @user_id, 0
		IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÄÁÆÄ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN 8 END
	END
END

COMMIT TRAN

RETURN 0
GO
