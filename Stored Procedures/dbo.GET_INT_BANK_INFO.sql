SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[GET_INT_BANK_INFO]
	@bank_code TINTBANKCODE,
	@iso TISO,
	@bank_name varchar(50)  OUTPUT,
	@rec_state tinyint	OUTPUT,
	@info varchar(255) OUTPUT
AS

SET NOCOUNT ON

SELECT  @rec_state = 0, @bank_name = '', @info = ''

SELECT @bank_name = DESCRIP, @rec_state = REC_STATE
FROM dbo.BIC_CODES (NOLOCK)
WHERE BIC = @bank_code

IF @@ROWCOUNT > 0 RETURN (0)

IF DATALENGTH(@bank_code) = 8
  SELECT @bank_name = DESCRIP, @rec_state = REC_STATE
  FROM dbo.BIC_CODES (NOLOCK)
  WHERE BIC = @bank_code + 'XXX'

IF @@ROWCOUNT > 0 RETURN (0)

SET @info = 'ÁÀÍÊÉ ÀÒ ÌÏÉÞÄÁÍÀ'
RETURN (1)
GO
