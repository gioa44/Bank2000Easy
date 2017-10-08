SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [impexp].[portion_export] 
	@date smalldatetime, 
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_out_nbg @date, @por, @user_id, 2, default, default, 'ÄØÓÐÏÒÔÉ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.PORTIONS_OUT_NBG
SET STATE = 3, EXPORT_TIME = GETDATE() -- Exported
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT

GO
