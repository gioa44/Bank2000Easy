SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[loan_close_day]
	@date smalldatetime,
	@user_id int,
	@loan_id int,
	@close_clients_other_loans bit = 0,
	@from_global_close_day bit = 0
AS

SET NOCOUNT ON

DECLARE  
	@client_no int,
	@agr_no varchar(100),
	@msg varchar(100),
	@loan_open_date_1 smalldatetime,
	@loan_open_date_all smalldatetime,
	@_date smalldatetime

SELECT @client_no = CLIENT_NO, @agr_no = AGREEMENT_NO
FROM dbo.LOANS (NOLOCK)
WHERE LOAN_ID = @loan_id

SET @loan_open_date_1 = dbo.loan_open_date_for_loan(@loan_id)
SET @_date = DATEADD(dd, 1, @loan_open_date_1)

IF @from_global_close_day = 0
BEGIN
	IF (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'LOAN_SERVER_STATE') <> 0
	BEGIN
		SET @msg = 'ÌÉÌÃÉÍÀÒÄÏÁÓ ÓÀÓÄÓáÏ ÌÏÃÖËÉÓ ÃÙÉÓ ÃÀáÖÒÅÀ/ÂÀáÓÍÀ. ÂÈáÏÅÈ ÃÀÄËÏÃÏÈ.'
		RAISERROR (@msg, 16, 1)
		RETURN (1)
	END

	SET @loan_open_date_all = dbo.loan_open_date()

	IF @date <> @loan_open_date_1
	BEGIN
		SET @msg = 'ÓÄÓáÉÓÈÅÉÓ ÄÓ ÃÙÄ ÖÊÅÄ ÃÀÉáÖÒÀ !' + ' (ÓÄÓáÉÓ ÍÏÌÄÒÉ: ' + @agr_no + ')'
		RAISERROR (@msg, 16, 1)
		RETURN (1)
	END

	IF @loan_open_date_1 >= @loan_open_date_all -- თუ სესხის CALC_DATE ემთხვევა ღია დღეს მაშინ ამ კონკრეტული სესხის დღის დახურვას არ ვაკეთებთ
	BEGIN
		SET @msg = 'ÓÄÓáÉÓÈÅÉÓ ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ, ÓÄÓáÉÓ ÙÉÀ ÃÙÄ ÄÌÈáÅÄÅÀ ÓÀÊÒÄÃÉÔÏ ÌÏÃÖËÉÓ ÙÉÀ ÃÙÄÓ !' + ' (ÓÄÓáÉÓ ÍÏÌÄÒÉ: ' + @agr_no + ')'
		RAISERROR (@msg, 16, 1)
		RETURN (1)
	END

	-- თუ არსებობს არაავტორიზირებული ოპერაციები დღის დახურვას არ ვაკეთებთ
	IF EXISTS (SELECT * FROM dbo.LOAN_OPS (NOLOCK) WHERE LOAN_ID = @loan_id AND OP_DATE = @loan_open_date_1 AND OP_STATE <> 255)
	BEGIN
		SET @msg = 'ÀÒÀÀÅÔÏÒÉÆÉÒÄÁÖËÉ ÏÐÄÒÀÝÉÉÓ ÀÒÓÄÁÏÁÉÓ ÂÀÌÏ, ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ !' + ' (ÓÄÓáÉÓ ÍÏÌÄÒÉ: ' + @agr_no + ')'
		RAISERROR (@msg, 16, 1)
		RETURN (1)
	END
END


DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE @r int

IF (@close_clients_other_loans <> 0) AND (@from_global_close_day = 0)
BEGIN
	DECLARE @_loan_id int

	DECLARE cc CURSOR LOCAL
	FOR
	SELECT LOAN_ID
	FROM dbo.LOANS (NOLOCK)
	WHERE CLIENT_NO = @client_no AND LOAN_ID <> @loan_id AND ([STATE] >= 40 AND [STATE] < 255 )

	OPEN cc

	FETCH NEXT FROM cc INTO @_loan_id 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC @r = dbo.loan_close_day @date = @date, @user_id = @user_id, @loan_id = @_loan_id, @close_clients_other_loans = 0, @from_global_close_day = @from_global_close_day

		IF @@ERROR <> 0 OR @r <> 0
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
			RAISERROR ('ÃÙÉÓ ÃÀáÖÒÅÀ ÛÄÖÞËÄÁÄËÉÀ, ÅÄÒ áÄÒáÃÄÁÀ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÄÓáÉÓ ÃÀáÖÒÅÀ.',16,1);
			RETURN(1);
		END
		
		FETCH NEXT FROM cc INTO @_loan_id 
	END

	CLOSE cc
	DEALLOCATE cc
END


EXEC @r = dbo.loan_process @date = @date, @user_id = @user_id, @loan_id = @loan_id
IF @@ERROR <> 0 OR @r <> 0
BEGIN
	  IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
	  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
	  RETURN 1
