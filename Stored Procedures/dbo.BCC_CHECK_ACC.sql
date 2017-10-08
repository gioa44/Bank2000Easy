SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[BCC_CHECK_ACC]
  @bc_client_id int,
  @bc_login_id int, 
  @acc_id int,
  @lat bit = 0,
  @for_what varchar(10),
  @disable_flag int 
AS

SET NOCOUNT ON

DECLARE @acc_str varchar(34)
SET @acc_str = convert(varchar(30), dbo.acc_get_account(@acc_id))

DECLARE
  @acc_rec_state tinyint,
  @acc_flags int,
  @login_acc_flags int,
  @client_type tinyint

SELECT @client_type = CLIENT_TYPE
FROM dbo.BC_CLIENTS (NOLOCK)
WHERE BC_CLIENT_ID = @bc_client_id

IF @client_type = 0 /* bc client */
  SELECT @acc_rec_state = REC_STATE, @acc_flags = ACC_FLAGS, @login_acc_flags = LOGIN_ACC_FLAGS
  FROM dbo.BC_LOGIN_ACC_VIEW 
  WHERE BC_CLIENT_ID = @bc_client_id AND BC_LOGIN_ID = @bc_login_id AND ACC_ID = @acc_id
ELSE
IF @client_type = 2 /* branch */
  SELECT @acc_rec_state = REC_STATE, @acc_flags = FLAGS, @login_acc_flags = 0xFF
  FROM dbo.BCC_BRANCH_ACC_VIEW
  WHERE BC_CLIENT_ID = @bc_client_id AND ACC_ID = @acc_id

IF @@ROWCOUNT = 0 OR @acc_rec_state IS NULL OR @acc_flags IS NULL
BEGIN
  IF @lat = 0 
       RAISERROR('<ERR>ÀÍÂÀÒÉÛÉ %s ÀÒ ÌÏÉÞÄÁÍÀ ÀÍ ÀÒ ÀÒÉÓ ÈØÅÄÍÉ ÀÍÂÀÒÉÛÉ</ERR>',16,1,@acc_str)
  ELSE RAISERROR('<ERR>Account %s not found or don''t belong to you</ERR>',16,1,@acc_str);
  RETURN (3)
END

IF @for_what <> 'statement'
BEGIN
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
  IF @acc_rec_state = 4 AND @for_what in ('plat','debit','debit_conv')
  BEGIN
    IF @lat = 0
         RAISERROR('<ERR>ÀÍÂÀÒÉÛÆÄ %s ÛÄÉÞËÄÁÀ ÌáÏËÏÃ ÊÒÄÃÉÔÖËÉ ÂÀÔÀÒÄÁÄÁÉ.</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>Only credit transactions are allowed on the account %s.</ERR>',16,1,@acc_str)
    RETURN (6)
  END
  IF @acc_rec_state = 8
  BEGIN
    IF @lat = 0
         RAISERROR('<ERR>ÀÍÂÀÒÉÛÉÃÀÍ %s ÛÄÉÞËÄÁÀ ÌáÏËÏÃ ÓÀÁÉÖãÄÔÏ ÃÄÁÄÔÖÒÉ ÂÀÔÀÒÄÁÄÁÉ.</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>only budget debit transactions are allowed for the account %s.</ERR>',16,1,@acc_str)
    RETURN (7)
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
  IF NOT @acc_rec_state in (1,4,32)
  BEGIN
    IF @lat = 0
         RAISERROR('<ERR>%s ÀÍÂÀÒÉÛÉÓ ÓÔÀÔÖÓÉ ÖÝÍÏÁÉÀ, ÂÀÔÀÒÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ. ÌÉÌÀÒÈÄÈ ÁÀÍÊ-ÊËÉÄÍÔÉÓ ÀÃÌÉÍÉÓÔÒÀÔÏÒÓ.</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>Status of account %s is unknown. Please inform Wen Bank-Client 2000 administrator.</ERR>',16,1,@acc_str)
    RETURN (10)
  END

  IF @disable_flag <> 0 AND (@acc_flags & @disable_flag = 0)  /* internet or bc disabled */
  BEGIN
    IF @lat = 0 
         RAISERROR('<ERR>%s ÀÍÂÀÒÉÛÆÄ ÀÒ ÂÀØÅÈ Ö×ËÄÁÀ ÜÀÀÔÀÒÏÈ ÏÐÄÒÀÝÉÄÁÉ ÁÀÍÊ-ÊËÉÄÍÔ ÓÉÓÔÄÌÉÈ</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>You don''t have rights to make operations on account %s</ERR>',16,1,@acc_str);
    RETURN (11)
  END
