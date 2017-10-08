SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CLEARING]
	@dt smalldatetime
AS

SET NOCOUNT ON

DECLARE
	@clearing int,
	@head_branch_id int

EXEC dbo.GET_SETTING_INT 'CLEARING', @clearing OUTPUT
IF @clearing = 0
	RETURN 0

EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO', @head_branch_id OUTPUT

EXEC dbo.CLEARING_BAL @dt=@dt, @head_branch_id = @head_branch_id

EXEC dbo.CLEARING_OUTBAL @dt=@dt, @head_branch_id = @head_branch_id

RETURN 0
GO
