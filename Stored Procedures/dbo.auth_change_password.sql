SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_change_password]
	@userName [varchar](128),
	@branchId [int],
	@oldPassword [char](32),
	@newPassword [char](32),
	@appUri [varchar](128),
	@remoteAddress [varchar](128),
	@raiseError [bit],
	@message [varchar](250) OUTPUT
AS
	DECLARE @r int
	EXEC @r = auth.[change_password]
		@userName,
		@branchId,
		@oldPassword,
		@newPassword,
		@appUri,
		@remoteAddress,
		@raiseError,
		@message OUTPUT
	RETURN @r
GO
