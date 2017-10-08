SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[get_rate] (@ccy TISO, @date smalldatetime)
RETURNS TRATE AS
BEGIN
  DECLARE @rate TRATE
    
  IF @ccy = 'GEL'
    SET @rate = 1
  ELSE
  BEGIN
    SELECT TOP 1 @rate = CONVERT(decimal(32,12), A.AMOUNT) / A.ITEMS
    FROM  dbo.VAL_RATES A (NOLOCK)
    WHERE A.ISO = @ccy AND A.DT <= @date
	ORDER BY A.DT DESC
  END

  RETURN @rate
END
GO
