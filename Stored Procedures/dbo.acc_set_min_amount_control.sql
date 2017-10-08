SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[acc_set_min_amount_control] (
	@user_id int,
	@acc_id int, 
	@date smalldatetime, 
	@new_amount money, 
	@new_check_date smalldatetime, 
	@comment varchar(255),
	@old_amount money OUTPUT,
	@old_check_date smalldatetime OUTPUT,
	@check_for_zero_amount bit = 0,
	@authorize bit = 1
)
AS

SET NOCOUNT ON;

DECLARE
	@old_amount_new money, 
	@old_check_date_new smalldatetime,
	@rec_id int,
	@r int

SELECT @old_amount = MIN_AMOUNT, @old_check_date = MIN_AMOUNT_CHECK_DATE, @old_amount_new = MIN_AMOUNT_NEW, @old_check_date_new = MIN_AMOUNT_CHECK_DATE_NEW
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

IF @old_amount IS NULL OR @old_amount_new IS NULL OR @old_amount <> @old_amount_new
BEGIN
	RAISERROR('<ERR>ÍÀÛÈÉÓ ÊÏÍÔÒÏËÉÓ ÈÀÍáÀ ÝÀÒÉÄËÉÀ ÀÍ ÀÒ ÀÒÉÓ ÀÅÔÏÒÉÆÄÁÖËÉ</ERR>', 16, 1)
	RETURN 2
END

IF ISNULL(@old_check_date, '19900101') <> ISNULL(@old_check_date_new, '19900101')
BEGIN
	RAISERROR('<ERR>ÍÀÛÈÉÓ ÊÏÍÔÒÏËÉÓ ÈÀÒÉÙÉ ÀÒ ÀÒÉÓ ÀÅÔÏÒÉÆÄÁÖËÉ</ERR>', 16, 1)
	RETURN 3
END

IF @check_for_zero_amount = 1 AND @old_amount <> $0.00
BEGIN
	RAISERROR('<ERR>ÍÀÛÈÉÓ ÊÏÍÔÒÏËÉÓ ÈÀÍáÀ ÀÒ ÖÃÒÉÓ ÍÏËÓ</ERR>', 16, 1)
	RETURN 4
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DELETE FROM dbo.ACCOUNTS_MIN_AMOUNTS
WHERE ACC_ID = @acc_id AND START_DATE >= @date
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END	

UPDATE dbo.ACCOUNTS_MIN_AMOUNTS 
SET END_DATE = @date
WHERE ACC_ID = @acc_id AND (END_DATE IS NULL OR END_DATE > @date)
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END	

IF ISNULL(@new_amount, $0.00) <> $0.00
BEGIN
	INSERT INTO dbo.ACCOUNTS_MIN_AMOUNTS
	VALUES (@acc_id, @date, @new_check_date, @new_check_date, @new_amount, @comment)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

INSERT INTO dbo.ACC_CHANGES(ACC_ID, [USER_ID], DESCRIP)
VALUES (@acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID MIN_AMOUNT MIN_AMOUNT_NEW MIN_AMOUNT_CHECK_DATE MIN_AMOUNT_CHECK_DATE_NEW')
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END	

SET @rec_id = SCOPE_IDENTITY()

INSERT INTO dbo.ACCOUNTS_ARC
SELECT @rec_id, *
FROM dbo.ACCOUNTS
WHERE ACC_ID = @acc_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END	

UPDATE dbo.ACCOUNTS
SET [UID] = [UID] + 1, 
	MIN_AMOUNT = CASE WHEN @authorize = 1 THEN @new_amount ELSE MIN_AMOUNT END,
	MIN_AMOUNT_NEW = @new_amount,
	MIN_AMOUNT_CHECK_DATE = CASE WHEN @authorize = 1 THEN @new_check_date ELSE MIN_AMOUNT_CHECK_DATE END,
	MIN_AMOUNT_CHECK_DATE_NEW = @new_check_date
WHERE ACC_ID = @acc_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END	

EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @acc_id, @user_id
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END	

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
