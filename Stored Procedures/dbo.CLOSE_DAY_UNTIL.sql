SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CLOSE_DAY_UNTIL]
	@to_date smalldatetime
 AS

DECLARE
  @dt smalldatetime,
  @r int

SET @dt = dbo.bank_open_date()

IF @dt >= @to_date
BEGIN
	RAISERROR('ÀÒÀÓßÏÒÉ ÈÀÒÉÙÉ',16,1)
	ROLLBACK
	RETURN(1)
END


WHILE @dt < @to_date
BEGIN
	EXEC @r = dbo.CLOSE_DAY
	IF @@ERROR <> 0 OR @r <> 0 RETURN (2)

	SET @dt = dbo.bank_open_date()
END

RETURN (0)
GO
