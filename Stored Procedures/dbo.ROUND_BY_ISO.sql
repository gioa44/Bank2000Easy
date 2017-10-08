SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ROUND_BY_ISO]
  @value   TAMOUNT,
  @iso	 TISO,
  @new_value TAMOUNT OUTPUT
AS

SET NOCOUNT ON

DECLARE @digits tinyint


SELECT @digits = DIGITS FROM VAL_CODES WHERE ISO=@iso

SET @digits = ISNULL(@digits,2)

SET @new_value = Round(@value,@digits)
IF @@ERROR <> 0 RETURN(1)
ELSE RETURN(0)


GO
