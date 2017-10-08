SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_CROSS_RATE]
	@rate_politics_id int = NULL,
	@iso1 TISO,
	@iso2 TISO,
	@look_buy bit,
	@amount money OUTPUT,
	@items int OUTPUT,
	@reverse bit OUTPUT,
	@rate_type tinyint = 0
AS

SET @amount = $0.0000
SET @items = 1
SET @reverse = 0

IF @iso1 = @iso2
BEGIN
	SET @amount = $1.0000
	RETURN 0
END

CREATE TABLE #T (ISO1 char(3) collate database_default, ISO2 char(3) collate database_default, ITEMS int, AMOUNT_BUY money, AMOUNT_SELL money)
INSERT INTO #T (ISO1, ISO2, ITEMS, AMOUNT_BUY, AMOUNT_SELL)
EXEC dbo.GET_CUSTOM_RATES @rate_politics_id, @rate_type

-- Try exact match
SELECT @amount = CASE WHEN @look_buy = 1 THEN AMOUNT_BUY ELSE AMOUNT_SELL END,
       @items = ITEMS
FROM #T
WHERE ISO1 = @iso1 AND ISO2 = @iso2

IF ISNULL(@amount,0) > 0 RETURN (0)

-- Try reverse match
SELECT @amount = CASE WHEN @look_buy = 0 THEN AMOUNT_BUY ELSE AMOUNT_SELL END,
       @items = ITEMS
FROM #T
WHERE ISO1 = @iso2 AND ISO2 = @iso1
SET @reverse = 1

DROP TABLE #T
GO
