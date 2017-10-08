SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_LOGIN_USER]
	@loginame varchar(128),
	@password varchar(32),
	@user_id int OUTPUT
AS

SET NOCOUNT ON

SET  @user_id = NULL


RETURN (0)
GO
