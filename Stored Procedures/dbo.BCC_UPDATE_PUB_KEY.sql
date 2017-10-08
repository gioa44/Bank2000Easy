SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[BCC_UPDATE_PUB_KEY]
  @bc_login_id int,
  @pub_key text
AS

SET NOCOUNT ON

DECLARE @r int,@e int

UPDATE BC_LOGINS
SET PUB_KEY = @pub_key
WHERE BC_LOGIN_ID = @bc_login_id

SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e<>0 BEGIN ROLLBACK RETURN END
IF @r=0 BEGIN ROLLBACK RAISERROR ('<ERR>ÊËÉÄÍÔÉÓ ÛÄÓÀÁÀÌÉÓÉ ÜÀÍÀßÄÒÉ ÀÒ ÌÏÉÞÄÁÍÀ. ÌÉÌÀÒÈÄÈ ÁÀÍÊ-ÊËÉÄÍÔÉÓ ÀÃÌÉÍÉÓÔÒÀÔÏÒÓ</ERR>',16,1) RETURN END


GO
