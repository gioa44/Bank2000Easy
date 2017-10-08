SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[payments_channel_is_available](@service_alias varchar(20), @channel_id int)
RETURNS BIT
AS
BEGIN
DECLARE
	@channel_is_available bit

IF EXISTS(
SELECT	SERVICE_ID
FROM	dbo.PAYMENT_PROVIDER_SERVICES(NOLOCK)
WHERE	SERVICE_ALIAS = @service_alias AND SERVICE_ID IN 
(SELECT SERVICE_ID FROM dbo.PAYMENT_SERVICE_CHANNELS(NOLOCK) WHERE CHANNEL_ID = @channel_id))

	SET @channel_is_available = 1
ELSE
	SET @channel_is_available = 0

RETURN @channel_is_available
END
GO
