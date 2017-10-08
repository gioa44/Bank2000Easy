SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[show_terrorists]
	@words varchar(1000)
AS
BEGIN

SET NOCOUNT ON;

DECLARE 
	@n int,
	@s varchar(1000),
	@res varchar(1000)

	SET @s = @words
	SET @res = ''

	SET @n = CHARINDEX(' ', @s)
	WHILE @n > 0 
	BEGIN
		IF @res <> ''
			SET @res = @res + ' AND ';		
		SET @res = @res + 'FORMSOF (INFLECTIONAL,' + SUBSTRING(@s, 1, @n - 1) + ')'		
		SET @s = SUBSTRING(@s, @n+1, LEN(@s))
		SET @n = CHARINDEX(' ', @s)
	END
	IF @res <> ''
		SET @res = @res + ' AND ';
	SET @res = @res + 'FORMSOF (INFLECTIONAL,' + @s + ')'

	SELECT * FROM TERORISTS
	WHERE CONTAINS(DESCRIP, @res)
END
GO
