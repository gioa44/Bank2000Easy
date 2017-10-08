SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[close_day] (@date smalldatetime)
AS

SET NOCOUNT ON;

IF EXISTS(SELECT * FROM impexp.PORTIONS_OUT_NBG WHERE PORTION_DATE <= @date AND STATE <> 4 AND ([COUNT] <> 0 OR AMOUNT <> $0))
BEGIN
	RAISERROR ('ÀÒÉÓ ÀÒÀÃÀÓÒÖËÄÁÖËÉ ÄÒÏÅÍÖË ÁÀÍÊÛÉ ÂÀÓÀÂÆÀÅÍÉ ÐÏÒÝÉÄÁÉ', 16, 1)
	RETURN 1
END

DECLARE 
	@next_day smalldatetime,
	@r int

SET @next_day = @date + 1

-- USER_ID = 7 , NBG
EXEC @r = impexp.import_docs_out_nbg @date = @next_day, @por = 0, @user_id = 7, @is_close_day = 1
IF @@ERROR <> 0 OR @r <> 0 RETURN 1

EXEC @r = impexp.import_docs_out_swift @date = @next_day, @por = 0,	@user_id = 7, @is_close_day = 1
IF @@ERROR <> 0 OR @r <> 0 RETURN 1

BEGIN TRAN

EXEC @r = impexp.cleanup_out_nbg @date
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

EXEC @r = impexp.cleanup_out_swift @date
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

EXEC @r = impexp.cleanup_in_nbg @date
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

EXEC @r = impexp.cleanup_in_swift @date
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT

RETURN @@ERROR
GO