END


IF (@for_what = 'debit') AND (@login_acc_flags & 2 = 0) /* debit ops disabled */
  BEGIN
    IF @lat = 0 
         RAISERROR('<ERR>%s ÀÍÂÀÒÉÛÉÃÀÍ ÀÒ ÂÀØÅÈ Ö×ËÄÁÀ ÂÀÀÊÄÈÏÈ ÃÄÁÄÔÖÒÉ ÏÐÄÒÀÝÉÄÁÉ ÁÀÍÊ-ÊËÉÄÍÔ ÓÉÓÔÄÌÉÈ</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>You don''t have rights to make debit operations from account %s</ERR>',16,1,@acc_str);
    RETURN (12)
  END

IF (@for_what = 'debit_conv') AND (@login_acc_flags & 16 = 0) /* debit conv disabled */
  BEGIN
    IF @lat = 0 
         RAISERROR('<ERR>%s ÀÍÂÀÒÉÛÉÃÀÍ ÀÒ ÂÀØÅÈ Ö×ËÄÁÀ ÂÀÀÊÄÈÏÈ ÃÄÁÄÔÖÒÉ ÊÏÍÅÄÒÔÀÝÉÄÁÉÓ ÏÐÄÒÀÝÉÄÁÉ ÁÀÍÊ-ÊËÉÄÍÔ ÓÉÓÔÄÌÉÈ</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>You don''t have rights to make debit conversion operations from account %s</ERR>',16,1,@acc_str);
    RETURN (12)
  END

IF (@for_what = 'credit') AND (@login_acc_flags & 4 = 0) /* credit ops disabled */
  BEGIN
    IF @lat = 0 
         RAISERROR('<ERR>%s ÀÍÂÀÒÉÛÉÃÀÍ ÀÒ ÂÀØÅÈ Ö×ËÄÁÀ ÂÀÀÊÄÈÏÈ ÊÒÄÃÉÔÖËÉ ÏÐÄÒÀÝÉÄÁÉ ÁÀÍÊ-ÊËÉÄÍÔ ÓÉÓÔÄÌÉÈ</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>You don''t have rights to make credit operations from account %s</ERR>',16,1,@acc_str);
    RETURN (14)
  END

IF (@for_what = 'credit_conv') AND (@login_acc_flags & 32 = 0) /* credit conv disabled */
  BEGIN
    IF @lat = 0 
         RAISERROR('<ERR>%s ÀÍÂÀÒÉÛÉÃÀÍ ÀÒ ÂÀØÅÈ Ö×ËÄÁÀ ÂÀÀÊÄÈÏÈ ÊÒÄÃÉÔÖËÉ ÊÏÍÅÄÒÔÀÝÉÄÁÉÓ ÏÐÄÒÀÝÉÄÁÉ ÁÀÍÊ-ÊËÉÄÍÔ ÓÉÓÔÄÌÉÈ</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>You don''t have rights to make credit conversion operations from account %s</ERR>',16,1,@acc_str);
    RETURN (14)
  END

IF (@for_what = 'plat') AND (@login_acc_flags & 8 = 0) /* plats disabled */
  BEGIN
    IF @lat = 0 
         RAISERROR('<ERR>%s ÀÍÂÀÒÉÛÉÃÀÍ ÀÒ ÂÀØÅÈ Ö×ËÄÁÀ ÂÀÃÀÒÉÝáÏÈ ÁÀÍÊ-ÊËÉÄÍÔ ÓÉÓÔÄÌÉÈ</ERR>',16,1,@acc_str)
    ELSE RAISERROR('<ERR>You don''t have rights to make transfers from account %s</ERR>',16,1,@acc_str);
    RETURN (15)
  END

RETURN (0)
GO
