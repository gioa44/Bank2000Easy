SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [impexp].[swift_break_string_tag72]
	@str varchar(210),
	@code varchar(35),
	@sw_str_35_1 varchar(35) OUTPUT,
	@sw_str_35_2 varchar(35) OUTPUT,
	@sw_str_35_3 varchar(35) OUTPUT,
	@sw_str_35_4 varchar(35) OUTPUT,
	@sw_str_35_5 varchar(35) OUTPUT,
	@sw_str_35_6 varchar(35) OUTPUT
AS
SET NOCOUNT ON
 
DECLARE
 @tmp_str varchar(310),
 @I int,
 @J int,
 @char char(1)
 
SET @str = REPLACE(@str, CHAR(0xD)+CHAR(0xA), ' ')
SET @str = REPLACE(@str, CHAR(0xD), ' ')
SET @str = REPLACE(@str, CHAR(0xA), ' ')
SET @tmp_str = @str
 

SET @I = 1
SET @J = LEN(@tmp_str)
SET @str = ''
 

WHILE @I <= @J
BEGIN
 SET @char = SUBSTRING(@tmp_str, @I, 1)
 IF @char NOT IN ('~','`','!','@','#','$','%','^','&','*','_','=','\','|','<','>',';','"')
  SET @str = @str + @char
 SET @I = @I + 1
END

SET @code = ISNULL(@code, '') 
IF @code <> ''
	SET @code = @code + ' '
 
IF LEN(@str) = 0 RETURN (0)

IF @sw_str_35_1 = ''
BEGIN
	SET @str = @code + LTRIM(RTRIM(@str))
	SET @code = '//'
	
	SET @tmp_str = SUBSTRING(@str, 1, 35)
	 
	IF SUBSTRING(@str, 36, 1) <> ' '
	BEGIN
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = SUBSTRING(@tmp_str, CHARINDEX(' ', @tmp_str), 35)
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = LTRIM(RTRIM(@tmp_str))
	END
	SET @str = SUBSTRING(@str, LEN(@tmp_str) + 1, 210) 
	WHILE LEN(@tmp_str) > 0 AND
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 47 AND 57 AND 
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 65 AND 90
			SET @tmp_str=SUBSTRING(@tmp_str,2,35)
	SET @sw_str_35_1 = @tmp_str
END
 
IF LEN(@str) = 0 RETURN (0)

IF @sw_str_35_2 = ''
BEGIN
	SET @str = @code + LTRIM(RTRIM(@str))
	SET @code = '//'

	SET @tmp_str = SUBSTRING(@str, 1, 35)
	 
	IF SUBSTRING(@str, 36, 1) <> ' '
	BEGIN
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = SUBSTRING(@tmp_str, CHARINDEX(' ', @tmp_str), 35)
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = LTRIM(RTRIM(@tmp_str))
	END
	SET @str = SUBSTRING(@str, LEN(@tmp_str) + 1, 210)
	WHILE LEN(@tmp_str) > 0 AND
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 47 AND 57 AND 
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 65 AND 90
			SET @tmp_str=SUBSTRING(@tmp_str,2,35)
	SET @sw_str_35_2 = @tmp_str
END

IF LEN(@str) = 0 RETURN (0)

IF @sw_str_35_3 = ''
BEGIN
	SET @str = @code + LTRIM(RTRIM(@str))
	SET @code = '//'

	SET @tmp_str = SUBSTRING(@str, 1, 35)
	 
	IF SUBSTRING(@str, 36, 1) <> ' '
	BEGIN
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = SUBSTRING(@tmp_str, CHARINDEX(' ', @tmp_str), 35)
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = LTRIM(RTRIM(@tmp_str))
	END
	SET @str = SUBSTRING(@str, LEN(@tmp_str) + 1, 210)
	WHILE LEN(@tmp_str) > 0 AND
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 47 AND 57 AND 
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 65 AND 90
			SET @tmp_str=SUBSTRING(@tmp_str,2,35)
	SET @sw_str_35_3 = @tmp_str
END

IF LEN(@str) = 0 RETURN (0)

IF @sw_str_35_4 = ''
BEGIN
	SET @str = @code + LTRIM(RTRIM(@str))
	SET @code = '//'

	SET @tmp_str = SUBSTRING(@str, 1, 35)
 
	IF SUBSTRING(@str, 36, 1) <> ' '
	BEGIN
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = SUBSTRING(@tmp_str, CHARINDEX(' ', @tmp_str), 35)
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = LTRIM(RTRIM(@tmp_str))
	END
	SET @str = SUBSTRING(@str, LEN(@tmp_str) + 1, 210)
	WHILE LEN(@tmp_str) > 0 AND
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 47 AND 57 AND 
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 65 AND 90
			SET @tmp_str=SUBSTRING(@tmp_str,2,35)
	SET @sw_str_35_4 = @tmp_str
END

IF LEN(@str) = 0 RETURN (0)

IF @sw_str_35_5 = ''
BEGIN
	SET @str = @code + LTRIM(RTRIM(@str))
	SET @code = '//'

	SET @tmp_str = SUBSTRING(@str, 1, 35)
	 
	IF SUBSTRING(@str, 36, 1) <> ' '
	BEGIN
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = SUBSTRING(@tmp_str, CHARINDEX(' ', @tmp_str), 35)
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = LTRIM(RTRIM(@tmp_str))
	END
	SET @str = SUBSTRING(@str, LEN(@tmp_str) + 1, 210)
	WHILE LEN(@tmp_str) > 0 AND
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 47 AND 57 AND 
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 65 AND 90
			SET @tmp_str=SUBSTRING(@tmp_str,2,35)
	SET @sw_str_35_5 = @tmp_str
END

IF LEN(@str) = 0 RETURN (0)
 
IF @sw_str_35_6 = ''
BEGIN
	SET @str = @code + LTRIM(RTRIM(@str))
	SET @code = '//'

	SET @tmp_str = SUBSTRING(@str, 1, 35)
	 
	IF SUBSTRING(@str, 36, 1) <> ' '
	BEGIN
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = SUBSTRING(@tmp_str, CHARINDEX(' ', @tmp_str), 35)
		SET @tmp_str = REVERSE(@tmp_str)
		SET @tmp_str = LTRIM(RTRIM(@tmp_str))
	END
	WHILE LEN(@tmp_str) > 0 AND
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 47 AND 57 AND 
		NOT UNICODE(UPPER(LEFT(@tmp_str,1))) BETWEEN 65 AND 90
			SET @tmp_str=SUBSTRING(@tmp_str,2,35)
	SET @sw_str_35_6 = @tmp_str
END
 
RETURN (0)
GO
