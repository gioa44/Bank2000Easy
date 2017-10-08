SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[depo_sp_sync_depo_b2000]
	@depo_id int = NULL,
	@user_id int,
	@date smalldatetime = NULL
AS

SET NOCOUNT ON;

DECLARE
	@r int
	
DECLARE
	@depo_synchronizing int
	
SET @depo_synchronizing = NULL	
	
UPDATE dbo.INI_INT WITH (ROWLOCK)
SET @depo_synchronizing = VALS, VALS = 1
WHERE IDS = 'DEPO_SYNCHRONIZING' AND VALS = 0
IF @@ERROR <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÉÍØÒÏÍÉÆÀÝÉÉÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓ ÃÒÏÓ!', 16, 1); RETURN (1); END

IF @depo_synchronizing IS NULL
BEGIN
	RAISERROR('ÀÍÀÁÒÄÁÆÄ ÌÉÌÃÉÍÀÒÄÏÁÓ ÓÉÍØÒÏÍÉÆÀÝÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ, ÓÝÀÃÄÈ ÌÏÂÅÉÀÍÄÁÉÈ!', 16, 1);
	RETURN (1);
END

CREATE TABLE #docs(
	DEPO_ID int NOT NULL,
	REC_ID int NOT NULL,
	REC_STATE tinyint NOT NULL,
	PRIMARY KEY (DEPO_ID, REC_ID))

INSERT INTO #docs(DEPO_ID, REC_ID, REC_STATE)
SELECT D.DEPO_ID, O.REC_ID, O.REC_STATE
FROM dbo.DEPO_DEPOSITS D (NOLOCK)
	INNER JOIN dbo.OPS_HELPER_0000 H (NOLOCK) ON (H.ACC_ID = D.DEPO_ACC_ID)
	INNER JOIN dbo.OPS_0000 O (NOLOCK) ON (O.REC_ID = H.REC_ID)
	LEFT OUTER JOIN dbo.DEPO_OP DO (NOLOCK) ON (DO.DEPO_ID = D.DEPO_ID) AND ((H.REC_ID = DO.DOC_REC_ID) OR (O.PARENT_REC_ID = DO.DOC_REC_ID))
WHERE (O.DOC_TYPE <> 16) AND ((@depo_id IS NULL) OR (D.DEPO_ID = @depo_id)) AND (D.STATE > 40) AND (D.STATE < 240) AND ((@date IS NULL) OR (H.DT <= @date)) AND (DO.OP_ID IS NULL)

IF @@ERROR <> 0 BEGIN EXEC dbo.depo_sp_sync_flag_clear; DROP TABLE #docs; RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÒÄÁÉÓ ÓÉÍØÒÏÍÉÆÀÝÉÉÓ ÃÒÏÓ!', 16, 1); RETURN (1); END

IF (SELECT COUNT(*) FROM #docs) = 0 BEGIN EXEC dbo.depo_sp_sync_flag_clear; DROP TABLE #docs; RETURN 0; END;

IF EXISTS(SELECT * FROM #docs WHERE REC_STATE < 20)
BEGIN EXEC dbo.depo_sp_sync_flag_clear; DROP TABLE #docs; RAISERROR('ÀÍÀÁÒÄÁÆÄ ÀÒÓÄÁÏÁÓ ÀÒÀÀÅÔÏÒÉÆÄÁÖËÉ ÓÀÁÖÈÄÁÉ!', 16, 1); RETURN (1); END

IF EXISTS(
	SELECT O.*
	FROM #docs D
		INNER JOIN dbo.DEPO_OP O (NOLOCK) ON O.DEPO_ID = D.DEPO_ID
	WHERE O.OP_STATE = 0)
BEGIN EXEC dbo.depo_sp_sync_flag_clear; DROP TABLE #docs; RAISERROR('ÀÍÀÁÒÄÁÆÄ ÀÒÓÄÁÏÁÓ ÃÀÖÓÒÖËÄÁÄËÉ ÏÐÄÒÀÝÉÄÁÉ!', 16, 1); RETURN (1); END


DECLARE c_sync CURSOR
FOR	SELECT DISTINCT DEPO_ID
FROM #docs
ORDER BY DEPO_ID
IF @@ERROR <> 0 BEGIN EXEC dbo.depo_sp_sync_flag_clear; DROP TABLE #docs; RAISERROR('ERROR: CREATE CURSOR', 16, 1); RETURN (1); END

OPEN c_sync

FETCH NEXT FROM c_sync INTO @depo_id

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC @r = dbo.depo_sp_sync_one_depo_b2000
		@depo_id = @depo_id,
		@user_id = @user_id
	
	IF @@ERROR <> 0 OR @r <> 0 BEGIN CLOSE c_sync; DEALLOCATE c_sync; EXEC dbo.depo_sp_sync_flag_clear; DROP TABLE #docs; RAISERROR('ERROR: CREATE CURSOR', 16, 1); RETURN (1); END
 
	FETCH NEXT FROM c_sync INTO @depo_id
END

CLOSE c_sync
DEALLOCATE c_sync

DROP TABLE #docs

EXEC @r = dbo.depo_sp_sync_flag_clear
IF @@ERROR <> 0 OR @r <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÉÍØÒÏÍÉÆÀÝÉÉÓ ÓÔÀÔÖÓÉÓ ÛÄÝÅËÉÓ ÃÒÏÓ!', 16, 1); RETURN (1); END

RETURN 0
GO
