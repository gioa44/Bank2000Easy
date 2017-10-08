SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [impexp].[get_latin_char] (@c char(1))
RETURNS varchar(3)
AS
BEGIN
	RETURN
		CASE @c 
		  WHEN 'À' THEN 'A'
		  WHEN 'Á' THEN 'B'
		  WHEN 'Â' THEN 'G'
		  WHEN 'Ã' THEN 'D'
		  WHEN 'Ä' THEN 'E'
		  WHEN 'Å' THEN 'V'
		  WHEN 'Æ' THEN 'Z'
		  WHEN 'È' THEN 'T'
		  WHEN 'É' THEN 'I'
		  WHEN 'Ê' THEN 'K'
		  WHEN 'Ë' THEN 'L'
		  WHEN 'Ì' THEN 'M'
		  WHEN 'Í' THEN 'N'
		  WHEN 'Ï' THEN 'O'
		  WHEN 'Ð' THEN 'P'
		  WHEN 'Ñ' THEN 'J'
		  WHEN 'Ò' THEN 'R'
		  WHEN 'Ó' THEN 'S'
		  WHEN 'Ô' THEN 'T'
		  WHEN 'Ö' THEN 'U'
		  WHEN '×' THEN 'P'
		  WHEN 'Ø' THEN 'K'
		  WHEN 'Ù' THEN 'G'
		  WHEN 'Ú' THEN 'K'
		  WHEN 'Û' THEN 'SH'
		  WHEN 'Ü' THEN 'CH'
		  WHEN 'Ý' THEN 'TS'
		  WHEN 'Þ' THEN 'DZ'
		  WHEN 'ß' THEN 'TS'
		  WHEN 'à' THEN 'TCH'
		  WHEN 'á' THEN 'KH'
		  WHEN 'ã' THEN 'DJ'
		  WHEN 'ä' THEN 'H'
		  ELSE @c
		END
END
GO
