SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [af].[def_func] (@is_debit bit, @acc_id int, @amount money, @iso char(3), @dt smalldatetime, 
	@a1 money, @p1 money, @a2 money, @p2 money, 
	@a3 money, @p3 money, @a4 money, @p4 money, 
	@a5 money, @p5 money)
RETURNS money
AS
BEGIN
	DECLARE @result money

	SET @p1 = ISNULL(@p1, $0)
	SET @p2 = ISNULL(@p2, $0)
	SET @p3 = ISNULL(@p3, $0)
	SET @p4 = ISNULL(@p4, $0)
	SET @p5 = ISNULL(@p5, $0)
	
	IF ISNULL(@a2, $0) <= ISNULL(@a1, $0)
		SET @a2 = NULL
	IF ISNULL(@a3, $0) <= ISNULL(@a2, $0)
		SET @a3 = NULL
	IF ISNULL(@a4, $0) <= ISNULL(@a3, $0)
		SET @a4 = NULL
	IF ISNULL(@a5, $0) <= ISNULL(@a4, $0)
		SET @a5 = NULL
	
	IF @is_debit = 0
		SET @amount = - @amount

	SET @result = $0.0000
	IF @a5 IS NOT NULL AND @amount > @a5
		SET @result = @amount * @p5
	ELSE
	IF @a4 IS NOT NULL AND @amount > @a4
		SET @result = @amount * @p4
	ELSE
	IF @a3 IS NOT NULL AND @amount > @a3
		SET @result = @amount * @p3
	ELSE
	IF @a2 IS NOT NULL AND @amount > @a2
		SET @result = @amount * @p2
	ELSE
	IF @amount > ISNULL(@a1, $0.0000)
		SET @result = @amount * @p1

	--IF @is_debit = 0
	--	SET @result = - @result

	RETURN @result
END
GO
