SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [auth].[ping] (@sessionId [nchar] (36))
WITH EXECUTE AS CALLER
AS EXTERNAL NAME [AltaSoft.Authentication].[AltaSoft.Authentication.AuthenticationFactory].[Ping]
GO
