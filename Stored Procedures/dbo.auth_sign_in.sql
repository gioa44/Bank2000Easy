SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_sign_in]
	@userName [varchar](128),
	@password [char](32),
	@branchId [int],
	@newPassword [char](32) = null,
	@appUri [varchar](128),
	@remoteAddress [varchar](128),
	@sessionId [char](36) OUTPUT,
	@userId [int] OUTPUT,
	@userFullName [varchar](50) OUTPUT,
	@deptId [int] OUTPUT,
	@passwordExpireDate [datetime] OUTPUT,
	@cannotChangePassword [bit] OUTPUT,
	@raiseError [bit],
	@message [varchar](250) OUTPUT
AS
	DECLARE @r int
	EXEC @r = auth.[sign_in]
		@userName,
		@password,
		@branchId,
		@newPassword,
		@appUri,
		@remoteAddress,
		@sessionId OUTPUT,
		@userId OUTPUT,
		@userFullName OUTPUT,
		@deptId OUTPUT,
		@passwordExpireDate OUTPUT,
		@cannotChangePassword OUTPUT,
		@raiseError,
		@message OUTPUT
	RETURN @r
GO
