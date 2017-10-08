SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[WBC_ADD_MESSAGE]
 @rec_id int OUTPUT,
 @message varchar(512) OUTPUT,
 @bc_client_id int,
 @bc_login_id int,
 @lat bit,
 @doc_date smalldatetime,
 @text  text,
 @message_type varchar(50) = null,
 @dt smalldatetime = null
AS
  SET NOCOUNT ON

  SET @message = ''
 
  INSERT INTO BC_MSGS (DOC_DATE,DESCRIP,[TEXT],BC_LOGIN_ID,REC_STATE,MSG_TYPE)
  VALUES(@doc_date, 'WBC: ' + @message_type, @text, @bc_login_id, 0, -1 )

  SET @rec_id = SCOPE_IDENTITY()

  IF @message_type = 'ÓÄÓáÉÓ ÃÀ×ÀÒÅÉÓ ÛÄÔÚÏÁÉÍÄÁÀ'
  BEGIN
    DECLARE @today smalldatetime, @deadline smalldatetime

    SET @doc_date = convert(smalldatetime,floor(convert(real,@doc_date)))
    SET @today = convert(smalldatetime,floor(convert(real,getdate())))

    DECLARE @date_changed bit
    SET @date_changed = 0

    EXEC dbo.WBC_GET_DOC_DATE @doc_date OUTPUT, @date_changed OUTPUT

    IF @lat <> 0
         SET @message = 'Loan repayment assignment message has been sent to the bank.<BR>'
    ELSE SET @message = 'ÓÄÓáÉÓ ÃÀ×ÀÒÅÉÓ ÛÄÓÀáÄÁ ÈØÅÄÍÉ ÛÄÔÚÏÁÉÍÄÁÀ ÂÀÉÂÆÀÅÍÀ ÁÀÍÊÛÉ.<BR>'

    IF @doc_date = @today
    BEGIN
      IF @lat <> 0
           SET @message = @message + 'The Bank will carry out your assignement today (if working day) not later than 18:00 pm (*).<BR>'
      ELSE SET @message = @message + 'ÈØÅÄÍÓ ÃÀÅÀËÄÁÀÓ ÁÀÍÊÉ ÛÄÀÓÒÖËÄÁÓ ÃÙÄÅÀÍÃÄËÉ ÃÙÉÓ (ÈÖ ÓÀÌÖÛÀÏ ÃÙÄÀ) 18:00 ÓÀÀÈÀÌÃÄ (*).<BR>'
    END
    ELSE
    BEGIN
      IF @lat <> 0
           SET @message = @message + 'The Bank will carry out your assignement the next working day not later than 12:00 pm (*).<BR>'
      ELSE SET @message = @message + 'ÈØÅÄÍÓ ÃÀÅÀËÄÁÀÓ ÁÀÍÊÉ ÛÄÀÓÒÖËÄÁÓ ÌÏÌÃÄÅÍÏ ÓÀÌÖÛÀÏ ÃÙÄÓ 12:00 ÓÀÀÈÀÌÃÄ (*).<BR>'
    END

    IF @lat <> 0
         SET @message = @message + 'The amount will be directed to cover accrued interest, loan principal and other payments considered in the Credit Agreement.<BR><BR><BR><BR>(*) Georgian local time'
    ELSE SET @message = @message + 'ÈÀÍáÀ ÂÀÃÀÍÀßÉËÃÄÁÀ ÃÀÒÉÝáÖË ÐÒÏÝÄÍÔÓ, ÓÄÓáÉÓ ÞÉÒÉÈÀÃ ÈÀÍáÀÓ ÃÀ ÓÀÊÒÄÃÉÔÏ áÄËÛÄÊÒÖËÄÁÉÈ ÂÀÈÅÀËÉÓßÉÍÄÁÖË ÓáÅÀ ÂÀÃÀÓÀáÃÄËÄÁÓ ÛÏÒÉÓ.<BR><BR><BR><BR>(*) ÈÁÉËÉÓÉÓ ÃÒÏÉÈ'
  END
  ELSE
  IF @message_type = 'ÀÍÀÁÒÉÓ ÛÄßÚÅÄÔÉÓ ÌÏÈáÏÅÍÀ'
  BEGIN
    IF @lat <> 0
      SET @message = 'Deposit termination message has been sent to the bank.'
    ELSE
      SET @message = 'ÁÀÍÊÓ ÂÀÄÂÆÀÅÍÀ ÔÄØÓÔÖÒÉ ÛÄÔÚÏÁÉÍÄÁÀ ÀÍÀÁÒÉÓ ÛÄßÚÅÄÔÉÓ ÛÄÓÀáÄÁ.'
  END 
  ELSE
  IF @message_type = 'ÀÍÀÁÒÉÓ ÂÀáÓÍÉÓ ÌÏÈáÏÅÍÀ'
  BEGIN
    IF @lat <> 0
      SET @message = 'Deposit opening message has been sent to the bank.'
    ELSE
      SET @message = 'ÁÀÍÊÓ ÂÀÄÂÆÀÅÍÀ ÔÄØÓÔÖÒÉ ÛÄÔÚÏÁÉÍÄÁÀ ÀÍÀÁÒÉÓ ÂÀáÓÍÉÓ ÛÄÓÀáÄÁ.'
  END 
  ELSE
  BEGIN
    IF @lat <> 0
      SET @message = 'Message has been sent to the bank.'
    ELSE
      SET @message = 'ÁÀÍÊÓ ÂÀÄÂÆÀÅÍÀ ÔÄØÓÔÖÒÉ ÛÄÔÚÏÁÉÍÄÁÀ.'
  END


  DECLARE @log_message varchar(255)
  SET @log_message ='Message, Id: ' + CAST(@rec_id AS varchar(50))
  EXEC dbo.WBC_ADD_LOG @bc_login_id,11,@log_message
  
  
  EXEC dbo.WBC_SEND_B2000MSG @bc_client_id, @bc_login_id, @message_type

  RETURN (0)
GO
