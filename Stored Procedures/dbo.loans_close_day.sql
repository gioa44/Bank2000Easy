SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[loans_close_day]
	@date smalldatetime,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
      @r int,
      @loan_open_date_all smalldatetime,
      @loan_id_ int,
      @op_id int,
      @op_type int

SET @loan_open_date_all = dbo.loan_open_date()

IF (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'LOAN_SERVER_STATE') <> 0
BEGIN
	RAISERROR ('ÌÉÌÃÉÍÀÒÄÏÁÓ ÓÀÓÄÓáÏ ÌÏÃÖËÉÓ ÃÙÉÓ ÃÀáÖÒÅÀ/ÂÀáÓÍÀ. ÂÈáÏÅÈ ÃÀÄËÏÃÏÈ.', 16, 1)
	RETURN (1)
END

IF @loan_open_date_all <> @date
BEGIN
	RAISERROR ('ÀÒÜÄÖËÉ ÃÙÄ ÖÊÅÄ ÃÀáÖÒÖËÉÀ.', 16, 1)
	RETURN (1)
END

IF EXISTS (SELECT * FROM dbo.LOAN_OPS WHERE (OP_DATE = @loan_open_date_all) AND (OP_STATE <> 255))
BEGIN
	RAISERROR ('ÀÒÀÀÅÔÏÒÉÆÉÒÄÁÖËÉ ÏÐÄÒÀÝÉÉÓ ÀÒÓÄÁÏÁÉÓ ÂÀÌÏ, ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ !', 16, 1)
	RETURN (1)
END

IF EXISTS (SELECT * FROM dbo.LOAN_DETAILS WHERE CALC_DATE < @loan_open_date_all)
BEGIN
	RAISERROR ('ÃÀÁÒÖÍÄÁÖËÉ ÓÄÓáÄÁÉÓ ÀÒÓÄÁÏÁÉÓ ÂÀÌÏ, ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ !', 16, 1)
	RETURN (1)
END

UPDATE dbo.INI_INT
SET VALS = 1 
WHERE IDS = 'LOAN_SERVER_STATE'
IF @@ERROR <> 0
BEGIN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÔÀÔÖÓÉÓ ÛÄÝÅËÀ 1). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1) 
  RETURN (105) 
END

---------------------------------- ÚÅÄËÀ ÓÄÓáÉÓ ÃÀáÖÒÅÀ ----------------------------------
------------------------------------------------------------------------------------------

DECLARE cr CURSOR FAST_FORWARD LOCAL FOR
SELECT L.LOAN_ID
FROM dbo.LOANS L
	INNER JOIN dbo.LOAN_DETAILS D ON D.LOAN_ID = L.LOAN_ID
WHERE D.CALC_DATE = @date


OPEN cr
FETCH NEXT FROM cr INTO @loan_id_

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC @r = dbo.loan_close_day @date = @date, @user_id = @user_id, @loan_id = @loan_id_, @close_clients_other_loans = 0, @from_global_close_day = 1
	IF @@ERROR <> 0 OR @r <> 0 
	BEGIN
		RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
		GOTO ret_
	END

	FETCH NEXT FROM cr INTO @loan_id_
END

------------------------------------------------------------------------------------------
---------------------------------- ÚÅÄËÀ ÓÄÓáÉÓ ÃÀáÖÒÅÀ ----------------------------------

EXEC @r = dbo.loan_process_risks
	@date       = @date,
	@user_id    = @user_id,
	@loan_id	= NULL

IF @@ERROR <> 0 OR @r <> 0
BEGIN
	RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
	GOTO ret_
END


UPDATE H
SET H.MAX_CATEGORY_LEVEL = D.MAX_CATEGORY_LEVEL,
    H.CATEGORY_1 = D.CATEGORY_1,
    H.CATEGORY_2 = D.CATEGORY_2,
    H.CATEGORY_3 = D.CATEGORY_3,
    H.CATEGORY_4 = D.CATEGORY_4,
    H.CATEGORY_5 = D.CATEGORY_5,
    H.CATEGORY_6 = D.CATEGORY_6
FROM dbo.LOAN_DETAILS D
    INNER JOIN dbo.LOAN_DETAILS_HISTORY H ON D.LOAN_ID = H.LOAN_ID AND H.CALC_DATE = DATEADD(day, -1, D.CALC_DATE)

IF @@ERROR <> 0
BEGIN
    RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
    GOTO ret_
END

--IF (SELECT ISNULL(VALS, 0) FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'L_LOG_LOAN_STATES') <> 0
--BEGIN
--	INSERT INTO dbo.LOAN_STATES_LOG (LOAN_ID, DATE, [STATE])
--	SELECT LOAN_ID, @date, [STATE] 
--	FROM dbo.LOANS (NOLOCK)
--	WHERE [STATE] <> 255
--	IF @@ERROR <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1) GOTO ret_ END
--END

UPDATE dbo.INI_DT 
SET VALS = @loan_open_date_all + 1 
WHERE IDS = 'OPEN_LOAN_DATE'
IF @@ERROR <> 0
BEGIN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÈÀÒÉÙÉÓ ÛÄÝÅËÀ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1) 
  GOTO ret_
END

ret_:
UPDATE dbo.INI_INT 
SET VALS = 0 
WHERE IDS = 'LOAN_SERVER_STATE'
IF @@ERROR <> 0
BEGIN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÔÀÔÖÓÉÓ ÛÄÝÅËÀ 2). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1) 
  RETURN (117) 
END

RETURN(0)
GO
