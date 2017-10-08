SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[import_docs_in_swift]
	@date smalldatetime,
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE
	@r int,
	@row_id int

DECLARE cc CURSOR LOCAL READ_ONLY
FOR
SELECT ROW_ID
FROM #swift_in

OPEN cc

FETCH NEXT FROM cc INTO @row_id

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC @r = impexp.import_1doc_in_swift @user_id, @row_id

	IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

	FETCH NEXT FROM cc INTO @row_id
END


CLOSE cc
DEALLOCATE cc

COMMIT
GO
