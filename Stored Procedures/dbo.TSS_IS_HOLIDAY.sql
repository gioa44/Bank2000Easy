SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[TSS_IS_HOLIDAY](@is_holiday bit OUTPUT) AS

DECLARE 
  @dt smalldatetime,
  @year smallint

SET @dt = GETDATE()
SET @dt = CONVERT(SMALLDATETIME,FLOOR(CONVERT(float,@dt)))
SET @year = YEAR(@dt)

IF NOT EXISTS(SELECT * FROM BANK2000.dbo.HOLIDAYS WHERE YEARS = @year)
  SET @year = -1

DECLARE 
  @idx smallint,
  @b tinyint

SET @idx = (MONTH(@dt)-1) * 4 + ((DAY(@dt)-1) / 8)
SELECT @b = SUBSTRING(DATA,@idx,2)
from BANK2000.dbo.HOLIDAYS
WHERE YEARS = @year

DECLARE @shl tinyint
SET @shl = (DAY(@dt)-1) % 8

DECLARE 
  @bits tinyint

SET @bits = 1
SET @idx = 0
WHILE @idx < @shl
BEGIN
  SET @bits = @bits * 2
  SET @idx = @idx + 1
END

SET DATEFIRST 1

IF (CASE WHEN @b & @bits = 0 THEN 0 ELSE 1 END) + 
   (CASE WHEN (@year = -1 AND DATEPART(WEEKDAY,@dt) IN (6,7)) THEN 1 ELSE 0 END) <> 0
     SET @is_holiday = 1
ELSE SET @is_holiday = 0


GO
