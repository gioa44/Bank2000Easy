SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [easy].[effr_fi](@x float, @cashFlow easy.t_CashFlow READONLY)
RETURNS float AS
BEGIN
	RETURN @x - easy.effr_f(@x, @cashFlow) / easy.effr_df(@x, @cashFlow);
END
GO
