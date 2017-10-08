SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_CLOSE_DAY]
	@date smalldatetime,
	@user_id int,
	@loan_id int = NULL,
	@close_clients_other_loans bit = 0
AS

SET NOCOUNT ON

BEGIN TRAN

DECLARE
      @r int,
      @err int

IF @loan_id IS NULL
	SET @close_clients_other_loans = 0

IF @close_clients_other_loans <> 0
BEGIN
	DECLARE 
		@client_no int,
		@_loan_id int

	SELECT @client_no = CLIENT_NO
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id

	DECLARE cc CURSOR LOCAL
	FOR
	SELECT LOAN_ID
	FROM dbo.LOANS (NOLOCK)
	WHERE CLIENT_NO = @client_no AND LOAN_ID <> @loan_id AND [STATE] <> dbo.loan_const_state_closed()

	OPEN cc

	FETCH NEXT FROM cc INTO @_loan_id 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC @r = dbo.LOAN_SP_LOAN_CLOSE_DAY
			@date = @date,
			@user_id = @user_id,
			@loan_id = @_loan_id,
			@close_clients_other_loans = 0

		IF @@ERROR <> 0 OR @r <> 0
		BEGIN
			IF @@TRANCOUNT > 0	ROLLBACK
			RAISERROR ('ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ, ÅÄÒ áÄÒáÃÄÁÀ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÄÓáÉÓ ÃÀáÖÒÅÀ.',16,1) 
			RETURN(1) 
		END
		
		FETCH NEXT FROM cc INTO @_loan_id 
	END

	CLOSE cc
	DEALLOCATE cc
END


--EXEC @r = dbo.LOAN_SP_ON_USER_BEFORE_LOAN_PROCESSING
--    @date = @date,
--    @user_id = @user_id,
--    @loan_id = @loan_id
--
--SELECT @err = @@ERROR
--IF @r <> 0 OR @err <> 0
--BEGIN
--    RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ "LOAN_SP_ON_USER_BEFORE_LOAN_PROCESSING"!', 16, 1)
--	IF @@TRANCOUNT > 0	ROLLBACK
--    RETURN (1)
--END

DECLARE 
      @error_str varchar(200),
      @op_descrip varchar(150)

DECLARE
      @loan_open_date smalldatetime,
      @loan_id_ int,
      @op_id int,
      @op_type int


IF (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'LOAN_SERVER_STATE') <> 0
BEGIN
	IF @@TRANCOUNT > 0	ROLLBACK
	RAISERROR ('ÌÉÌÃÉÍÀÒÄÏÁÓ ÓÄÓáÉÓ ÃÙÉÓ ÃÀáÖÒÅÀ/ÂÀáÓÍÀ. ÂÈáÏÅÈ ÃÀÄËÏÃÏÈ.', 16, 1)
	RETURN (1)
END

SET @loan_open_date = CASE WHEN @loan_id IS NULL THEN dbo.loan_open_date() ELSE dbo.loan_open_date_for_loan(@loan_id) END

IF @date <> @loan_open_date
BEGIN
	IF @@TRANCOUNT > 0	ROLLBACK
	RAISERROR ('ÓÄÓáÉÓÈÅÉÓ ÄÓ ÃÙÄ ÖÊÅÄ ÃÀÉáÖÒÀ !', 16, 1)
	RETURN (1)
END

-- თუ სესხის CALC_DATE ემთხვევა ღია დღეს მაშინ ამ კონკრეტული სესხის დღის დახურვას არ ვაკეთებთ
IF @loan_id IS NOT NULL AND @loan_open_date >= dbo.loan_open_date()
BEGIN
	IF @@TRANCOUNT > 0	ROLLBACK
	RAISERROR ('ÓÄÓáÉÓÈÅÉÓ ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ, ÓÄÓáÉÓ ÙÉÀ ÃÙÄ ÄÌÈáÅÄÅÀ ÓÀÊÒÄÃÉÔÏ ÌÏÃÖËÉÓ ÙÉÀ ÃÙÄÓ !', 16, 1)
	RETURN (1)
END

-- თუ არსებობს არაავტორიზირებული ოპერაციები დღის დახურვას არ ვაკეთებთ
IF EXISTS (SELECT * FROM dbo.LOAN_OPS WHERE (@loan_id IS NULL OR LOAN_ID = @loan_id) AND (OP_DATE = @loan_open_date) AND (OP_STATE <> 255))
BEGIN
	IF @@TRANCOUNT > 0	ROLLBACK
	RAISERROR ('ÀÒÀÀÅÔÏÒÉÆÉÒÄÁÖËÉ ÏÐÄÒÀÝÉÉÓ ÀÒÓÄÁÏÁÉÓ ÂÀÌÏ, ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ !', 16, 1)
	RETURN (1)
