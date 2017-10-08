SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [af].[depo_prod_func_fix_amount]
	(@is_debit bit, @acc_id int, @amount money, @iso char(3), @dt smalldatetime, @a1 money, @a2 money, @a_fix money, @p money)
RETURNS money
AS
BEGIN
	DECLARE @result money

	SET @a1 = ISNULL(@a1, $0.00)
	SET @a2 = ISNULL(@a2, $0.00)
	SET @a_fix = ISNULL(@a_fix, $0.00)
	
	IF @a2 <= @a1
		SET @a2 = NULL 
	
	SET @p = ISNULL(@p, $0.00)
	
	IF @is_debit = 0
		SET @amount = - @amount

	SET @result = $0.0000

	IF @amount >= @a_fix and @amount >= @a1 and ((@a2 IS NULL) OR (@amount <= @a2))
		SET @result = @a_fix * @p

	RETURN @result
END

GO
