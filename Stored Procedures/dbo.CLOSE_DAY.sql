SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CLOSE_DAY] AS

SET NOCOUNT ON

DECLARE
	@dt smalldatetime,
	@auto_lock_days int,
	@year int,
	@sql nvarchar(4000),
	@error int,
	@r int

UPDATE dbo.USERS
SET LOCK_FLAG = 1
WHERE LOCK_FLAG = 0 AND GETDATE() > USER_AUTO_LOCK_DATE

EXEC dbo.GET_SETTING_INT 'USER_AUTO_LOCK', @auto_lock_days OUTPUT
IF @auto_lock_days > 0
BEGIN
  UPDATE dbo.USERS
  SET LOCK_FLAG = 1
  WHERE LOCK_FLAG = 0 AND DATEDIFF(dd, USER_LAST_LOGIN, GETDATE()) > @auto_lock_days
END

EXEC dbo.SAVE_OLD_LOGS

EXEC @r = dbo.ON_USER_BEFORE_CLOSE_DAY 0
IF @@ERROR <> 0 OR @r <> 0 
BEGIN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÌÏÌáÌÀÒÄÁËÉÓ ×ÖÍØÝÉÀ 1). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (101) 
END

BEGIN TRAN

SET DEADLOCK_PRIORITY HIGH

SET @dt = dbo.bank_open_date()
SET @year = YEAR(@dt)

SET @sql = 'CLOSING DAY: ' + CONVERT(varchar(20), @dt, 103)
PRINT @sql

IF dbo.bank_work_date() < @dt + 1
BEGIN
	UPDATE dbo.INI_DT
	SET VALS = @dt + 1
	WHERE IDS = 'WORK_BANK_DATE'
	IF @@ERROR <> 0 
	BEGIN 
	  ROLLBACK TRAN 
	  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÈÀÒÉÙÉÓ ÛÄÝÅËÀ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
	  RETURN (113) 
	END
END

EXEC @r = dbo.ON_USER_BEFORE_CLOSE_DAY 1
IF @@ERROR <> 0 OR @r <> 0 
BEGIN
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÌÏÌáÌÀÒÄÁËÉÓ ×ÖÍØÝÉÀ 2). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (102) 
END

IF EXISTS (SELECT * FROM dbo.OPS_0000 WHERE DOC_DATE <= @dt AND NOT (REC_STATE BETWEEN 20 AND 29))
BEGIN
  RAISERROR ('ÀÒÉÓ ÀÒÀÀÖÔÏÒÉÆÄÁÖËÉ ÓÀÁÖÈÄÁÉ. ÃÙÉÓ ÃÀáÖÒÅÀ ÀÒ ÛÄÉÞËÄÁÀ',16,1)
  ROLLBACK TRAN
  RETURN (104)
END

UPDATE dbo.INI_INT SET VALS = 1 WHERE IDS = 'SERVER_STATE'
IF @@ERROR <> 0
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÔÀÔÖÓÉÓ ÛÄÝÅËÀ 1). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1) 
  RETURN (105) 
END

IF DAY(@dt) = 1 AND MONTH(@dt) = 1
BEGIN
	EXEC @r = dbo.SYS_CREATE_NEW_YEAR
	IF @@ERROR <> 0 OR @r <> 0 
	BEGIN 
		ROLLBACK TRAN 
		RAISERROR ('Cannot close Jan 01',16,1)
		RETURN (107) 
	END
END

PRINT 'DOING JOBS ..'
EXEC @r = dbo._DO_JOBS 1, 3
IF @@ERROR <> 0 OR @r <> 0 
BEGIN
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÃÀÅÀËÄÁÄÁÉ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (106) 
END

PRINT 'Closing Import/Export day ..'
EXEC @r = impexp.close_day @dt 
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÉÌÐÏÒÔ/ÄØÓÐÏÒÔÉ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (199) 
END

PRINT 'Moving Payments to arc ..'
EXEC @r = dbo.PAYMENTS_CLOSE_DAY @dt = @dt
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÀÒÉÓ ÀÒÀÀÖÔÏÒÉÆÄÁÖËÉ ÓÀÁÖÈÄÁÉ ÊÏÌÖÍÀËÖÒ ÂÀÃÀÓÀáÀÃÄÁÛÉ. ÃÙÉÓ ÃÀáÖÒÅÀ ÀÒ ÛÄÉÞËÄÁÀ',16,1)
  RETURN (104) 
END

