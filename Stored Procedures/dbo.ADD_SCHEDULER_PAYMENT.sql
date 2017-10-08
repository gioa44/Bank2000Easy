SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ADD_SCHEDULER_PAYMENT]
	@rec_id int,
	@user_id int, /* who is adding the document */
	@channel_id int = 2,
	@lat bit = 0

AS

SET NOCOUNT ON

DECLARE 
	@r int,
	@provider_id int,
	@service_alias varchar(20),
	@id_in_provider varchar(50),
	@id2_in_provider varchar(50),
	@debt money,

	@acc_id int,
	
	@sender_acc_name varchar(100),
	@dept_no int,
	@full_amount money,
	@tariff_amount money,
	@usable_amount money,
	@use_overdraft smallint,
	@product_tariff int,
	@pay_part bit,
	@descrip varchar(100),
	@ccy char(3),
	@internal_transaction bit

SELECT @dept_no = DEPT_NO 
FROM dbo.USERS
WHERE [USER_ID] = @user_id

SELECT	@provider_id=PROVIDER_ID, @service_alias=SERVICE_ALIAS, @acc_id=ACC_ID, @id_in_provider=ID_IN_PROVIDER, 
		@id2_in_provider=ID2_IN_PROVIDER, @debt=AMOUNT, @pay_part=PAY_PART, @descrip=DESCRIP, @ccy=CCY
FROM	dbo.PAYMENTS_SCHEDULER_TMP
WHERE	REC_ID = @rec_id

SELECT	@sender_acc_name = DESCRIP
FROM	dbo.ACCOUNTS (NOLOCK)
WHERE	ACC_ID = @acc_id

IF @@ROWCOUNT = 0
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉ(ÂÒÀ×ÉÊÉÈ ÂÀÃÀáÃÀ) ÂÀÌÂÆÀÅÍÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ',16,1)
	RETURN 100
END

IF @ccy <> 'GEL'
	SET @debt = dbo.get_equ(@debt, @ccy, GETDATE())

SET @tariff_amount = dbo.payments_get_tariff(@provider_id, @service_alias, @channel_id, @debt, 0)
SET @full_amount = @debt + @tariff_amount

EXEC @r=dbo.acc_get_usable_amount @acc_id=@acc_id, @usable_amount=@usable_amount OUTPUT, @use_overdraft=1

IF @full_amount > @usable_amount
	SET @use_overdraft = 1
ELSE
	SET @use_overdraft = 0

IF @use_overdraft=1 AND @pay_part=0
	RETURN 101

IF @use_overdraft=1 AND @pay_part=1
BEGIN
	SET @full_amount = @usable_amount
	--EXEC @r=dbo.acc_get_usable_amount @acc_id=@acc_id, @usable_amount=@full_amount OUTPUT, @use_overdraft=0
	IF @full_amount < $1.00
		RETURN 102
	SET @tariff_amount = dbo.payments_get_tariff(@provider_id, @service_alias, @channel_id, @full_amount, 1)
END

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

IF @use_overdraft=1 AND @pay_part=1
BEGIN
	UPDATE	dbo.PAYMENTS_SCHEDULER_TMP
	SET		AMOUNT = AMOUNT - (@full_amount - @tariff_amount)
	WHERE	REC_ID = @rec_id
END
ELSE
	DELETE	dbo.PAYMENTS_SCHEDULER_TMP
	WHERE	REC_ID = @rec_id

IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

EXEC @r=dbo.ADD_UTILITY_PAYMENT @rec_id output, @user_id=@user_id, @provider_id=@provider_id,
			@service_alias=@service_alias, @id_in_provider=@id_in_provider, @id2_in_provider=@id2_in_provider,
			@full_amount=@full_amount, @tariff_amount=@tariff_amount,
			@sender_acc_id=@acc_id,@dept_no=@dept_no,
			@lat=@lat, @channel_id=@channel_id,@descrip_scheduler = @descrip

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN @r END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN 0
GO
