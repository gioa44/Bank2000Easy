SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[WBC_UFC_ADD_TREASURY]
  @ref_id int OUTPUT,
  @bc_client_id int,
  @bc_login_id int,
  @ccard_id varchar(20),
  @saxazkod varchar(9),
  @amount TAMOUNT,
  @descrip varchar(150),
  @lat bit = 0,
  @message varchar(255) OUTPUT
AS


INSERT INTO dbo.WBC_UFC_OPERATIONS(CARD_ID, OP_TYPE, AMOUNT, ISO, DESCRIP, RECEIVER_ACC)
VALUES (@ccard_id, 4, @amount, 'GEL', @descrip, @saxazkod)

SET @ref_id = SCOPE_IDENTITY()

EXEC dbo.WBC_UFC_MSG_FOR_TREASURY @message OUTPUT, @bc_client_id, @bc_login_id, @lat

DECLARE @log_message varchar(255)
SET @log_message ='Transfer (UFC), Ref Id: ' + CAST(@ref_id AS varchar(50))
EXEC dbo.WBC_ADD_LOG @bc_login_id,6,@log_message
GO
