SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[BCC_GET_PUB_KEY]
  @bc_login_id	int
AS

SET NOCOUNT ON

SELECT PUB_KEY
FROM dbo.BC_LOGINS
WHERE BC_LOGIN_ID = @bc_login_id


GO