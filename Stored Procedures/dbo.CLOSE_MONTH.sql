SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CLOSE_MONTH] AS

SET NOCOUNT ON

DECLARE
  @date smalldatetime,
  @r int

SET @date = dbo.bank_open_date ()

DECLARE @msg nvarchar(255)
SET @msg =  'CLOSING MONTH: ' + CONVERT(varchar(2),MONTH(@date)) + '-' + CONVERT(varchar(4),YEAR(@date))
PRINT @msg

IF DAY(@date + 1) <> 1
BEGIN
  SET @msg = CONVERT(varchar(20), @date, 103)
  RAISERROR ('<ERR>Cannot close month. %s is not last day of month</ERR>', 16, 1, @msg)
  RETURN(-1009)
END

--

IF MONTH(@date + 1) = 1
BEGIN
  EXEC @r = dbo.CLOSE_YEAR
  IF @@ERROR <> 0 OR @r <> 0 RETURN(-1003)
END
GO
