SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [easy].[effr_df](@x float, @cashFlow easy.t_CashFlow READONLY)
RETURNS float AS
BEGIN
    DECLARE
		@s float;
	
	SELECT @s = SUM(YearSpan * AMOUNT / POWER(1 + @x, YearSpan + 1))
	FROM @cashFlow	
	
	RETURN -ISNULL(@s, 0.0)
END
GO
