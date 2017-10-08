SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[depo_fn_get_formula_accrue](@depo_id int, @op_amount money, @old_amount money, @old_intrate decimal(32, 12), @op_intrate money)
RETURNS varchar(255)
AS
BEGIN
	DECLARE
		@function_id int,
		@function_name varchar(512),
		@function_params varchar(512),
		@function varchar(512),
		@prod_id int,
		@iso TISO,
		@intrate TRATE

	DECLARE
		@range_1 money,
		@range_2 money

	SELECT @prod_id = PROD_ID, @iso = ISO, @range_1 = PROD_ACCRUE_MIN, @range_2 = PROD_ACCRUE_MAX
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id
	
	SELECT @function_id = FUNCTION_ID
	FROM dbo.DEPO_PRODUCT (NOLOCK)
	WHERE PROD_ID = @prod_id
	
	SELECT @function_name = FUNCTION_NAME
	FROM af.FUNCTIONS (NOLOCK)
	WHERE FUNCTION_ID = @function_id
	

	SET @intrate = dbo.depo_fn_get_formula_accrue_value(@op_amount, @old_amount, @old_intrate, @op_intrate)
	

	SET @function_params = ',$' + convert(varchar(32), @intrate)
	SET @function = @function_name + '(0, @acc_id, AMOUNT,''' + convert(char(3),@iso) + ''',DT,$' + convert(varchar(30), ISNULL(@range_1, $0.00)) + ',$' + convert(varchar(30), ISNULL(@range_2, $0.00)) + @function_params + ')'
	
	RETURN @function
END
GO
