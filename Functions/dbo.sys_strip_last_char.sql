SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[sys_strip_last_char] (@msg varchar(8000), @char char(1))
RETURNS varchar(8000)
AS
BEGIN
	IF RIGHT(@msg, 1) = @char
		SET @msg = SUBSTRING(@msg, 1, LEN(@msg) - 1)
	
	RETURN @msg
END
GO
