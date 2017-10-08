SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[BCC_CHECK_USER]
	@bc_bid varchar(14),
	@bc_login varchar(12),
	@psw_hash char(32),
	@bc_client_id	int OUTPUT,
	@bc_login_id	int OUTPUT,
	@flags int OUTPUT,
	@flags2 int OUTPUT,
	@flags3 int OUTPUT,
	@client_type tinyint OUTPUT,
	@man_ps_names varchar(255) OUTPUT,
	@dept_no int OUTPUT,
	@descrip varchar(100) OUTPUT,
	@start_date smalldatetime = NULL OUTPUT
AS

SET NOCOUNT ON

SET @flags = 0
SET @bc_client_id = 0
SET @bc_login_id = 0

-- For compatibility with old BC2000SRV
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID ('dbo.BC_CLIENTS') AND name = 'START_DATE')
	SELECT @bc_client_id = BC_CLIENT_ID, @man_ps_names = MANAGER_PC_NAMES, 
		   @dept_no = BRANCH_ID, @client_type = CLIENT_TYPE, @start_date = [START_DATE]
	FROM dbo.BC_CLIENTS (NOLOCK)
	WHERE SUBSTRING(CONVERT(varchar(36),BC_BID),10,14) = @bc_bid AND (FLAGS & 1 <> 0) /* bc enabled */
ELSE
	SELECT @bc_client_id = BC_CLIENT_ID, @man_ps_names = MANAGER_PC_NAMES, 
		   @dept_no = BRANCH_ID, @client_type = CLIENT_TYPE, @start_date = NULL
	FROM dbo.BC_CLIENTS (NOLOCK)
	WHERE SUBSTRING(CONVERT(varchar(36),BC_BID),10,14) = @bc_bid AND (FLAGS & 1 <> 0) /* bc enabled */

IF @@ROWCOUNT <> 1 OR @bc_client_id IS NULL
BEGIN
  SET @bc_client_id = 0
  RETURN (1)
END

SELECT @bc_login_id = BC_LOGIN_ID, @flags = FLAGS, @flags2 = FLAGS2, @flags3 = FLAGS3, @descrip = DESCRIP
FROM dbo.BC_LOGINS(NOLOCK)
WHERE BC_CLIENT_ID = @bc_client_id AND BC_LOGIN = @bc_login /*AND BC_PIN = @psw_hash */ AND (FLAGS & 1 <> 0) /* bc enabled */

IF @@ROWCOUNT <> 1 OR @bc_login_id IS NULL OR @flags IS NULL
BEGIN
  SET @bc_client_id = 0
  SET @bc_login_id = 0
  RETURN (2)
END

RETURN 0
GO
