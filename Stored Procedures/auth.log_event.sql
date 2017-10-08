SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [auth].[log_event] (@sessionId [nchar] (36), @severity [int], @eventDescrip [nvarchar] (4000))
WITH EXECUTE AS CALLER
AS EXTERNAL NAME [AltaSoft.Authentication].[AltaSoft.Authentication.AuthenticationFactory].[LogSessionEvent]
GO
