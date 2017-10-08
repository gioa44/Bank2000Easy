SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[user_branch_id](@user_id int)
RETURNS int
AS
BEGIN
	DECLARE @dept_no int
	
	SELECT @dept_no = DEPT_NO 
	FROM dbo.USERS (NOLOCK) 
	WHERE [USER_ID] = @user_id

	SET @dept_no = dbo.dept_branch_id(@dept_no)
	RETURN @dept_no
END
GO
