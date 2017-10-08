SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[BCC_EXP_VAL_RATES]
  @dt smalldatetime = 0,
  @for_branch bit = 0
AS
 
SET NOCOUNT ON
 
IF @for_branch = 1
BEGIN
	SELECT R.* 
	FROM dbo.VAL_RATES R (NOLOCK)
		INNER JOIN dbo.VAL_CODES C (NOLOCK) ON C.ISO = R.ISO
	WHERE C.IS_DISABLED = 0 AND R.DT >= ISNULL(@dt,0)

	RETURN 0
END
 
DECLARE @rates TABLE (ISO char(3), DT smalldatetime, ITEMS int, AMOUNT money, PRIMARY KEY (ISO, DT))
 
INSERT INTO @rates
SELECT R.* 
FROM dbo.VAL_RATES R (NOLOCK)
	INNER JOIN dbo.VAL_CODES C (NOLOCK) ON C.ISO = R.ISO
WHERE C.IS_DISABLED = 0 AND R.DT >= ISNULL(@dt,0)
 
DECLARE 
	@items int,
	@amount money,
	@iso TISO,
	@max_dt smalldatetime,
	@start_date smalldatetime

SET @start_date = @dt
 
SELECT @max_dt = MAX(DT)
FROM @rates
 
DECLARE cc CURSOR FAST_FORWARD LOCAL
FOR
SELECT ISO FROM dbo.VAL_CODES (NOLOCK) 
WHERE IS_DISABLED = 0
 
OPEN cc
FETCH NEXT FROM cc INTO @iso
 
WHILE @@FETCH_STATUS = 0
BEGIN
 SELECT @dt = MIN(DT)
 FROM @rates
 WHERE ISO = @iso AND DT >= @start_date
 
 IF @dt IS NULL
 BEGIN
  SELECT @dt = MAX(DT)
  FROM dbo.VAL_RATES (NOLOCK)
  WHERE ISO = @iso AND DT < @start_date
 
  SELECT @items = ITEMS, @amount = AMOUNT
  FROM dbo.VAL_RATES (NOLOCK)
  WHERE ISO = @iso AND DT = @dt
 END
 ELSE
 BEGIN
  SELECT @items = ITEMS, @amount = AMOUNT
  FROM @rates
  WHERE ISO = @iso AND DT = @dt
 END
 
 IF @dt IS NOT NULL
 BEGIN
  IF @dt < @start_date
   SET @dt = @start_date
 
  WHILE @dt <= @max_dt
  BEGIN
   IF NOT EXISTS(SELECT * FROM @rates WHERE ISO = @iso AND DT = @dt)
    INSERT INTO @rates VALUES (@iso, @dt, @items, @amount)
   ELSE
    SELECT @items = ITEMS, @amount = AMOUNT
    FROM @rates
    WHERE ISO = @iso AND DT = @dt
 
   SET @dt = @dt + 1
  END
 END
 
 FETCH NEXT FROM cc INTO @iso
END
 
SELECT * FROM @rates
GO
