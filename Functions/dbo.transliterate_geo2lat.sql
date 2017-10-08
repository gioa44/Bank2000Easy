SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[transliterate_geo2lat] (@s varchar(max))
RETURNS varchar(max)
BEGIN
	DECLARE
		@i int,
		@c varchar(2),
		@result varchar(max);

	SET @result = '';
	SET @i = 1
	WHILE @i <= LEN(@s)
	BEGIN
		SET @c = CASE SUBSTRING(@s, @i, 1)
			WHEN 'À' THEN 'a'
      		WHEN 'Á' THEN 'b'
      		WHEN 'Â' THEN 'g'
      		WHEN 'Ã' THEN 'd'
      		WHEN 'Ä' THEN 'e'
      		WHEN 'Å' THEN 'v'
      		WHEN 'Æ' THEN 'z'
      		WHEN 'È' THEN 't'
      		WHEN 'É' THEN 'i'
      		WHEN 'Ê' THEN 'k'
      		WHEN 'Ë' THEN 'l'
      		WHEN 'Ì' THEN 'm'
      		WHEN 'Í' THEN 'n'
      		WHEN 'Ï' THEN 'o'
      		WHEN 'Ð' THEN 'p'
      		WHEN 'Ñ' THEN 'j'
      		WHEN 'Ò' THEN 'r'
      		WHEN 'Ó' THEN 's'
      		WHEN 'Ô' THEN 't'
      		WHEN 'Ö' THEN 'u'
      		WHEN '×' THEN 'p'
      		WHEN 'Ø' THEN 'k'
      		WHEN 'Ù' THEN 'g'
      		WHEN 'Ú' THEN 'k'
      		WHEN 'Û' THEN 'sh'
      		WHEN 'Ü' THEN 'ch'
      		WHEN 'Ý' THEN 'ts'
      		WHEN 'Þ' THEN 'dz'
      		WHEN 'ß' THEN 'ts'
      		WHEN 'à' THEN 'tch'
      		WHEN 'á' THEN 'kh'
      		WHEN 'ã' THEN 'dj'
      		WHEN 'ä' THEN 'h'
      		ELSE SUBSTRING(@s, @i, 1)
		END;
		SET @result = @result + @c;
		SET @i = @i + 1;
	END
	IF LEN(@result) > 0
		SET @result = STUFF (@result, 1, 1, UPPER(SUBSTRING(@result, 1, 1))) 
 	return @result;
END;
GO
