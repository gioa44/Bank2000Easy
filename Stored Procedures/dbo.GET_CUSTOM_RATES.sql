SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- @rate_type
-- 0 - Non Cash Exchange
-- 1 - Cash Exchange
-- 2 - Non Cash Exchange Bank-Client
-- 4 - Non Cash Exchange Internet Banking

CREATE PROCEDURE [dbo].[GET_CUSTOM_RATES] (@rate_politics_id int, @rate_type tinyint = 0)
AS

SET NOCOUNT ON

CREATE TABLE #T (ISO1 char(3) collate database_default, ISO2 char(3) collate database_default, ITEMS int, AMOUNT_BUY money, AMOUNT_SELL money)

DECLARE 
  @formula varchar(4000)

IF @rate_politics_id IS NOT NULL
BEGIN
  SELECT @formula = FORMULA
  FROM dbo.RATE_POLITICS (NOLOCK)
  WHERE REC_ID = @rate_politics_id

  IF @formula IS NOT NULL
  BEGIN
    SET @formula = 
       'DECLARE @rate_type tinyint' + CHAR(13) +
       'SET @rate_type = ' + CONVERT(varchar(20), @rate_type) + CHAR(13) +
        @formula

    INSERT INTO #T (ISO1, ISO2, ITEMS, AMOUNT_BUY, AMOUNT_SELL)
    EXEC sp_sqlexec @formula
  END
END

IF @rate_type = 1
  INSERT INTO #T
  SELECT A.* 
  FROM dbo.CROSS_RATES_KAS A 
    LEFT OUTER JOIN #T T ON T.ISO1 = A.ISO1 AND T.ISO2 = A.ISO2 OR T.ISO1 = A.ISO2 AND T.ISO2 = A.ISO1
  WHERE T.ISO1 IS NULL
ELSE
  INSERT INTO #T
  SELECT A.* 
  FROM dbo.CROSS_RATES A 
    LEFT OUTER JOIN #T T ON T.ISO1 = A.ISO1 AND T.ISO2 = A.ISO2 OR T.ISO1 = A.ISO2 AND T.ISO2 = A.ISO1
  WHERE T.ISO1 IS NULL


SELECT * 
FROM #T

DROP TABLE #T
GO
