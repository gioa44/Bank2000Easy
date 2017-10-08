SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GET_SETTING_STR]
	@param_name varchar(20),
	@str_val varchar(255) OUTPUT
AS

SET NOCOUNT ON;

SET @str_val = NULL

SELECT @str_val = VALS
FROM dbo.INI_STR (NOLOCK) 
WHERE IDS = @param_name

SET @str_val = ISNULL(@str_val, '')

RETURN (0)
GO
