SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_formula_accrue_value](@op_amount money, @old_amount money, @old_intrate decimal(32, 12), @op_intrate money)
RETURNS decimal(32, 12)
AS
BEGIN
	DECLARE
		@intrate TRATE

	SET @intrate = convert(decimal(32, 12), @old_amount * @old_intrate + @op_amount * @op_intrate) / (@old_amount + @op_amount)
	

	RETURN @intrate
END
GO
