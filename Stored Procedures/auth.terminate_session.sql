SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [auth].[terminate_session] (@sessionId [nchar] (36), @reason [nvarchar] (50), @remoteAddress [nvarchar] (128))
WITH EXECUTE AS CALLER
AS EXTERNAL NAME [AltaSoft.Authentication].[AltaSoft.Authentication.AuthenticationFactory].[TerminateSession]
GO
