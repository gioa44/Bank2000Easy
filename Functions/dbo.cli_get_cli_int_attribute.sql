SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[cli_get_cli_int_attribute] (@client_id int, @attrib_code varchar(50)) 
RETURNS int
AS
BEGIN

  RETURN (SELECT CONVERT(int, ATTRIB_VALUE) FROM dbo.CLIENT_ATTRIBUTES (NOLOCK) WHERE CLIENT_NO = @client_id AND ATTRIB_CODE = @attrib_code)
END
GO
