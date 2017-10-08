SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[so_is_valid_proc_date](@date datetime, @schedule_date datetime, @period_type int, @holiday_shifting int, @current_try_no int)
RETURNS bit
BEGIN
	DECLARE
		@is_holiday bit

	SET @is_holiday = dbo.date_is_holiday(@date)
	
	SET @schedule_date = ISNULL(@schedule_date, @date)
	SET @current_try_no = ISNULL(@current_try_no, 0)
	
	IF (DATEADD(dd, @current_try_no, @schedule_date) <=  @date AND (@is_holiday = 0 OR @holiday_shifting = 0))
		RETURN 1

	RETURN 0	
END
GO
