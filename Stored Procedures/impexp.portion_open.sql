SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[portion_open]
	@date smalldatetime, 
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_out_nbg @date, @por, @user_id, 2, 99, default, 'ÂÀÙÄÁÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.PORTIONS_OUT_NBG 
SET STATE = 1, CLOSE_TIME = NULL, EXPORT_TIME = NULL, FINISH_TIME = NULL -- Open
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT

GO
