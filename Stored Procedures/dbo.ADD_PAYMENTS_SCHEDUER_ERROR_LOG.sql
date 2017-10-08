SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_PAYMENTS_SCHEDUER_ERROR_LOG]
	@rec_id int OUTPUT,
	@provider_id int = 0,
	@service_alias varchar(20) = '',
	@id_in_provider varchar(50) = '',
	@id2_in_provider varchar(50) = null,
	@acc_id int,
	@amount money

AS

SET NOCOUNT ON

	INSERT INTO dbo.PAYMENT_SCHEDUER_ERROR_LOG(PROVIDER_ID,SERVICE_ALIAS,ID_IN_PROVIDER,ID2_IN_PROVIDER,ACC_ID,AMOUNT)
	VALUES(@provider_id,@service_alias,@id_in_provider,@id2_in_provider,@acc_id,@amount)

	SET @rec_id = SCOPE_IDENTITY()

	RETURN 0

RETURN 0
GO