END

------------------- ÒÉÓÊÄÁÉ -------------------
------------------–––––––––––------------------
DECLARE
	@principal money,
	@overdue_principal money,
	@calloff_date smalldatetime,
	@calloff_principal money,
	@writeoff_principal money,

	@max_category_level int,
	@category_1 money,
	@category_2 money,
	@category_3 money,           
	@category_4 money,
	@category_5 money,
	@category_6 money


SELECT 
	@principal = ISNULL(D.PRINCIPAL, $0.00), @overdue_principal = ISNULL(D.OVERDUE_PRINCIPAL, $0.00), @calloff_date = L.CALLOFF_DATE, 
	@calloff_principal = ISNULL(D.CALLOFF_PRINCIPAL, $0.00), @writeoff_principal = ISNULL(D.WRITEOFF_PRINCIPAL, $0.00)
FROM dbo.LOANS L (NOLOCK)
	INNER JOIN dbo.LOAN_DETAILS D (NOLOCK) ON L.LOAN_ID = D.LOAN_ID
WHERE L.LOAN_ID = @loan_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END
	
EXEC @r = dbo.loan_risk_analyse
	@loan_id = @loan_id,
	@date = @_date,
	@principal = @principal, 
	@principal_overdue = @overdue_principal,
	@calloff_date = @calloff_date,
	@principal_calloff = @calloff_principal,
	@principal_writeoff = @writeoff_principal,
	@category_1 = @category_1 OUTPUT,
	@category_2 = @category_2 OUTPUT,
	@category_3 = @category_3 OUTPUT,
	@category_4 = @category_4 OUTPUT,
	@category_5 = @category_5 OUTPUT,
	@category_6 = @category_6 OUTPUT,
	@max_category_level = @max_category_level OUTPUT
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

UPDATE dbo.LOAN_DETAILS
SET 
	CATEGORY_1 = CASE WHEN ISNULL(@category_1,$0.00)=$0.00 THEN NULL ELSE @category_1 END,
	CATEGORY_2 = CASE WHEN ISNULL(@category_2,$0.00)=$0.00 THEN NULL ELSE @category_2 END,
	CATEGORY_3 = CASE WHEN ISNULL(@category_3,$0.00)=$0.00 THEN NULL ELSE @category_3 END,
	CATEGORY_4 = CASE WHEN ISNULL(@category_4,$0.00)=$0.00 THEN NULL ELSE @category_4 END,
	CATEGORY_5 = CASE WHEN ISNULL(@category_5,$0.00)=$0.00 THEN NULL ELSE @category_5 END,
	CATEGORY_6 = CASE WHEN ISNULL(@category_6,$0.00)=$0.00 THEN NULL ELSE @category_6 END,
	MAX_CATEGORY_LEVEL = @max_category_level
WHERE LOAN_ID = @loan_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN(1); END

IF @from_global_close_day = 0
BEGIN
	IF @close_clients_other_loans <> 0
	BEGIN
		EXEC @r = dbo.loan_process_risks @date = @date, @user_id = @user_id, @loan_id = @loan_id

		IF @@ERROR <> 0 OR @r <> 0
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
			RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
			RETURN 1
		END
	END

	UPDATE dbo.LOAN_DETAILS_HISTORY
	SET MAX_CATEGORY_LEVEL = @max_category_level,
		CATEGORY_1 = CASE WHEN ISNULL(@category_1,$0.00)=$0.00 THEN NULL ELSE @category_1 END,
		CATEGORY_2 = CASE WHEN ISNULL(@category_2,$0.00)=$0.00 THEN NULL ELSE @category_2 END,
		CATEGORY_3 = CASE WHEN ISNULL(@category_3,$0.00)=$0.00 THEN NULL ELSE @category_3 END,
		CATEGORY_4 = CASE WHEN ISNULL(@category_4,$0.00)=$0.00 THEN NULL ELSE @category_4 END,
		CATEGORY_5 = CASE WHEN ISNULL(@category_5,$0.00)=$0.00 THEN NULL ELSE @category_5 END,
		CATEGORY_6 = CASE WHEN ISNULL(@category_6,$0.00)=$0.00 THEN NULL ELSE @category_6 END
	WHERE LOAN_ID = @loan_id AND CALC_DATE = @loan_open_date_1 --ÄÓ ÀØ ÖÊÅÄ ÉØÍÄÁÀ ßÉÍÀ ÃÙÄ, ÒÀÃÂÀÍ loan_process ÖÊÅÄ ÌÏáÃÀ

	IF @@ERROR <> 0
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
		RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ!', 16, 1)
		RETURN 1
	END
END

------------------–––––––––––------------------
------------------- ÒÉÓÊÄÁÉ -------------------

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR

GO
