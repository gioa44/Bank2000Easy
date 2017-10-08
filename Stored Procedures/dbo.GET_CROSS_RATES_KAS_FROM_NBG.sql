SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[GET_CROSS_RATES_KAS_FROM_NBG] AS

SET NOCOUNT ON

DECLARE 
  @iso1 TISO,
  @iso2 TISO, 
  @items int, 
  @dt smalldatetime

DECLARE CROSS_RATES_CURSOR CURSOR LOCAL
FOR
  SELECT ISO1,ISO2,ITEMS FROM CROSS_RATES_KAS
  FOR READ ONLY

CREATE TABLE #T
(
	[ISO1] char(3) NOT NULL ,
	[ISO2] char(3) NOT NULL ,
	[ITEMS] [int] NOT NULL ,
	[AMOUNT_BUY] money NULL ,
	[AMOUNT_SELL] money NULL 
)

  SET @dt = convert(smalldatetime,floor(convert(real,getdate())))

  OPEN CROSS_RATES_CURSOR

  FETCH NEXT FROM CROSS_RATES_CURSOR INTO @iso1, @iso2, @items
 
  WHILE @@FETCH_STATUS = 0
  BEGIN
    DECLARE 
      @amount1 TAMOUNT,
      @items1 int,
      @amount2 TAMOUNT,
      @items2 int

    SET @dt = (SELECT MAX(DT) FROM dbo.VAL_RATES WHERE DT<=@dt)
    SET @items1 = 1
    SET @items2 = 1    

    IF @iso1 <> 'GEL'
      SELECT @amount1 = AMOUNT, @items1 = ITEMS
      FROM dbo.VAL_RATES (NOLOCK)
      WHERE ISO=@iso1 and DT = @dt
    ELSE
      SELECT @amount1 = 1 
    IF @@ROWCOUNT = 1
    BEGIN
      IF @iso2 <> 'GEL'
        SELECT @amount2 = AMOUNT, @items2 = ITEMS
        FROM VAL_RATES 
        WHERE ISO=@iso2 and DT = @dt
      ELSE
        SELECT @amount2 = 1 
      IF @@ROWCOUNT = 1 AND (@amount2 * @items1 > 0)
      BEGIN
        DECLARE @rate_amount TAMOUNT
        SET @rate_amount = @amount1 * @items2 * 1.0 / @amount2 * @items1
    
        INSERT INTO #T
        SELECT @iso1, @iso2, @items, @rate_amount, @rate_amount
      END
    END

    FETCH NEXT FROM CROSS_RATES_CURSOR INTO @iso1, @iso2, @items
  END;

  SELECT * FROM #T

  DROP TABLE #T
GO
