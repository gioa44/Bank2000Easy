SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_AFTER_EDIT_CLIENT]
	@client_no int,
	@user_id int
AS

SET NOCOUNT ON;

-- Put your checks here

RETURN 0
GO