SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_OPEN_DAY]
	@date smalldatetime,
	@user_id int,
	@loan_id int,
	@open_clients_other_loans bit = 0
AS

BEGIN TRAN

DECLARE @r int

IF @open_clients_other_loans <> 0
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
	WHERE CLIENT_NO = @client_no AND LOAN_ID <> @loan_id AND [STATE] <> 255

	OPEN cc

	FETCH NEXT FROM cc INTO @_loan_id 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC @r = dbo.LOAN_SP_LOAN_OPEN_DAY
			@date = @date,
			@user_id = @user_id,
			@loan_id = @_loan_id,
			@open_clients_other_loans = 0

		IF @@ERROR <> 0 OR @r <> 0
		BEGIN
			IF @@TRANCOUNT > 0	ROLLBACK
			RAISERROR ('ÃÙÉÓ ÃÀÁÒÖÍÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÅÄÒ áÄÒáÃÄÁÀ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÄÓáÉÓ ÃÀÁÒÖÍÄÁÀ.',16,1) 
			RETURN(1) 
		END
		
		FETCH NEXT FROM cc INTO @_loan_id 
	END

	CLOSE cc
	DEALLOCATE cc
END

DECLARE 
	@err int,
	@loan_day_to_open smalldatetime,
	@loan_open_day smalldatetime,
	@op_id int

SELECT @op_id = OP_ID FROM dbo.LOAN_OPS 
WHERE LOAN_ID = @loan_id AND OP_TYPE IN (250, 214)

IF @op_id IS NOT NULL
BEGIN
	SELECT TOP 1 @loan_day_to_open = CALC_DATE
	FROM dbo.LOAN_DETAILS_HISTORY (NOLOCK)
	WHERE LOAN_ID = @loan_id
	ORDER BY CALC_DATE DESC

	IF (@loan_day_to_open IS NULL) OR (@loan_day_to_open < dbo.bank_open_date())
	BEGIN	
		IF @@TRANCOUNT > 0	ROLLBACK
		RAISERROR ('ÃÙÉÓ ÃÀÁÒÖÍÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÒÀÃÂÀÍ ÓÄÓáÉÓ ÀÒÓÄÁÏÁÉÓ ÁÏËÏ ÃÙÄ BANK2000-ÛÉ ÃÀáÖÒÖËÉÀ.',16,1) 
		RETURN(1) 
	END
	
	EXEC @r = dbo.LOAN_SP_DELETE_OPS @op_id, @user_id

	IF @@ERROR <> 0 OR @r <> 0
	BEGIN	
		IF @@TRANCOUNT > 0	ROLLBACK
		RAISERROR ('ÛÄÝÃÏÌÀ ÓÄÓáÉÓ ÃÀáÖÒÅÉÓ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÓ ÃÒÏÓ.',16,1) 
		RETURN(1) 
	END

	IF @@TRANCOUNT > 0	COMMIT
	RETURN(0)
END
ELSE 
IF EXISTS (SELECT * FROM dbo.LOANS WHERE LOAN_ID = @loan_id AND [STATE] = 255)
BEGIN
	IF @@TRANCOUNT > 0	ROLLBACK
	RAISERROR ('ÛÄÝÃÏÌÀ ÓÄÓáÉÓ ÃÀÁÒÖÍÄÁÉÓ ÃÒÏÓ. ÅÄÒ áÄÒáÃÄÁÀ ÛÄÓÀÁÀÌÉÓÉ ÉÍ×ÏÒÌÀÝÉÉÓ ÀÌÏÙÄÁÀ !',16,1) 
	RETURN(1)
END


SELECT @loan_open_day = CALC_DATE
FROM dbo.LOAN_DETAILS (NOLOCK)
WHERE LOAN_ID = @loan_id

SET @loan_day_to_open = @loan_open_day - 1

IF EXISTS (SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_DATE = @loan_open_day)
BEGIN
	IF @@TRANCOUNT > 0	ROLLBACK
	RAISERROR ('ÛÄÝÃÏÌÀ ÓÄÓáÉÓ ÃÀÁÒÖÍÄÁÉÓ ÃÒÏÓ. ßÀÛÀËÄÈ ÀÌ ÈÀÒÉÙÛÉ ÛÄÓÒÖËÄÁÖËÉ ÏÐÄÒÀÝÉÄÁÉ !',16,1) 
	RETURN(1)
END

EXEC @r = dbo.LOAN_SP_RETURN_LOAN_DETAILS @loan_id, @loan_day_to_open

SELECT @err = @@ERROR
IF @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN @r END
IF @err <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN @err END

SET @op_id = NULL
SELECT @op_id = MAX(OP_ID)
FROM dbo.LOAN_OPS
WHERE (LOAN_ID = @loan_id) AND (OP_TYPE IN (70, 80, 200, 170, 211))  AND (PARENT_OP_ID IS NULL OR PARENT_OP_ID = -1) AND (BY_PROCESSING = 1) AND (OP_DATE = @loan_day_to_open)

IF @op_id IS NOT NULL
BEGIN
	EXEC @r = dbo.LOAN_SP_DELETE_OPS @op_id, @user_id

	IF @@ERROR <> 0 OR @r <> 0
	BEGIN	
		IF @@TRANCOUNT > 0	ROLLBACK
		RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÄÁÉÓ ßÀÛËÉÓ ÃÒÏÓ.',16,1) 
		RETURN(1) 
	END
END

IF @@TRANCOUNT > 0	COMMIT
RETURN(0)
GO
