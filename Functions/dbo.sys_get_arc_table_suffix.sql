SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[sys_get_arc_table_suffix] (@year int)
RETURNS varchar(4)
AS
BEGIN
  DECLARE @suffix varchar(4)
  IF @year = 0
    SET @suffix = '0000'
  ELSE
  BEGIN
    IF @year < 2000
      SET @year = 2000
    SET @suffix = CONVERT(varchar(4), @year)
  END

  RETURN @suffix
END
GO
