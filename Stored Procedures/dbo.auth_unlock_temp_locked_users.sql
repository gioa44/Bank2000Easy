SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_unlock_temp_locked_users]
AS
	EXEC auth.[unlock_temp_locked_users]
GO
