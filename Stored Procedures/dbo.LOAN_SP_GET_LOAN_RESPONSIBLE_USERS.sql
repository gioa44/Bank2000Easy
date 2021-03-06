SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOAN_RESPONSIBLE_USERS]
	@user_id int = NULL,
	@dept_no int = NULL
AS
SET NOCOUNT ON

	SELECT USER_ID, USER_NAME, USER_FULL_NAME
	FROM dbo.USERS (NOLOCK)
	WHERE ((@user_id IS NOT NULL AND USER_ID = @user_id) OR (@user_id IS NULL AND IS_LOAN_OFFICER = 1)) AND
		(@dept_no IS NULL OR DEPT_NO = @dept_no) AND USER_DEL_FLAG = 0

	RETURN
GO
