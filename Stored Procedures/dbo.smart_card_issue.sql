SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[smart_card_issue]
	@client_id int,
	@serial_no varchar(100),
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

UPDATE dbo.CLIENTS
SET SMART_CARD_NO = @serial_no 
WHERE CLIENT_NO = @client_id
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK; RETURN 1; END 

INSERT INTO dbo.CLI_CHANGES (CLIENT_NO, [USER_ID], DESCRIP)
VALUES (@client_id, @user_id, 'ÓÌÀÒÔ ÁÀÒÀÈÉÓ ÂÄÍÄÒÀÝÉÀ')
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK; RETURN 1; END 

COMMIT
GO
