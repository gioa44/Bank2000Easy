SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[OPEN_DAY] (@open_work_date bit = 0) AS
 
DECLARE
 @dt smalldatetime,
 @year int,
 @sql nvarchar(4000),
 @error int,
 @r int
 
SET NOCOUNT ON
 
DECLARE @database_id int
SET @database_id = dbo.sys_database_id()
 
EXEC @r = dbo.ON_USER_BEFORE_OPEN_DAY 0
IF @@ERROR <> 0 OR @r <> 0
BEGIN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÌÏÌáÌÀÒÄÁËÉÓ ×ÖÍØÝÉÀ 1). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (101) 
END
 
BEGIN TRAN
 
SET DEADLOCK_PRIORITY HIGH

SET @dt = dbo.bank_open_date()
SET @year = YEAR(@dt - 1)
 
SET @sql = 'OPENING DAY: ' + CONVERT(varchar(20), @dt-1, 103)
PRINT @sql
 
EXEC @r = dbo.ON_USER_BEFORE_OPEN_DAY 1
IF @@ERROR <> 0 OR @r <> 0
BEGIN
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÌÏÌáÌÀÒÄÁËÉÓ ×ÖÍØÝÉÀ 2). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (102) 
END

EXEC @r = dbo.SYS_DELETE_AUTO_DOCS @dt
IF @@ERROR <> 0 OR @r <> 0
BEGIN 
  ROLLBACK TRAN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÀÅÔÏÌÀÔÖÒÉ ÓÀÁÖÈÄÁÉÓ ßÀÛËÀ). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (103) 
END
 
UPDATE dbo.INI_INT SET VALS = 2 WHERE IDS = 'SERVER_STATE'
IF @@ERROR <> 0
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÓÔÀÔÖÓÉÓ ÛÄÝÅËÀ 1). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1) 
  RETURN (104) 
END
 

EXEC @r = dbo.SYS_DROP_DATE_CONSTRAINTS @year
IF @@ERROR <> 0 OR @r <> 0
BEGIN 
  ROLLBACK TRAN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÈÀÒÉÙÉÓ ÊÏÍÓÔÒÄÉÍÔÄÁÉÓ ÌÏáÓÍÀ). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (107) 
END
 
/* disable some checks to accelerate moving from OPS_ARC */
 
ALTER TABLE dbo.OPS_0000 NOCHECK CONSTRAINT ALL
 
SET @dt = @dt - 1
 
UPDATE dbo.INI_DT
SET VALS = @dt
WHERE IDS = 'OPEN_BANK_DATE'
IF @@ERROR <> 0
BEGIN 
  ROLLBACK TRAN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÈÀÒÉÙÉÓ ÛÄÝÅËÀ). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (107) 
END
 
PRINT 'MOVING DOCS, BALANCES & RATES FROM ARCHIVE'
EXEC @r = dbo.SYS_MOVE_ALL_ARC_DOCS_TO_CUR @dt
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÀÁÖÈÄÁÉÓ ÂÀÃÌÏÔÀÍÀ ÀÒØÉÅÉÃÀÍ). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1) 
  RETURN (110) 
END
 
PRINT 'OPENING Import/Export day ..'
EXEC impexp.open_day @dt 
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÉÌÐÏÒÔ/ÄØÓÐÏÒÔÉ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (199) 
END

----
 
PRINT 'DELETING OPS_HELPER'
 
SET @sql = N'DELETE FROM dbo.' + dbo.sys_get_arc_table_name('OPS_HELPER',@year) + N' WHERE DT = @dt'
EXEC @r = sp_executesql @sql, N'@dt smalldatetime', @dt
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('TODO',16,1) 
  RETURN (110) 
END
 
PRINT 'DELETING SALDOS'
 
SET @sql = N'DELETE FROM dbo.' + dbo.sys_get_arc_table_name('SALDOS',@year) + N' WHERE DT = @dt'
EXEC @r = sp_executesql @sql, N'@dt smalldatetime', @dt
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('TODO',16,1) 
  RETURN (110) 
END
 
IF DAY(@dt) = 1 AND MONTH(@dt) = 1
BEGIN
	EXEC @r = dbo.SYS_DELETE_NEW_YEAR
	IF @@ERROR <> 0 OR @r <> 0 
	BEGIN 
		ROLLBACK TRAN 
		RAISERROR ('Cannot delete tables',16,1)
		RETURN (107) 
	END
END


UPDATE dbo.INI_INT SET VALS = 0 WHERE IDS = 'SERVER_STATE'
IF @@ERROR <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÓÔÀÔÖÓÉÓ ÛÄÝÅËÀ 2). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1) 
  RETURN (112) 
END
 
PRINT 'DOING JOBS ..'
EXEC @r = dbo._DO_JOBS 2,4
IF @@ERROR <> 0 OR @r <> 0
BEGIN
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÃÀÅÀËÄÁÄÁÉ). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (113) 
END
 
EXEC @r = dbo.ON_USER_AFTER_OPEN_DAY 1
IF @@ERROR <> 0 OR @r <> 0
BEGIN
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÌÏÌáÌÀÒÄÁËÉÓ ×ÖÍØÝÉÀ 3). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (114) 
END
 
EXEC @r = dbo.SYS_ADD_DATE_CONSTRAINTS @dt
IF @@ERROR <> 0 OR @r <> 0
BEGIN 
  ROLLBACK TRAN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÈÀÒÉÙÉÓ ÊÏÍÓÔÒÄÉÍÔÄÁÉÓ ÃÀÃÄÁÀ). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (107) 
END
 
ALTER TABLE dbo.OPS_0000 CHECK CONSTRAINT ALL
 
INSERT INTO dbo.DAY_RETURNS (DT) VALUES(@dt)
IF @@ERROR <> 0 
BEGIN
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ËÏÂÉÒÄÁÀ). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (115) 
END
 
IF @open_work_date <> 0
BEGIN
 UPDATE dbo.INI_DT
 SET VALS = @dt
 WHERE IDS = 'WORK_BANK_DATE'
 IF @@ERROR <> 0 
 BEGIN 
   ROLLBACK TRAN 
   RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÂÀáÓÍÉÓÀÓ (ÈÀÒÉÙÉÓ ÛÄÝÅËÀ). ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
   RETURN (107) 
 END
END
 
SET DEADLOCK_PRIORITY NORMAL

COMMIT TRAN
 
IF @@ERROR <> 0
BEGIN
  RAISERROR('ÛÄÝÃÏÌÀ ÃÙÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÉÓÀÓ. ÃÙÄ ÀÒ ÂÀÉáÓÍÀ',16,1)
  RETURN (115)
END
 
PRINT 'DAY OPENED.'
 
EXEC dbo.ON_USER_AFTER_OPEN_DAY 0
 
RETURN (0)
GO
