SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[sys_has_right](@user_id int, @task_id int, @right_id tinyint) 
RETURNS bit
AS
BEGIN
	DECLARE @group_id int

	SELECT @group_id = GROUP_ID
	FROM dbo.USERS (NOLOCK)
	WHERE [USER_ID] = @user_id

	RETURN dbo.sys_group_has_right(@group_id, @task_id, @right_id)
END
GO
