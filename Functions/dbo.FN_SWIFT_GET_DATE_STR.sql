SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[FN_SWIFT_GET_DATE_STR](@date smalldatetime)
RETURNS char(8) AS  
BEGIN
  DECLARE
    @date_str varchar(8)

  IF @date IS NULL 
    RETURN NULL

  SET @date_str = ''

  DECLARE
    @tmp_part varchar(2)

  SET @tmp_part = SUBSTRING(convert(varchar(4), DATEPART(yy, @date)), 3, 2)
  SET @date_str = @tmp_part + '/'
  SET @tmp_part = convert(varchar(2), DATEPART(mm, @date))
  SET @date_str = @date_str + CASE WHEN LEN(@tmp_part) = 1 THEN '0' + @tmp_part ELSE @tmp_part END + '/'
  SET @tmp_part = convert(varchar(2), DATEPART(dd, @date))
  SET @date_str = @date_str + CASE WHEN LEN(@tmp_part) = 1 THEN '0' + @tmp_part ELSE @tmp_part END

  return convert(char(8), @date_str)
END
GO
