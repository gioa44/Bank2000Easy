SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[table_cross_rates_nbg] (@base_ccy TISO = 'GEL', @date smalldatetime) 
  RETURNS @tbl TABLE (
     ISO char(3) NOT NULL PRIMARY KEY,
     RATE decimal(32, 12) NOT NULL
  )
AS
BEGIN

  DECLARE @nat_rate TRATE

  IF @base_ccy = 'GEL'
  BEGIN
    INSERT INTO @tbl
    SELECT M.ISO, M.AMOUNT / CONVERT(decimal, M.ITEMS)
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE M.ISO = S.ISO AND S.DT <= @date)

    INSERT INTO @tbl
    VALUES ('GEL', CONVERT(decimal, 1))
  END
  ELSE
  BEGIN
    SELECT @nat_rate = M.AMOUNT / CONVERT(decimal, M.ITEMS)
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.ISO = @base_ccy AND M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE S.ISO = @base_ccy AND S.DT <= @date)

    INSERT INTO @tbl
    VALUES ('GEL', CONVERT(decimal, 1) / @nat_rate)

    INSERT INTO @tbl
    SELECT M.ISO, M.AMOUNT / CONVERT(decimal, M.ITEMS) / @nat_rate
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE M.ISO = S.ISO AND S.DT <= @date)
  END

  RETURN
END
GO
