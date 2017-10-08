SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_begin_long_operation]
	@sessionId char(36),
	@minutes [int]
AS
	EXEC auth.begin_long_operation @sessionId,  @minutes

GO
