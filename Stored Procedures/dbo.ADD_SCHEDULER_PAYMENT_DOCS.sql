SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_SCHEDULER_PAYMENT_DOCS]
	@user_id int, 
	@lat bit = 0
AS

SET NOCOUNT ON

DECLARE 
	@rec_id int,
	@provider_id int,
	@service_alias varchar(20),
	@channel_id int,
	@id_in_provider varchar(50),
	@id2_in_provider varchar(50),
	@amount money,
	@sender_acc_id int,
	@pay_part bit,
	@priority_order smallint,
	@sender_acc_name varchar(100),
	@dept_no int,
	@descrip varchar(100),
	@ccy char(3),
	@tariff_amount money,
	@usable_amount money,
	@product_tariff int,
	@r int,
	@internal_transaction bit

SET @channel_id = 2
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE cc CURSOR LOCAL FOR
SELECT REC_ID,PROVIDER_ID,SERVICE_ALIAS,ACC_ID,ID_IN_PROVIDER,ID2_IN_PROVIDER,AMOUNT,PAY_PART,DESCRIP,CCY
FROM	dbo.PAYMENTS_SCHEDULER_TMP (NOLOCK)
ORDER BY ACC_ID,PRIORITY_ORDER

OPEN cc
IF @@ERROR <> 0  GOTO RollBackThisTrans1

FETCH NEXT FROM cc INTO @rec_id,@provider_id,@service_alias,@sender_acc_id,@id_in_provider,@id2_in_provider,@amount,@pay_part,@descrip,@ccy
IF @@ERROR <> 0 GOTO RollBackThisTrans1

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @ccy <> 'GEL'
		SET @amount = dbo.get_equ(@amount, @ccy, GETDATE())

	SET @dept_no = dbo.acc_get_dept_no(@sender_acc_id)
	SET @tariff_amount = dbo.payments_get_tariff(@provider_id,@service_alias,@channel_id,@amount,0)
	EXEC dbo.acc_get_usable_amount @acc_id=@sender_acc_id, @usable_amount=@usable_amount OUT,@use_overdraft=0

	IF (@usable_amount > 0) AND (@usable_amount < @tariff_amount + @amount) AND (@pay_part = 1) OR (@usable_amount > @tariff_amount + @amount)
	BEGIN
		IF (@usable_amount < @tariff_amount + @amount) AND (@pay_part = 1)
		BEGIN
			SET @amount = @usable_amount
			SET @tariff_amount = dbo.payments_get_tariff(@provider_id,@service_alias,@channel_id,@amount,1)

			UPDATE	dbo.PAYMENTS_SCHEDULER_TMP
			SET		AMOUNT = @amount
			WHERE	REC_ID = @rec_id

		END
		ELSE
			DELETE	dbo.PAYMENTS_SCHEDULER_TMP
			WHERE	REC_ID = @rec_id
		SET @amount = @amount + @tariff_amount

		EXEC @r = dbo.ADD_UTILITY_PAYMENT @rec_id  OUTPUT,
			@user_id=@user_id,
			@provider_id=@provider_id,
			@service_alias=@service_alias,
			@id_in_provider=@id_in_provider,
			@id2_in_provider=@id2_in_provider,
			@channel_id=@channel_id,
			@full_amount=@amount,
			@tariff_amount=@tariff_amount,
			@dept_no=@dept_no,
			@sender_acc_id=@sender_acc_id,
			@descrip_scheduler = @descrip

		IF @r <> 0 GOTO RollBackThisTrans1
	END

	FETCH NEXT FROM cc INTO @rec_id,@provider_id,@service_alias,@sender_acc_id,@id_in_provider,@id2_in_provider,@amount,@pay_part,@descrip,@ccy
	IF @@ERROR <> 0 GOTO RollBackThisTrans1
END

CLOSE cc
DEALLOCATE cc

COMMIT TRAN

RETURN 0

RollBackThisTrans1:

CLOSE cc
DEALLOCATE cc

ROLLBACK
RETURN 1
GO
