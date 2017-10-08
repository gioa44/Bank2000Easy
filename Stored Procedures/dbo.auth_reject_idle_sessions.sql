SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_reject_idle_sessions]
AS
	EXEC auth.[reject_idle_sessions]
GO
