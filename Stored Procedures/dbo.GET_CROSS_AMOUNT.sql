SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[GET_CROSS_AMOUNT]
  @iso1		TISO,
  @iso2		TISO,
  @amount 	TAMOUNT,
  @dt		smalldatetime,
  @new_amount 	TAMOUNT 	OUTPUT
AS

SET NOCOUNT ON

IF @iso1 = @iso2
BEGIN
  SET @new_amount = @amount
  RETURN (0)
END
ELSE
BEGIN
  DECLARE
    @items1 int,
    @items2 int,
    @amount1 TAMOUNT,
    @amount2 TAMOUNT

  IF @iso1 = 'GEL'
  BEGIN
    SET @amount1 = 1
    SET @items1  = 1
  END
  ELSE
  BEGIN
    SELECT @amount1 = AMOUNT, @items1 = ITEMS
    FROM  VAL_RATES
    WHERE ISO=@iso1 and DT = (SELECT MAX(DT) FROM VAL_RATES WHERE (ISO=@iso1) and (DT<=@dt))
    IF (@@ERROR <> 0) RETURN (2)
    IF (@amount1 IS NULL) or (@items1 IS NULL)
    BEGIN
      RAISERROR('%s ÅÀËÖÔÉÓ ÊÖÒÓÉ ÀÒ ÌÏÉÞÄÁÍÀ',16,1,@iso1)
      RETURN (3)
    END
  END

  IF @iso2 = 'GEL'
  BEGIN
    SET @amount2 = 1
    SET @items2  = 1
  END
  ELSE
  BEGIN
    SELECT @amount2 = AMOUNT, @items2 = ITEMS
    FROM  VAL_RATES
    WHERE ISO=@iso2 and DT = (SELECT MAX(DT) FROM VAL_RATES WHERE (ISO=@iso2) and (DT<=@dt))
    IF (@@ERROR <> 0) RETURN (3)
    IF (@amount2 IS NULL) or (@items2 IS NULL)
    BEGIN
      RAISERROR('%s ÅÀËÖÔÉÓ ÊÖÒÓÉ ÀÒ ÌÏÉÞÄÁÍÀ',16,1,@iso2)
      RETURN (3)
    END
  END

  SELECT @new_amount = @amount * (@amount1 * @items2) / (@amount2 * @items1)
  IF (@@ERROR <> 0) RETURN (9)

  DECLARE @retval Int
  EXEC @retval = ROUND_BY_ISO @new_amount,@iso2, @new_amount OUTPUT
  IF (@@ERROR <> 0) RETURN (4)
  ELSE RETURN @retval
END







GO
