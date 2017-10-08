SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[user_smart_card_unregister]
	@user_id int,
	@saved_group_id int = NULL OUTPUT
AS

SET NOCOUNT ON;

DECLARE 
	@group_id int

BEGIN TRAN

SELECT @group_id = GROUP_ID, @saved_group_id = SAVED_GROUP_ID
FROM dbo.USERS
WHERE [USER_ID] = @user_id

IF @group_id < 0
BEGIN
	UPDATE dbo.USERS
	SET GROUP_ID = @saved_group_id, SAVED_GROUP_ID = NULL
	WHERE [USER_ID] = @user_id

	DELETE FROM dbo.OPS_SETS WHERE SET_ID = @group_id
	DELETE FROM dbo.ACC_SETS WHERE SET_ID = @group_id
	DELETE FROM dbo.CLI_SETS WHERE SET_ID = @group_id
	DELETE FROM dbo.GROUPS WHERE GROUP_ID = @group_id
END

COMMIT
GO
