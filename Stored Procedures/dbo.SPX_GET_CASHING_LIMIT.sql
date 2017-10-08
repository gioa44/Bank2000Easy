SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[SPX_GET_CASHING_LIMIT]
  @iso TISO
AS
BEGIN
  SET NOCOUNT ON

  DECLARE
    @sys_time smalldatetime,
    @iso_equ TISO,
    @amount TAMOUNT

  SET @amount = NULL
  SET @sys_time = GETDATE()

  SELECT 
    @iso_equ = ISO_EQU, @amount = AMOUNT
  FROM dbo.CASHING_LIMIT
  WHERE ISO=@iso    


  IF @amount IS NOT NULL AND @iso_equ IS NOT NULL
    EXEC dbo.GET_CROSS_AMOUNT @iso1=@iso_equ, @iso2=@iso, @amount=@amount, @dt=@sys_time, @new_amount=@amount OUTPUT 
  
  SELECT ISNULL(@amount, -1)
  
  RETURN (0) 
END
GO
