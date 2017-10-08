SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_CHECK_RECV_ACC]
  @acc_id int,
  @acc TACCOUNT,
  @iso TISO,
  @acc_name varchar(100) OUTPUT,
  @tax_code varchar(11) OUTPUT,
  @lat bit = 0,
  @is_val bit = 0
AS

SET NOCOUNT ON

DECLARE @acc_str varchar(34)
SET @acc_str = convert(varchar(30),@acc) + '/' + @iso

DECLARE
  @acc_rec_state tinyint,
  @acc_flags int,
  @client_id int
 
SET @tax_code = NULL

SELECT @acc_rec_state = REC_STATE, @acc_flags = FLAGS, @acc_name = CASE WHEN @is_val = 0 THEN DESCRIP ELSE DESCRIP_LAT END, @client_id = CLIENT_NO
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

IF @@ROWCOUNT = 0 OR @acc_rec_state IS NULL OR @acc_flags IS NULL
BEGIN
  IF @lat = 0 
       RAISERROR('<ERR>ÀÍÂÀÒÉÛÉ %s ÀÒ ÌÏÉÞÄÁÍÀ</ERR>',16,1,@acc_str)
  ELSE RAISERROR('<ERR>Account %s not found</ERR>',16,1,@acc_str);
  RETURN (3)
END

IF @client_id IS NOT NULL
  SELECT @tax_code = CONVERT(varchar(11), TAX_INSP_CODE)
  FROM dbo.CLIENTS (NOLOCK)
  WHERE CLIENT_NO = @client_id

IF @acc_rec_state = 64
BEGIN
  IF @lat = 0
       RAISERROR('<ERR>ÀÍÂÀÒÉÛÉ %s ÃÀÒÄÆÄÒÅÄÁÖËÉÀ, ÂÀÔÀÒÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ.</ERR>',16,1,@acc_str)
  ELSE RAISERROR('<ERR>Account %s is reserved, no entry is possible.</ERR>',16,1,@acc_str)
  RETURN (4)
END
ELSE
IF @acc_rec_state = 2
BEGIN
  IF @lat = 0
       RAISERROR('<ERR>ÀÍÂÀÒÉÛÉ %s ÃÀáÖÒÖËÉÀ, ÂÀÔÀÒÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ.</ERR>',16,1,@acc_str)
  ELSE RAISERROR('<ERR>Account %s is closed, no entry is possible.</ERR>',16,1,@acc_str)
  RETURN (5)
END
IF @acc_rec_state = 16
BEGIN
  IF @lat = 0
       RAISERROR('<ERR>ÀÍÂÀÒÉÛÉ %s ÂÀÚÉÍÖËÉÀ, ÂÀÔÀÒÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ.</ERR>',16,1,@acc_str)
  ELSE RAISERROR('<ERR>Account %s is frozen, no entry is possible.</ERR>',16,1,@acc_str)
  RETURN (8)
END
IF @acc_rec_state = 128
BEGIN
  IF @lat = 0
       RAISERROR('<ERR>ÀÍÂÀÒÉÛÉ %s ÀÒ ÌÏÉÞÄÁÍÀ ÁÀÍÊÉÓ ÀÍÂÀÒÉÛÈÀ ÓÉÀÛÉ.</ERR>',16,1,@acc_str)
  ELSE RAISERROR('<ERR>Account %s is removed, no entry is possible.</ERR>',16,1,@acc_str)
  RETURN (9)
END
ELSE
IF NOT @acc_rec_state in (1,4,8,32)
BEGIN
  IF @lat = 0
       RAISERROR('<ERR>%s ÀÍÂÀÒÉÛÉÓ ÓÔÀÔÖÓÉ ÖÝÍÏÁÉÀ, ÂÀÔÀÒÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ. ÌÉÌÀÒÈÄÈ ÁÀÍÊ-ÊËÉÄÍÔÉÓ ÀÃÌÉÍÉÓÔÒÀÔÏÒÓ.</ERR>',16,1,@acc_str)
  ELSE RAISERROR('<ERR>Status of account %s is unknown. Please inform Wen Bank-Client 2000 administrator.</ERR>',16,1,@acc_str)
  RETURN (9)
END

RETURN (0)
GO
