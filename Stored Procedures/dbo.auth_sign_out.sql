SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_sign_out]
	@sessionId [char](36)
AS
	EXEC auth.[sign_out] @sessionId 
GO
