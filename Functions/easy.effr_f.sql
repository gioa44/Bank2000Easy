SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [easy].[effr_f](@x float, @cashFlow easy.t_CashFlow READONLY)
RETURNS float AS
BEGIN
    DECLARE
		@s float;
	
	SELECT @s = SUM(AMOUNT / POWER(1 + @x, YearSpan))
	FROM @cashFlow	
	
	RETURN ISNULL(@s, 0.0)
END
GO
