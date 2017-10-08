SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_SWIFT_DOCS] 
  @user_id int /* who is adding the document */,
  @doc_date smalldatetime,
  @rec_state smallint,
  @lat bit = 0
AS

SET NOCOUNT ON

DECLARE 
  @dt_open smalldatetime,
  @today smalldatetime
 
SET @today = convert(smalldatetime,floor(convert(real,getdate())))
EXEC dbo.GET_OPEN_BANK_DATE @dt_open OUTPUT

IF @doc_date < @dt_open
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÞÅÄËÉ ÈÀÒÉÙÉÈ ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot add documets with an old date</ERR>',16,1)
  RETURN (3)
END

DECLARE 
  @op_num int,
  @ret_code int

BEGIN TRAN

DECLARE cur CURSOR
FOR
SELECT OP_NUM
FROM dbo.SWIFT_DOCS

OPEN cur
IF @@ERROR <> 0 GOTO ROLLBACK_TRAN

FETCH NEXT FROM cur INTO @op_num
IF @@ERROR <> 0 GOTO ROLLBACK_TRAN

WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC @ret_code = dbo.ADD_SWIFT_DOC @op_num, @user_id, @doc_date, @lat, @rec_state
  IF @@ERROR <> 0 OR @ret_code <> 0 GOTO ROLLBACK_TRAN

  FETCH NEXT FROM cur INTO @op_num
  IF @@ERROR <> 0 GOTO ROLLBACK_TRAN
END

IF @@FETCH_STATUS <> -1
BEGIN
  RAISERROR ('FETCH STATUS ERROR',16,1)
  GOTO ROLLBACK_TRAN
END

CLOSE cur
DEALLOCATE cur
COMMIT
RETURN 0

ROLLBACK_TRAN:
ROLLBACK
CLOSE cur
DEALLOCATE cur
RETURN 1
GO
