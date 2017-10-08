SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_get_user_rights]
	@sessionId [char](36)
AS
	EXEC auth.[get_user_rights] @sessionId
GO
