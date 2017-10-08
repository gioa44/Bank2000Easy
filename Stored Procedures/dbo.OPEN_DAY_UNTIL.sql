SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[OPEN_DAY_UNTIL]
	@to_date smalldatetime,
	@open_work_date bit = 0
AS

DECLARE
  @dt smalldatetime,
  @r int

SET @dt = dbo.bank_open_date()

IF @dt <= @to_date
BEGIN
	RAISERROR('ÀÒÀÓßÏÒÉ ÈÀÒÉÙÉ',16,1)
	ROLLBACK
	RETURN(1)
END


WHILE @to_date < @dt
BEGIN
	EXEC @r = dbo.OPEN_DAY @open_work_date
	IF @@ERROR <> 0 OR @r <> 0 RETURN (2)

	SET @dt = dbo.bank_open_date()
END

RETURN (0)
GO
