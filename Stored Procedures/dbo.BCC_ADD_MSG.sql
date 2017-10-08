SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Stored procedure
CREATE PROCEDURE [dbo].[BCC_ADD_MSG]
  @rec_id int OUTPUT,
  @bc_login_id int,
  @dt smalldatetime = null,
  @descrip varchar(50),
  @text text = null,
  @data image = null,
  @rec_state tinyint,
  @msg_type int,
  @filename varchar(100) = null
AS

DECLARE @now datetime
SET @now = getdate()

INSERT INTO dbo.BC_MSGS(DOC_DATE,DESCRIP,[TEXT],DATA,BC_LOGIN_ID,REC_STATE,MSG_TYPE,[FILENAME])
VALUES(@now,@descrip,@text,@data,@bc_login_id,@rec_state,@msg_type,@filename)
IF @@ERROR<>0 BEGIN SET @rec_id = 0 RETURN (1) END

SELECT @rec_id = SCOPE_IDENTITY()
IF @@ERROR<>0 RETURN (2)
RETURN (0)
GO
