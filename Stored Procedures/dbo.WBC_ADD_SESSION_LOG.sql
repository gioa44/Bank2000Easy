SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[WBC_ADD_SESSION_LOG] 
  @bc_client_id int,
  @bc_login_id int,
  @ip varchar(20),
  @session_id int OUTPUT
AS

SET NOCOUNT ON

INSERT INTO dbo.WBC_SESSIONS (BC_CLIENT_ID,BC_LOGIN_ID, DT_START, IP)
VALUES (@bc_client_id,@bc_login_id, GETDATE(), @ip)

SET @session_id = SCOPE_IDENTITY()
RETURN (0)
GO
