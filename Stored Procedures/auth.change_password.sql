SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [auth].[change_password] (@userName [nvarchar] (128), @branchId [int], @oldPassword [nchar] (32), @newPassword [nchar] (32), @appUri [nvarchar] (128), @remoteAddress [nvarchar] (128), @raiseError [bit], @message [nvarchar] (250) OUTPUT)
WITH EXECUTE AS CALLER
AS EXTERNAL NAME [AltaSoft.Authentication].[AltaSoft.Authentication.AuthenticationFactory].[ChangePassword]
GO
