SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[GET_GEO_BANK_INFO]
	@bank_code varchar(9),
	@iso TISO,
	@bank_code9 TGEOBANKCODE OUTPUT,
	@bank_name varchar(50)  OUTPUT,
	@rec_state tinyint	OUTPUT,
	@info varchar(255) OUTPUT
AS

SET NOCOUNT ON

SELECT  @rec_state = 0, @bank_name = '', @info = '', @bank_code9 = 0

IF DATALENGTH(@bank_code) = 3			
BEGIN
  SELECT TOP 1
	@bank_name  = DESCRIP,
	@bank_code9 = CODE9,
	@rec_state  = REC_STATE
  FROM dbo.BANKS (NOLOCK)
  WHERE  CODE3 = @bank_code
END
ELSE
BEGIN
  SELECT @bank_name  = DESCRIP,
	@bank_code9 = CODE9,
	@rec_state  = REC_STATE  FROM dbo.BANKS (NOLOCK)
  WHERE CODE9 = CONVERT(int, @bank_code)
END

IF @@ROWCOUNT > 0 RETURN (0)SET @info = 'ÁÀÍÊÉ ÀÒ ÌÏÉÞÄÁÍÀ'
RETURN (1)
GO
