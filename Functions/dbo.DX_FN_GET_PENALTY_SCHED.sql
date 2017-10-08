SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[DX_FN_GET_PENALTY_SCHED](@did int, @iso TISO, @start_date smalldatetime, @end_date smalldatetime)
RETURNS varchar(1000)
AS
BEGIN
	DECLARE
		@result varchar(1000),
		@months int
	
	SET @result = ''
	SET @months = DATEDIFF(m, @start_date, @end_date)

	SET @result = 
		'1. - 2.5%' + CHAR(13) +
		'2. - 3.5%' + CHAR(13) +
		'3. - 4.5%' + CHAR(13)

	RETURN (@result)
END
GO
