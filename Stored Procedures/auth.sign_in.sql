SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [auth].[sign_in] (@userName [nvarchar] (128), @password [nchar] (32), @branchId [int], @newPassword [nchar] (32)=NULL, @appUri [nvarchar] (128), @remoteAddress [nvarchar] (128), @sessionId [nchar] (36) OUTPUT, @userId [int] OUTPUT, @userFullName [nvarchar] (50) OUTPUT, @deptId [int] OUTPUT, @passwordExpireDate [datetime] OUTPUT, @cannotChangePassword [bit] OUTPUT, @raiseError [bit], @message [nvarchar] (250) OUTPUT)
WITH EXECUTE AS CALLER
AS EXTERNAL NAME [AltaSoft.Authentication].[AltaSoft.Authentication.AuthenticationFactory].[SignIn]
GO
