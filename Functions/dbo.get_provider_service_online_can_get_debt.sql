SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[get_provider_service_online_can_get_debt] (@provider_id int, @service_alias varchar(20))
RETURNS bit
AS
BEGIN
	DECLARE
		@online_can_get_debt bit
	SELECT	@online_can_get_debt = ONLINE_CAN_GET_DEBT 
	FROM	dbo.PAYMENT_PROVIDER_SERVICES
	WHERE	PROVIDER_ID = @provider_id AND SERVICE_ALIAS = @service_alias

  RETURN(@online_can_get_debt)
END
GO
