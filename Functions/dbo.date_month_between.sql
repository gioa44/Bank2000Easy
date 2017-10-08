SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[date_month_between](@start_date smalldatetime, @end_date smalldatetime)
RETURNS int AS  
BEGIN
	DECLARE
		@months int

	SET @months = DATEDIFF(MONTH, @start_date, @end_date)
	
	IF (ISNULL(@months, 0) > 0) AND (DATEADD(MONTH, @months, @start_date) > @end_date)
		SET @months = @months - 1

	RETURN (@months)
END
GO
