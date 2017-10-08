SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [impexp].[date_to_char6] (@date smalldatetime)
RETURNS char(6)
AS
BEGIN
	DECLARE @s6 char(6)
	SET @s6 = STR(DAY(@date),2) + STR(MONTH(@date),2) + STR(YEAR(@date) % 100,2)
	SET @s6 = REPLACE(@s6, ' ', '0')
	RETURN @s6
END
GO
