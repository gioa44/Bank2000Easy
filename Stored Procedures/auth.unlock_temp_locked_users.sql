SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [auth].[unlock_temp_locked_users]
WITH EXECUTE AS CALLER
AS EXTERNAL NAME [AltaSoft.Authentication].[AltaSoft.Authentication.AuthenticationFactory].[UnlockTempLockedUsers]
GO
