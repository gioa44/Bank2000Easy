SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[cli_get_cli_attribute] (@client_id int, @attrib_code varchar(50)) 
RETURNS varchar(1000)
AS
BEGIN

  RETURN (SELECT ATTRIB_VALUE FROM dbo.CLIENT_ATTRIBUTES (NOLOCK) WHERE CLIENT_NO = @client_id AND ATTRIB_CODE = @attrib_code)
END
GO
