SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[table_cross_rate_diffs_nbg] (@base_ccy TISO = 'GEL', @date smalldatetime) 
  RETURNS @tbl TABLE (
     ISO char(3) NOT NULL PRIMARY KEY,
     RATE_DIFF decimal(32, 12) NOT NULL
  )
AS
BEGIN

  DECLARE @tbl_prev TABLE (
     ISO char(3) NOT NULL PRIMARY KEY,
     RATE decimal(32, 12) NOT NULL
  )

  DECLARE @nat_rate TRATE

  IF @base_ccy = 'GEL'
  BEGIN
    INSERT INTO @tbl_prev
    SELECT M.ISO, M.AMOUNT / CONVERT(decimal, M.ITEMS)
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE M.ISO = S.ISO AND S.DT < @date)

    INSERT INTO @tbl
    SELECT M.ISO, M.AMOUNT / CONVERT(decimal, M.ITEMS)
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE M.ISO = S.ISO AND S.DT <= @date)
  END
  ELSE
  BEGIN
    SELECT @nat_rate = M.AMOUNT / CONVERT(decimal, M.ITEMS)
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.ISO = @base_ccy AND M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE S.ISO = @base_ccy AND S.DT < @date)

    INSERT INTO @tbl_prev
    SELECT M.ISO, M.AMOUNT / CONVERT(decimal, M.ITEMS) / @nat_rate
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE M.ISO = S.ISO AND S.DT < @date)

    SELECT @nat_rate = M.AMOUNT / CONVERT(decimal, M.ITEMS)
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.ISO = @base_ccy AND M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE S.ISO = @base_ccy AND S.DT <= @date)

    INSERT INTO @tbl
    SELECT M.ISO, M.AMOUNT / CONVERT(decimal, M.ITEMS) / @nat_rate
    FROM dbo.VAL_RATES M (NOLOCK)
    WHERE M.DT = (SELECT MAX(S.DT) FROM dbo.VAL_RATES S (NOLOCK) WHERE M.ISO = S.ISO AND S.DT <= @date)
  END

  UPDATE @tbl
  SET RATE_DIFF = A.RATE_DIFF - B.RATE
  FROM @tbl A 
    INNER JOIN @tbl_prev B ON A.ISO = B.ISO

  DELETE FROM @tbl
  WHERE RATE_DIFF = 0

  RETURN
END
GO
