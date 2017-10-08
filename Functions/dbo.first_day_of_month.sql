SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[first_day_of_month] (@dt smalldatetime)
RETURNS smalldatetime AS  
BEGIN 
  RETURN DATEADD(dd, - DAY(@dt) + 1, @dt)
END
GO
