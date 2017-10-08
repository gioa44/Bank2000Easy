SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_ping]
	@sessionId [char](36)
AS
	EXEC auth.[ping] @sessionId
GO
