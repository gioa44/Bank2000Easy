SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[date_prev_workday](@date smalldatetime)
RETURNS smalldatetime AS  
BEGIN
	WHILE dbo.date_is_holiday(@date) = 1
		SET @date = DATEADD(day, -1, @date)

	RETURN (@date)
END
GO
