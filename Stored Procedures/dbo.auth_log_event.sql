SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_log_event]
	@sessionId [char](36),
	@severity [int],
	@eventDescrip [varchar](4000)
AS
	EXEC auth.log_event
		@sessionId,
		@severity,
		@eventDescrip
GO
