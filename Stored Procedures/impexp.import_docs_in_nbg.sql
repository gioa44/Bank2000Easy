SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[import_docs_in_nbg] 
	@date smalldatetime,
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_in_nbg @date, @por, @user_id, 1, default, default, 'ÉÌÐÏÒÔÉ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

EXEC @r = impexp.on_user_before_import_portion_in_nbg
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE @row_id int

DECLARE cc CURSOR LOCAL READ_ONLY
FOR
SELECT ROW_ID
FROM #nbg_in
WHERE VOP <> '99' AND PDK = '1' AND VOBR = '3'

OPEN cc

FETCH NEXT FROM cc INTO @row_id

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC @r = impexp.import_1doc_in_nbg @date, @por, @user_id, @row_id
	
	IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

	FETCH NEXT FROM cc INTO @row_id
END


CLOSE cc
DEALLOCATE cc

UPDATE impexp.PORTIONS_IN_NBG
SET STATE = 1
WHERE PORTION_DATE = @date AND PORTION = @por

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT

RETURN @@ERROR
GO
