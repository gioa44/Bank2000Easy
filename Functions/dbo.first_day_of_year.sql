SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[first_day_of_year] (@dt smalldatetime)
RETURNS smalldatetime AS  
BEGIN 
	RETURN DATEADD(Day, - DATEPART(dayofyear, @dt) + 1, @dt)
END
GO
