SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[WBC_UFC_ADD_CHARGE]
  @ref_id int OUTPUT,
  @bc_client_id int,
  @bc_login_id int,
  @ccard_id varchar(20),
  @charger_id int,
  @charge_id int,
  @id varchar(100),
  @amount TAMOUNT,
  @lat bit = 0,
  @message varchar(255) OUTPUT,
  @terminal_id varchar(30) OUTPUT
AS

SELECT @terminal_id = TERM_ID
FROM dbo.WBC_CHARGER_CHARGES
WHERE CHARGER_ID = @charger_id AND CHARGE_ID = @charge_id

INSERT INTO dbo.WBC_UFC_OPERATIONS(CARD_ID, OP_TYPE, AMOUNT, DESCRIP, CHARGER_ID, CHARGE_ID)
VALUES (@ccard_id, 2, @amount, @id, @charger_id, @charge_id)

SET @ref_id = SCOPE_IDENTITY()

SET @message = ''

DECLARE @log_message varchar(255)
SET @log_message ='Bill payments (UFC), Ref Id: ' + CAST(@ref_id AS varchar(50))
EXEC dbo.WBC_ADD_LOG @bc_login_id,10,@log_message
GO
