SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[depo_fn_get_formula](@depo_id int, @op_id int = NULL)
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
		@intrate money,
		@agreement_amount money,
		@spend bit,
		@spend_const_amount money,
		@spend_amount_intrate money,
		@accumulative bit,
		@accumulate_schema_intrate tinyint

	DECLARE
		@range_1 money,
		@range_2 money
		
	DECLARE
		@min_accrue_intrate varchar(10)

	SELECT @prod_id = PROD_ID, @iso = ISO, @intrate = ISNULL(INTRATE, 0), @range_1 = PROD_ACCRUE_MIN, @range_2 = PROD_ACCRUE_MAX,
		@agreement_amount = AGREEMENT_AMOUNT, @spend = SPEND, @spend_const_amount = ISNULL(SPEND_CONST_AMOUNT, $0.00), @spend_amount_intrate = ISNULL(SPEND_AMOUNT_INTRATE, $0.00),
		@accumulative = ACCUMULATIVE, @accumulate_schema_intrate = ACCUMULATE_SCHEMA_INTRATE
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id
	
	SELECT @function_id = FUNCTION_ID
	FROM dbo.DEPO_PRODUCT (NOLOCK)
	WHERE PROD_ID = @prod_id
	
	IF (@spend = 0) AND (@accumulative = 0)
	BEGIN
		IF @range_1 IS NULL
			SET @range_1 = @agreement_amount
		IF @range_2 IS NULL			
			SET @range_2 = @agreement_amount
	END
	
	SELECT @function_name = FUNCTION_NAME
	FROM af.FUNCTIONS (NOLOCK)
	WHERE FUNCTION_ID = @function_id

	IF @function_name = 'af.depo_prod_func_fix_amount'
		SET @function_params = ',$' + convert(varchar(30), @agreement_amount) + ',$' + convert(varchar(30), @intrate)
	ELSE
	IF @function_name = 'af.depo_prod_func_fix_amount_delta'
		SET @function_params = ',$' + convert(varchar(30), @spend_const_amount) + ',$' + convert(varchar(30), @intrate) + ',$' + convert(varchar(30), @spend_amount_intrate)
	ELSE
	IF @function_name = 'af.depo_prod_func_min_max_range'
		SET @function_params = ',$' + convert(varchar(30), @intrate)
	ELSE
	IF @function_name = 'af.depo_prod_func_floating_intrate'
		SET @function_params = ',$' + convert(varchar(32), @intrate)
			
	SET @function = @function_name + '(0, @acc_id, AMOUNT,''' + convert(char(3),@iso) + ''',DT,$' + convert(varchar(30), ISNULL(@range_1, $0.00)) + ',$' + convert(varchar(30), ISNULL(@range_2, $0.00)) + @function_params + ')'
	
	RETURN @function
END
GO