PRINT 'Moving Incasos to arc ..'
EXEC @r = dbo.INCASSO_CLOSE_DAY @dt = @dt
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÓÀÁÖÈÄÁÉÓ ÂÀÃÀÔÀÍÉÓÀÓ ÀÒØÉÅÛÉ',16,1)
  RETURN (104) 
END

EXEC @r = dbo.SYS_DROP_DATE_CONSTRAINTS @year
IF @@ERROR <> 0 OR @r <> 0
BEGIN 
  ROLLBACK TRAN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÈÀÒÉÙÉÓ ÊÏÍÓÔÒÄÉÍÔÄÁÉÓ ÌÏáÓÍÀ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (107) 
END

PRINT 'FIXING 2601,2611 ..'
EXEC @r = dbo._FIX_26x1 @dt, 0 -- End of dayIF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (26x1-ÉÓ ÂÀÓßÏÒÄÁÀ - 1). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (110) 
END

PRINT 'Clearing docs ..'
EXEC @r = dbo.CLEARING @dt = @dt
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÊËÉÒÉÍÂÉÓ ÓÀÁÖÈÄÁÉÓ ÂÀÔÀÒÄÁÉÓÀÓ',16,1)
  RETURN (111) 
END

PRINT 'MOVING DOCS, BALS & RATES TO ARC ..'
EXEC @r = dbo.SYS_MOVE_ALL_DOCS_TO_ARC @dt
IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÀÁÖÈÄÁÉÓ ÂÀÃÀÔÀÍÀ ÀÒØÉÅÛÉ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (107) 
END

SET @dt = @dt + 1

IF DAY(@dt) = 1
BEGIN
	EXEC @r = dbo.CLOSE_MONTH
	IF @@ERROR <> 0 OR @r <> 0 
	BEGIN 
		ROLLBACK TRAN 
		RAISERROR ('Cannot close month',16,1)
		RETURN (107) 
	END
END

IF DAY(@dt) = 2 AND MONTH(@dt) = 1
BEGIN
	EXEC @r = dbo.CLOSE_JAN_01
	IF @@ERROR <> 0 OR @r <> 0 
	BEGIN 
		ROLLBACK TRAN 
		RAISERROR ('Cannot close Jan 01',16,1)
		RETURN (107) 
	END
END

	
UPDATE dbo.INI_DT
SET VALS = @dt
WHERE IDS = 'OPEN_BANK_DATE'
IF @@ERROR <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÈÀÒÉÙÉÓ ÛÄÝÅËÀ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (113) 
END


DECLARE @prev_date smalldatetime
SET @prev_date = @dt - 1

EXEC @r = dbo.SYS_ADD_DATE_CONSTRAINTS @dt
IF @@ERROR <> 0 OR @r <> 0
BEGIN 
  ROLLBACK TRAN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÈÀÒÉÙÉÓ ÊÏÍÓÔÒÄÉÍÔÄÁÉÓ ÃÀÃÄÁÀ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (107) 
END

PRINT 'FIXING 2601,2611 ..'
EXEC @r = dbo._FIX_26x1 @dt, 1 -- start of day (revaluation)IF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (26x1-ÉÓ ÂÀÓßÏÒÄÁÀ - 2). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (115) 
END
PRINT 'BUILDING BALANCE ..'

EXEC @r = dbo.SYS_BUILD_BALANCE @prev_dateIF @@ERROR <> 0 OR @r <> 0 
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÁÀËÀÍÓÄÁÉÓ ÛÄÍÀáÅÀ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (199) 
END

UPDATE dbo.INI_INT SET VALS = 0 WHERE IDS = 'SERVER_STATE'
IF @@ERROR <> 0
BEGIN 
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÔÀÔÖÓÉÓ ÛÄÝÅËÀ 2). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1) 
  RETURN (117) 
END

EXEC @r = dbo.ON_USER_AFTER_CLOSE_DAY 1
IF @@ERROR <> 0 OR @r <> 0 
BEGIN
  ROLLBACK TRAN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÌÏÌáÌÀÒÄÁËÉÓ ×ÖÍØÝÉÀ 3). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (118) 
END

SET DEADLOCK_PRIORITY NORMAL

COMMIT TRAN
IF @@ERROR <> 0 
BEGIN
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ. ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (119)
END

PRINT 'DAY CLOSED.'

EXEC dbo.ON_USER_AFTER_CLOSE_DAY 0

RETURN (0)
GO
