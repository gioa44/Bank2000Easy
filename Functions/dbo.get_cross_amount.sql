SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[get_cross_amount] (@amount money, @ccy1 TISO, @ccy2 TISO, @date smalldatetime)
RETURNS money AS
BEGIN

DECLARE @new_amount money

IF @ccy1 = @ccy2
  SET @new_amount = @amount
ELSE
BEGIN
  DECLARE
    @items1 int,
    @items2 int,
    @amount1 TAMOUNT,
    @amount2 TAMOUNT

  SET @date = convert(smalldatetime,floor(convert(real,@date)))
  IF @ccy1 = 'GEL'
  BEGIN
    SET @amount1 = 1
    SET @items1  = 1
  END
  ELSE
  BEGIN
    SELECT @amount1 = AMOUNT, @items1 = ITEMS
    FROM  dbo.VAL_RATES (NOLOCK)
    WHERE ISO=@ccy1 and DT = (SELECT MAX(DT) FROM dbo.VAL_RATES (NOLOCK) WHERE (ISO = @ccy1) and (DT <= @date))
  END

  IF @ccy2 = 'GEL'
  BEGIN
    SET @amount2 = 1
    SET @items2  = 1
  END
  ELSE
  BEGIN
    SELECT @amount2 = AMOUNT, @items2 = ITEMS
    FROM  dbo.VAL_RATES (NOLOCK)
    WHERE ISO=@ccy2 and DT = (SELECT MAX(DT) FROM dbo.VAL_RATES (NOLOCK) WHERE (ISO = @ccy2) and (DT <= @date))
  END

  SELECT @new_amount = @amount * (@amount1 * @items2) / (@amount2 * @items1)
END

RETURN ROUND(@new_amount,2,1)
END
GO
