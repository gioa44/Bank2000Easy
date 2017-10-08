SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SYS_BUILD_BALANCES] (@dt1 smalldatetime, @dt2 smalldatetime) AS

SET NOCOUNT ON

DECLARE @dt smalldatetime

SET @dt = @dt1
WHILE @dt < @dt2
BEGIN
  EXEC dbo.SYS_BUILD_BALANCE @dt
  SET @dt = @dt + 1
END
GO
