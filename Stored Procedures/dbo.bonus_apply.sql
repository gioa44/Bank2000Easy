SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[bonus_apply]
	@bonus_id int,
	@id int,
	@date smalldatetime,
	@client_no int,
	@user_id int
AS

SET NOCOUNT ON;
	
INSERT INTO dbo.CLIENT_BONUSES (CLIENT_NO,BONUS_ID,ID,EXECUTED,ADDED_BY,ADDED_AT)
VALUES (@client_no,@bonus_id,@id,0,@user_id,GETDATE())
GO
