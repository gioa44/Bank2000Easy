SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_RATE_INFO]
  @iso TISO,
  @dt smalldatetime,
  @amount money OUTPUT,
  @items int OUTPUT
AS

SET NOCOUNT ON

IF @iso = 'GEL'
BEGIN
	SET @items  = 1
	SET @amount = 1
	RETURN (0)
END

SELECT TOP 1 @amount = AMOUNT, @items = ITEMS
FROM dbo.VAL_RATES (NOLOCK)
WHERE ISO = @iso AND DT <= @dt
ORDER BY DT DESC

IF @items IS NULL
BEGIN	RAISERROR('ÅÀËÖÔÉÓ ÊÖÒÓÉ ÀÒ ÌÏÉÞÄÁÍÀ',16,1)
	RETURN (1)
END
RETURN (0)
GO
