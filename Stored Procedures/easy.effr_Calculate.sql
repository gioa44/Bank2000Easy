SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [easy].[effr_Calculate] 
	@epsilon float = 0.00000001,
	@cashFlow easy.t_CashFlow READONLY,
	@result float OUTPUT
AS
	SET @result = NULL;

	DECLARE
		@iterations int = 1,
		@x float = easy.effr_fi(0.02, @cashFlow),
		@y float;

	SET @y = easy.effr_f(@x, @cashFlow);
	
	WHILE ABS(@y) >= @epsilon
	BEGIN
		IF ABS(@x) > 1000.0
			RETURN 0;

		SET @x = easy.effr_fi(@x, @cashFlow)
	    
		SET @iterations = @iterations + 1;

		PRINT @iterations

		IF @iterations > 10000
			BREAK;

		SET @y = easy.effr_f(@x, @cashFlow);
	END;

	SET @result = ROUND(@x, 7);
	RETURN 0;
GO
