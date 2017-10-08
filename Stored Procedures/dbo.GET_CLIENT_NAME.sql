SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [dbo].[GET_CLIENT_NAME]
	@client_no 	int,
	@client_name 	varchar(100) OUTPUT,
	@client_name_lat varchar(100) OUTPUT
AS

SET NOCOUNT ON

SELECT @client_name = DESCRIP, @client_name_lat = DESCRIP_LAT
FROM CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no






GO
