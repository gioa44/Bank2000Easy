SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[GET_NEAR_DAY_UP](@date smalldatetime)
RETURNS smalldatetime
AS
BEGIN
  DECLARE
    @count int

	 
  SELECT @count=COUNT(*) FROM dbo.CALENDAR WHERE DT=@date AND DAY_TYPE=2
  
  WHILE (@count = 0 AND DATEPART(dw, @date) = 1) OR  (@count = 1)
  BEGIN
    SET @date = @date + 1
    SELECT @count=COUNT(*) FROM dbo.CALENDAR WHERE DT=@date AND DAY_TYPE=2		
  END
  
  RETURN @date
END
GO
