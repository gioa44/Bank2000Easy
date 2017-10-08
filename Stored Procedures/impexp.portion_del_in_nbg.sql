SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[portion_del_in_nbg]
	@date smalldatetime, 
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_in_nbg @date, @por, @user_id, 1, default, default, 'ÂÀÖØÌÄÁÀ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DELETE FROM impexp.DOCS_IN_NBG 
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

DELETE FROM impexp.PORTIONS_IN_NBG 
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT
GO
