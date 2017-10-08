SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_GET_CUR_RATE_INFO]
  @iso TISO,
  @rate_kind tinyint,
  @amount TAMOUNT OUTPUT,
  @items int OUTPUT,
  @dt smalldatetime = null
AS

SET NOCOUNT ON

IF @iso = 'GEL'
BEGIN  SET @items  = 1
  SET @amount = 1
  RETURN (0)
END

IF NOT (@rate_kind IN (0,1,2,3,99))
BEGIN
  RAISERROR('<ERR>ÀÒÀÓßÏÒÉ ÐÀÒÀÌÄÔÒÉ : %d</ERR>',16,1,@rate_kind)
  RETURN (1)
END

IF @rate_kind = 99
BEGIN
  IF @dt IS NULL 
    SET @dt = convert(smalldatetime,floor(convert(real,getdate())))

  SELECT @amount = AMOUNT, @items = ITEMS
  FROM dbo.VAL_RATES
  WHERE ISO = @iso and DT = (SELECT MAX(DT) FROM VAL_RATES WHERE ISO = @iso and DT <= @dt)
END
ELSE
IF @rate_kind = 0
BEGIN
  SELECT @amount = AMOUNT_BUY, @items = ITEMS
  FROM CURRENT_RATES
  WHERE ISO = @iso
END
ELSE
IF @rate_kind = 1
BEGIN
  SELECT @amount = AMOUNT_SELL, @items = ITEMS
  FROM CURRENT_RATES
  WHERE ISO = @iso
END
ELSE
IF @rate_kind = 2
BEGIN
  SELECT @amount = AMOUNT_BUY, @items = ITEMS
  FROM CURRENT_RATES_KAS
  WHERE ISO = @iso
END
ELSE
IF @rate_kind = 3
BEGIN
  SELECT @amount = AMOUNT_SELL, @items = ITEMS
  FROM CURRENT_RATES_KAS
  WHERE ISO = @iso
END

IF @items IS NULL
BEGIN
  RAISERROR('<ERR>%s ÅÀËÖÔÉÓ ÊÖÒÓÉ ÀÒ ÌÏÉÞÄÁÍÀ</ERR>',16,1,@iso)
  RETURN (1)
END
RETURN (0)
GO
