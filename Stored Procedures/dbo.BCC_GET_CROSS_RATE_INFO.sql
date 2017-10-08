SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_GET_CROSS_RATE_INFO]
  @bc_client_id int = null,
  @iso1		TISO,
  @iso2		TISO,
  @nbg	 	bit,
  @amount 	TAMOUNT 	OUTPUT,
  @items  	int 		OUTPUT,
  @reverse	bit		OUTPUT,
  @dt 		smalldatetime = null
AS

SET NOCOUNT ON

SET @amount = 0
SET @items = 1
SET @reverse = 0

IF @iso1 = @iso2  RETURN (0)

DECLARE @items1 int, @items2 int, @amount1 TAMOUNT, @amount2 TAMOUNT

IF @nbg = 1
BEGIN
  IF @dt IS NULL 
    SET @dt = convert(smalldatetime,floor(convert(real,getdate())))

  IF @iso1 <> 'GEL'
    SELECT @amount1 = AMOUNT, @items1 = ITEMS
    FROM dbo.VAL_RATES (NOLOCK)
    WHERE ISO = @iso1 and DT = (SELECT MAX(DT) FROM VAL_RATES(NOLOCK) WHERE ISO = @iso1 and DT <= @dt)
  ELSE
    SELECT @amount1 = 1, @items1 = 1

  IF @iso2 <> 'GEL'
    SELECT @amount2 = AMOUNT, @items2 = ITEMS
    FROM dbo.VAL_RATES (NOLOCK)
    WHERE ISO = @iso2 and DT = (SELECT MAX(DT) FROM VAL_RATES(NOLOCK) WHERE ISO = @iso2 and DT <= @dt)
  ELSE
    SELECT @amount2 = 1, @items2 = 1

  IF (@items2 > @items1) OR ((@items2 = @items1) AND (@amount2 > @amount1))
  BEGIN
    SET @items = @items2 / @items1
    SET @amount = @amount2 * @items * @items1 * 1.0 / (@items2 * @amount1)
    SET @reverse = 1
  END
  ELSE
  BEGIN
    SET @items = @items1 / @items2
    SET @amount = @amount1 * @items * @items2 * 1.0 / (@items1 * @amount2)
    SET @reverse = 0
  END

  RETURN (0)
END

DECLARE 
  @rate_politics_id int,
  @main_client_id int

SET @main_client_id    = NULL
SET @rate_politics_id  = NULL

SELECT @main_client_id = MAIN_CLIENT_ID
FROM dbo.BC_CLIENTS (NOLOCK)
WHERE BC_CLIENT_ID = @bc_client_id 

IF @main_client_id IS NOT NULL
  SELECT @rate_politics_id = RATE_POLITICS_ID
  FROM dbo.CLIENTS (NOLOCK)
  WHERE CLIENT_NO = @main_client_id

EXEC dbo.GET_CROSS_RATE @rate_politics_id, @iso1, @iso2, 1, @amount OUTPUT, @items OUTPUT, @reverse OUTPUT, 2 -- Bank-Client
IF ISNULL(@amount,0) > 0 RETURN (0)

-- if not succesful, try to convert via GEL
IF (@iso1 = 'GEL') OR (@iso2 = 'GEL') RETURN (0)

DECLARE @reverse1 bit, @reverse2 bit

SET @items1 = 1
SET @items2 = 1
SET @amount1 = 0
SET @amount2 = 0
SET @reverse1 = 0
SET @reverse2 = 0

EXEC dbo.GET_CROSS_RATE  @rate_politics_id, @iso1, 'GEL', 1, @amount1 OUTPUT, @items1 OUTPUT, @reverse1 OUTPUT, 2 -- Bank-Client
IF ISNULL(@amount1,0) > 0
  EXEC dbo.GET_CROSS_RATE  @rate_politics_id, @iso2, 'GEL', 0, @amount2 OUTPUT, @items2 OUTPUT, @reverse2 OUTPUT, 2 -- Bank-Client

IF ISNULL(@amount1,0) <= 0 OR ISNULL(@amount2,0) <= 0 RETURN (0)

IF @items2 > @items1
BEGIN
  SET @items = @items2 / @items2

  IF @reverse1 = 0 and @reverse2 = 0 
    SET @amount = @amount2 * @items * @items1 / (@items2 * @amount1)
  ELSE
  IF @reverse1 = 0 and @reverse2 <> 0 
    SET @amount = @items * @items1 * 1.0 / (@items2 * @amount1 * @amount2)
  ELSE
  IF @reverse1 <> 0 and @reverse2 = 0 
    SET @amount =  @amount1 * @amount2 * @items * @items1 * 1.0/ (@items2)
  ELSE
  IF @reverse1 <> 0 and @reverse2 <> 0 
    SET @amount =  @amount1 * @items * @items2 * 1.0 / (@items1 * @amount2);

  SET @reverse = 1
END
ELSE
BEGIN
  SET @items = @items1 / @items2

  IF @reverse1 = 0 and @reverse2 = 0 
    SET @amount = @amount1 * @items * @items2 * 1.0 / (@items1 * @amount2)
  ELSE
  IF @reverse1 = 0 and @reverse2 <> 0 
    SET @amount = @items * @items2 * 1.0 / (@items1 * @amount2 * @amount1)
  ELSE
  IF @reverse1 <> 0 and @reverse2 = 0 
    SET @amount =  @amount2 * @amount1 * @items * @items2 * 1.0 / (@items1)
  ELSE
  IF @reverse1 <> 0 and @reverse2 <> 0 
     SET @amount =  @amount2 * @items * @items1 * 1.0 / (@items2 * @amount1);

  SET @reverse = 0
END

RETURN (0)
GO
