SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_SCHEDULER_PAYMENT_TEMP]
	@rec_id int OUTPUT,
	@user_id int, /* who is adding the document */

	@provider_id int,
	@service_alias varchar(20),
	@channel_id int = 2,
	@id_in_provider varchar(50) = '',
	@id2_in_provider varchar(50) = '',
	@debt money = 0.0,

	@sender_acc_id int = NULL,
	@descrip varchar(100),
	@ccy char(3),
	@pay_part bit = 0,
	@priority_order int = 0,
	@is_online_debt bit = 0,
	@lat bit = 0

AS

SET NOCOUNT ON

DECLARE 
	@r int,
	@sender_acc_name varchar(100),
	@dept_no int,
	@old_dept money,
	@tariff_amount money,
	@product_tariff int,
	@internal_transaction bit


SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

IF EXISTS(SELECT * FROM dbo.PAYMENTS_SCHEDULER_TMP(NOLOCK) 
			WHERE PROVIDER_ID = @provider_id AND SERVICE_ALIAS = @service_alias AND ID_IN_PROVIDER = @id_in_provider
			AND ACC_ID = @sender_acc_id)
BEGIN
	SELECT	@rec_id = REC_ID, @old_dept = AMOUNT
	FROM	dbo.PAYMENTS_SCHEDULER_TMP(NOLOCK) 
	WHERE	PROVIDER_ID = @provider_id AND SERVICE_ALIAS = @service_alias AND ID_IN_PROVIDER = @id_in_provider
			AND ACC_ID = @sender_acc_id

	IF @is_online_debt = 0
		SET @debt = @debt + @old_dept

	UPDATE	dbo.PAYMENTS_SCHEDULER_TMP
	SET		AMOUNT = @debt
	WHERE	REC_ID = @rec_id

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

END
ELSE
BEGIN
	INSERT INTO dbo.PAYMENTS_SCHEDULER_TMP(PROVIDER_ID,SERVICE_ALIAS,ACC_ID,ID_IN_PROVIDER,ID2_IN_PROVIDER,AMOUNT,PAY_PART,PRIORITY_ORDER,DESCRIP,CCY)
			VALUES(@provider_id,@service_alias,@sender_acc_id,@id_in_provider,@id2_in_provider,@debt,@pay_part,@priority_order,@descrip,@ccy)

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

	SET @rec_id = SCOPE_IDENTITY()
END

IF @rec_id > 0
	UPDATE	dbo.PAYMENTS_SCHEDULER
	SET		LAST_PAY_DATE = convert(smalldatetime,floor(convert(real,getdate())))
	WHERE	PROVIDER_ID = @provider_id AND SERVICE_ALIAS = @service_alias AND ID_IN_PROVIDER = @id_in_provider
			AND ACC_ID = @sender_acc_id

IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN (0)
GO
