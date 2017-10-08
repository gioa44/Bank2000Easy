SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[get_binary_string](@number int, @digits tinyint = 32)
RETURNS varchar(32)
AS 
BEGIN
	DECLARE 
		@binary_string varchar(32),
		@n bigint

	SET @n = @number
	
	IF (@n < 0)
		SET @n = (@n & 0x7FFFFFFF) | 0x80000000

	SET @binary_string = ''
 
	WHILE @n <> 0
	BEGIN
		SET @binary_string = CAST(ABS(@n % 2) AS char(1)) + @binary_string
		SET @n = @n / 2
	END
	
	WHILE LEN(@binary_string) < @digits 
		SET @binary_string = '0' + @binary_string

RETURN @binary_string
END
GO
