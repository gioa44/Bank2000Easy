SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [export].[get_client_type3](@client_id int)
RETURNS tinyint
AS
BEGIN

DECLARE	
	@client_type tinyint,
	@client_subtype int

	SELECT @client_type = CLIENT_TYPE, @client_subtype = CLIENT_SUBTYPE 
	FROM dbo.CLIENTS WHERE CLIENT_NO = @client_id	

	IF @client_type <> 1
		SET @client_type = 4 -- ÐÉÒÏÁÉÈÀÃ ÀÙÅÍÉÛÍÏÈ ÉÖÒÉÃÉÖËÉ ÐÉÒÉ

	RETURN @client_type
END
GO
