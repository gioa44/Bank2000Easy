SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[sys_get_date_str] (@dt smalldatetime)
RETURNS varchar(8)
AS
BEGIN
	DECLARE @s varchar(8)

	SET @s = CONVERT(varchar(4), YEAR(@dt))
	IF MONTH(@dt) <= 9
		SET @s = @s + '0'
	SET @s = @s + CONVERT(varchar(2), MONTH(@dt))
	IF DAY(@dt) <= 9
		SET @s = @s + '0'
	SET @s = @s + CONVERT(varchar(2), DAY(@dt))
	RETURN @s
END
GO
