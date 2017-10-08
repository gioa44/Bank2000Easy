SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [impexp].[get_swift_string](@str varchar(max))
RETURNS varchar(max)
AS
BEGIN
	DECLARE 
		@s varchar(max),
		@len int,
		@i int,
		@c varchar(3)
	
	SET @len = LEN(@str)
	SET @s = ''
	SET @i = 1

	WHILE @i <= @len
	BEGIN
		SET @c = SUBSTRING(@str, @i, 1)
		IF @c BETWEEN 'À' AND 'ä'
			SET @s = @s + RTRIM(impexp.get_latin_char(@c))
		ELSE
		BEGIN
			SET @c = UPPER(@c)
			IF NOT (@c BETWEEN 'A' AND 'Z' OR @c BETWEEN '0' AND '9' OR @c IN ('+', '(', ')', '?', '''', ':', '-', '/', ',', '.', char(10), char(13)))
				SET @c = ' '

			SET @s = @s + @c
		END
		SET @i = @i + 1
	END
	
	RETURN @s
END
GO
