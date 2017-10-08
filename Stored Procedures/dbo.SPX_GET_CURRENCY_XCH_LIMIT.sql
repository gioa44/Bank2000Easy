SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SPX_GET_CURRENCY_XCH_LIMIT]
  @iso TISO
AS
BEGIN
  SET NOCOUNT ON

  DECLARE
    @sys_time smalldatetime,
    @limit_time_h int,
    @limit_time_m int,
    @iso_equ TISO,
    @amount TAMOUNT

  SET @amount = NULL

  SET @sys_time = GETDATE()
  SELECT @limit_time_h = DATEPART(hh, @sys_time), @limit_time_m = DATEPART(mi, @sys_time)

  SELECT 
    @iso_equ = 
    CASE 
      WHEN NOT ((@limit_time_h > DATEPART(hh, LIMIT_TIME)) OR ((@limit_time_h = DATEPART(hh, LIMIT_TIME) AND @limit_time_m >= DATEPART(mi, LIMIT_TIME))))
      THEN ISO_EQU
      ELSE ISO_EQU2
    END,
    @amount =
    CASE 
      WHEN (LIMIT_TIME IS NULL) OR NOT ((@limit_time_h > DATEPART(hh, LIMIT_TIME)) OR ((@limit_time_h = DATEPART(hh, LIMIT_TIME) AND @limit_time_m >= DATEPART(mi, LIMIT_TIME))))
      THEN AMOUNT
      ELSE AMOUNT2
    END
  FROM dbo.CURRENCY_XCH_LIMIT
  WHERE ISO=@iso    


  IF @amount IS NOT NULL AND @iso_equ IS NOT NULL
    EXEC dbo.GET_CROSS_AMOUNT @iso1=@iso_equ, @iso2=@iso, @amount=@amount, @dt=@sys_time, @new_amount=@amount OUTPUT 
  
  SELECT ISNULL(@amount, -1)
  
  RETURN (0) 
END
GO