END

-- თუ რომელიმე სესხის დღე არის დაბრუნებული ანუ თუ ყველა სესხი არ არის ღია დღეში, მაშინ დღეს არ ვხურავთ
IF @loan_id IS NULL AND EXISTS (SELECT * FROM dbo.LOAN_DETAILS WHERE CALC_DATE <> @loan_open_date)
BEGIN
	IF @@TRANCOUNT > 0	ROLLBACK
	RAISERROR ('ÃÀÁÒÖÍÄÁÖËÉ ÓÄÓáÄÁÉÓ ÀÒÓÄÁÏÁÉÓ ÂÀÌÏ, ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ !', 16, 1)
	RETURN (1)
END

IF @loan_id IS NULL
BEGIN
	UPDATE dbo.INI_INT 
	SET VALS = 1 
	WHERE IDS = 'LOAN_SERVER_STATE'
	IF @@ERROR <> 0
	BEGIN 
	  IF @@TRANCOUNT > 0	ROLLBACK
	  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÔÀÔÖÓÉÓ ÛÄÝÅËÀ 1). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1) 
	  RETURN (105) 
	END
END

EXEC @r = dbo.LOAN_SP_LOAN_PROCESSING
	  @date       = @date,
	  @user_id    = @user_id,
	  @loan_id    = @loan_id

SELECT @err = @@ERROR
IF @r <> 0 OR @err <> 0
BEGIN
	  IF @@TRANCOUNT > 0 ROLLBACK
	  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
	  RETURN @r
END

IF (@close_clients_other_loans <> 0) OR (@loan_id IS NULL)
BEGIN
	EXEC @r = dbo.LOAN_SP_LOAN_PROCESSING_RISKS
		@date       = @date,
		@user_id    = @user_id,
		@loan_id	= @loan_id

	SELECT @err = @@ERROR
	IF @r <> 0 OR @err <> 0
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK
		RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
		RETURN @r
	END

	--EXEC @r = dbo.LOAN_SP_LOAN_PROCESSING_RISKS_GROUPS
	--    @date       = @date,
	--    @user_id    = @user_id,
	--	@loan_id	= @loan_id
	--
	--SELECT @err = @@ERROR
	--IF @r <> 0 OR @err <> 0
	--BEGIN
	--    IF @@TRANCOUNT > 0 ROLLBACK
	--    RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
	--    RETURN @r
	--END
END

UPDATE H
SET   H.MAX_CATEGORY_LEVEL = D.MAX_CATEGORY_LEVEL,
    H.CATEGORY_1 = D.CATEGORY_1,
    H.CATEGORY_2 = D.CATEGORY_2,
    H.CATEGORY_3 = D.CATEGORY_3,
    H.CATEGORY_4 = D.CATEGORY_4,
    H.CATEGORY_5 = D.CATEGORY_5,
    H.CATEGORY_6 = D.CATEGORY_6
FROM dbo.LOAN_DETAILS D
    INNER JOIN dbo.LOAN_DETAILS_HISTORY H ON D.LOAN_ID = H.LOAN_ID AND H.CALC_DATE = DATEADD(day, -1, D.CALC_DATE)
WHERE @loan_id IS NULL OR D.LOAN_ID = @loan_id	

IF @@ERROR <> 0
BEGIN
    IF @@TRANCOUNT > 0 ROLLBACK
    RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
    RETURN @r
END

/*EXEC @r = dbo.LOAN_SP_LOAN_PROCESSING_RISKS_ACCOUNTING
      @date       = @date,
      @user_id    = @user_id

SELECT @err = @@ERROR
IF @r <> 0 OR @err <> 0
BEGIN
      IF @@TRANCOUNT > 0 ROLLBACK
      RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
      RETURN @r
END*/

IF @loan_id IS NULL
BEGIN
	UPDATE dbo.INI_INT 
	SET VALS = 0 
	WHERE IDS = 'LOAN_SERVER_STATE'
	IF @@ERROR <> 0
	BEGIN 
	  ROLLBACK
	  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÔÀÔÖÓÉÓ ÛÄÝÅËÀ 2). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1) 
	  RETURN (117) 
	END

	UPDATE dbo.INI_DT 
	SET VALS = @loan_open_date + 1 
	WHERE IDS = 'OPEN_LOAN_DATE'
	IF @@ERROR <> 0
	BEGIN 
	  ROLLBACK
	  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÈÀÒÉÙÉÓ ÛÄÝÅËÀ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1) 
	  RETURN (118) 
	END
END

COMMIT
RETURN(0)
GO
