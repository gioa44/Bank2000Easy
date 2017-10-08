SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_terminate_session]
	@sessionId [char](36),
	@reason [varchar](50),
	@remoteAddress [varchar](128)
AS
	EXEC auth.[terminate_session]
		@sessionId,
		@reason,
		@remoteAddress
GO
