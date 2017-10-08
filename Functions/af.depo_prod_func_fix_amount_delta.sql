SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [af].[depo_prod_func_fix_amount_delta]
	(@is_debit bit, @acc_id int, @amount money, @iso char(3), @dt smalldatetime, @a1 money, @a2 money, @a_fix money, @p_fix money, @p_delta money)
RETURNS money
AS
BEGIN
	DECLARE @result money

	SET @a1 = ISNULL(@a1, $0.00)
	SET @a2 = ISNULL(@a2, $0.00)
	
	IF @a2 <= @a1
		SET @a2 = NULL 
		
	SET @a_fix = ISNULL(@a_fix, $0.00)
	SET @p_fix = ISNULL(@p_fix, $0.00)
	SET @p_delta = ISNULL(@p_delta, $0.00)
	
	IF @is_debit = 0
		SET @amount = - @amount

	SET @result = $0.0000

	IF (@amount < @a1) OR ((@a2 IS NOT NULL) AND (@amount > @a2))
		RETURN @result
		
	IF @amount >= @a_fix
	BEGIN
		SET @result = @a_fix * @p_fix
		SET @amount = @amount - @a_fix
	END
	
	SET @result = @result + (@amount * @p_delta)	

	RETURN @result
END
GO
