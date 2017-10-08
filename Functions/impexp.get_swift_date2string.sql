SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [impexp].[get_swift_date2string](@dt smalldatetime)
RETURNS varchar(6)
AS
BEGIN
	DECLARE 
		@dt_str varchar(6),
		@m varchar(2),
		@d varchar(2)
	
	SET @dt_str = SUBSTRING(convert(varchar(4), DATEPART(year, @dt)), 3, 2)
	SET @m = convert(varchar(2), DATEPART(month, @dt))
	SET @d = convert(varchar(2), DATEPART(day, @dt))
	
	SET @dt_str = @dt_str + CASE WHEN LEN(@m) = 2 THEN @m ELSE '0' + @m END
	SET @dt_str = @dt_str + CASE WHEN LEN(@d) = 2 THEN @d ELSE '0' + @d END
	
	RETURN @dt_str
END
GO
