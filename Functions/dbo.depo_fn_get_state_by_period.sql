SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_state_by_period](@date1 smalldatetime, @date2 smalldatetime, @state tinyint,
	@start_date smalldatetime, @end_date smalldatetime, @annulment_date smalldatetime, @close_op_date smalldatetime)
RETURNS tinyint
AS
BEGIN
	DECLARE 
		@result tinyint

	SET @result = 0
	
	IF @end_date IS NULL
		SET @end_date = @close_op_date

	IF (@start_date > @date2) OR ((@start_date = @date2) AND (@state = 40))
		GOTO RESULT_
		
	IF ((@end_date IS NOT NULL) AND (@end_date <= @date1)) OR ((@annulment_date IS NOT NULL) AND (@annulment_date <= @date1))
		GOTO RESULT_
		
	IF (@annulment_date IS NOT NULL) AND (@annulment_date > @date2)
	BEGIN
		SET @result = 50
		GOTO RESULT_ 
	END
	
	SET @result = @state
RESULT_:
	RETURN (@result)
END
GO
