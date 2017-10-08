SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[user_group_id](@user_id int)
RETURNS int
AS
BEGIN
	DECLARE @group_id int
	
	SELECT @group_id = GROUP_ID
	FROM dbo.USERS (NOLOCK) 
	WHERE [USER_ID] = @user_id

	RETURN @group_id
END
GO
