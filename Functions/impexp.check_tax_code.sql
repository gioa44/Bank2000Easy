SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [impexp].[check_tax_code] (@tax_code varchar(20))
RETURNS smallint
AS
BEGIN
	IF LEN(@tax_code) = 11
		RETURN (0)

	IF LEN(@tax_code) <> 9
		RETURN (10) --ÀÌ ÅÄËÛÉ ÛÄÉÞËÄÁÀ ÌáÏËÏÃ 9 ÀÍ 11 ÍÉÛÍÀ ÓÀÂÀÓÀÓÀáÀÃÏ ÊÏÃÉÓ ÀÍ ÐÉÒÀÃÉ ÍÏÌÒÉÓ ÜÀßÄÒÀ

	IF LEFT(@tax_code, 1) NOT IN ('1', '2')
		RETURN (20) --ÐÉÒÅÄËÉ ÈÀÍÒÉÂÉ ÖÍÃÀ ÉÚÏÓ 1 ÀÍ 2

	DECLARE
		@I int,
		@tax_magic_number char(8),
		@s8 varchar(9),
		@imult int,
		@smult int

	SET @tax_magic_number = '21212121'			
	
	SET @imult = 0
	SET @s8 = SUBSTRING(@tax_code, 1, 8)

	SET @I = 1
	WHILE @I <= 8 
	BEGIN
		SET @smult = (ASCII(SUBSTRING(@s8, @I, 1)) - ASCII('0')) * (ASCII(SUBSTRING(@tax_magic_number, @I, 1)) - ASCII('0'))

		IF @smult < 10 
			SET @imult = @imult + @smult
		ELSE
			SET @imult = @imult + (1 + @smult - 10);
		SET @I = @I + 1
	END

	SET @imult = @imult % 10
	
	IF @imult = 0 
		SET @s8 = @s8 + '0'
	ELSE
		SET @s8 = @s8 + convert(char(1), 10 - @imult)

	IF @s8 <> @tax_code 
		RETURN (30) --ÓÀÂÀÓÀÓÀáÀÃÏ ÊÏÃÉÓ ÓÀÊÏÍÔÒÏËÏ ÂÀÓÀÙÄÁÉ ÀÒÀÓßÏÒÉÀ

	RETURN 0 --Good
END
GO
