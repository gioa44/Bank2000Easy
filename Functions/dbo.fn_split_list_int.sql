SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO


CREATE FUNCTION [dbo].[fn_split_list_int] (@list varchar(8000), @delimiter char(1) = ',')
RETURNS @table table ([ID] int PRIMARY KEY CLUSTERED) AS
BEGIN
  DECLARE @id varchar(10), @pos int
  
  SET @list = LTRIM(RTRIM(@list)) + @delimiter
  SET @pos = CHARINDEX(@delimiter, @list, 1)

  IF REPLACE(@list, @delimiter, '') <> ''
  BEGIN
    WHILE @pos > 0
    BEGIN
      SET @id = LTRIM(RTRIM(LEFT(@list, @pos - 1)))
      IF @id <> ''
      BEGIN
	 INSERT INTO @table ([ID]) 
	 VALUES (CAST(@id AS int))
      END
      SET @list = RIGHT(@list, LEN(@list) - @pos)
      SET @pos = CHARINDEX(@delimiter, @list, 1)
    END
  END	
  RETURN
END

GO
