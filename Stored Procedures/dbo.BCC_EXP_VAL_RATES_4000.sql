SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_EXP_VAL_RATES_4000]
  @dt smalldatetime = 0
AS

SET NOCOUNT ON

SELECT R.ISO, R.DT, R.ITEMS, R.AMOUNT
FROM dbo.VAL_RATES R
  INNER JOIN dbo.VAL_CODES C ON C.ISO = R.ISO
WHERE C.IS_DISABLED = 0 AND R.DT >= ISNULL(@dt,0)
GO
