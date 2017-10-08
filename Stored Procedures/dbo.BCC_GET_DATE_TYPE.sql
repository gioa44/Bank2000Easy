SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_GET_DATE_TYPE] (@dt smalldatetime, @type tinyint OUTPUT) AS

SET @type = null

SELECT @type = DAY_TYPE FROM dbo.CALENDAR 
WHERE DT = @dt

IF @type IS NOT NULL return (0)

IF DATEPART(dw,@dt) = 1
  SET @type = 2
ELSE
IF DATEPART(dw,@dt) = 7 
  SET @type = 1
ELSE
  SET @type = 0

RETURN 0

GO
