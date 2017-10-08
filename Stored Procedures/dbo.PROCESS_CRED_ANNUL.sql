SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PROCESS_CRED_ANNUL]
	@acc_id int,
	@annul_date smalldatetime,
	@user_id int,
	@doc_rec_id int OUTPUT
AS


IF EXISTS(
	SELECT *
	FROM dbo.DEPTS
	WHERE CODE9 IN (
		220101757 --ÒÄÓÐÖÁËÉÊÀ
		,220101601 --VTB ãÏÒãÉÀ
		,220101722 --ÐÒÏÂÒÄÓ ÁÀÍÊÉ
		,220101912 -- ÀÆÄÒÁÀÉãÀÍÉÓ ÓÀÄÒÈÀÛÏÒÉÓÏ ÁÀÍÊÉ
	))
BEGIN
	RAISERROR ('ÄÓ ÐÒÏÝÄÃÖÒÀ ÀÒ ÂÀÌÏÉÚÄÍÄÁÀ ÈØÅÄÍÉ ÓÉÓÔÄÌÉÓÈÅÉÓ, ÃÀÒÙÅÄÅÀ ÛÄÀÓÒÖËÄÈ ÃÄÐÏÆÉÔÄÁÉÓ ÌÏÃÖËÉÃÀÍ!', 16, 1)
	RETURN 1
END

DECLARE
	@did int,
	@dno varchar(50),
	@annul_percent money,
	@start_date smalldatetime,
	@start_date_type tinyint,
	@start_date_days int,
	@date_type tinyint

DECLARE
	@dept_no int,
	@iso TISO,
	@blocked_amount money,
	@day_diff smallint,
	@realiz_acc_id int,
	@r int

SELECT @did = DEPO_ID, @dno = DEPO_NO
FROM dbo.DEPOS (NOLOCK)
WHERE ACC_ID = @acc_id

SELECT @dept_no = DEPT_NO, @iso = ISO, @blocked_amount = ISNULL(BLOCKED_AMOUNT, $0.00)
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

SELECT 
	@start_date = START_DATE, 
	@realiz_acc_id = CLIENT_ACCOUNT, 
	@start_date_type = START_DATE_TYPE, -- ÃÀÒÙÅÄÅÉÓ ÓÀßÚÉÓÉ ÈÀÒÉÙÉ
	@start_date_days = START_DATE_DAYS, -- ÂÀÓÖËÉ ÈÅÄÄÁÉ ÀÍ ÃÙÄÄÁÉ (ÃÀÌÏÊÉÃÄÁÖËÉÀ START_DATE_TYPE)
	@date_type = DATE_TYPE	-- ÅÀÃÉÓ ÔÉÐÉ
FROM dbo.ACCOUNTS_CRED_PERC 
WHERE ACC_ID = @acc_id

IF @date_type = 2	-- ÈÅÄÄÁÉ
	SET @day_diff = DATEDIFF(mm, @start_date, @annul_date - 1) + 1
ELSE				-- ÃÙÄÄÁÉ
	SET @day_diff = DATEDIFF(dd, @start_date, @annul_date)

SELECT TOP 1 @annul_percent = PERC
FROM dbo.ACCOUNTS_CRED_PERC_DETAILS
WHERE ACC_ID = @acc_id AND DAYS <= @day_diff
ORDER BY DAYS DESC

IF @annul_percent IS NULL
	SELECT TOP 1 @annul_percent = PERC
	FROM dbo.ACCOUNTS_CRED_PERC_DETAILS
	WHERE ACC_ID = @acc_id
	ORDER BY DAYS ASC

IF @annul_percent IS NULL
BEGIN
	RAISERROR ('ÌÉÌÃÉÍÀÒÄ ÐÒÏÃÖØÔÉÓÀÈÅÉÓ ÀÒ ÀÒÉÓ ÂÀÍÓÀÆÙÅÒÖËÉ ÃÀÒÙÅÄÅÉÓ ÓØÄÌÀ', 16, 1)
	RETURN 1
END

DECLARE @recalc_option tinyint
SET @recalc_option = 1 -- Recalc from beginning

IF ISNULL(@start_date_type, 0) = 2	-- ÁÏËÏ ÒÄÀËÉÆÀÝÉÀ
BEGIN
	SET @recalc_option = 2 -- Recalc from last realiz. date
END
ELSE
IF ISNULL(@start_date_type, 0) = 3	-- ÂÀáÓÍÉÃÀÍ ÂÀÓÖËÉ ÃÙÄÄÁÉ
BEGIN
	SET @start_date = DATEADD(dd, @start_date_days, @start_date)
END
ELSE
IF ISNULL(@start_date_type, 0) = 4	-- ÂÀáÓÍÉÃÀÍ ÂÀÓÖËÉ ÈÅÄÄÁÉ
BEGIN
	SET @start_date = DATEADD(mm, @start_date_days, @start_date)
END

DECLARE @formula varchar(512)
SET @formula = 'CASE WHEN AMOUNT<$0 THEN AMOUNT*-'+convert(varchar(15), @annul_percent) + ' ELSE $0 END'

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

EXEC @r = dbo.PROCESS_ACCRUAL
	@perc_type = 0,
	@acc_id = @acc_id,
	@user_id = @user_id,
	@dept_no = @dept_no,
	@doc_date = @annul_date,
	@calc_date = @annul_date,
	@force_calc = 1,
	@force_realization = 1,
	@simulate = 0,
	@formula = @formula,
	@recalc_option = @recalc_option
IF @@ERROR<>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

UPDATE dbo.ACCOUNTS_CRED_PERC
SET END_DATE = @annul_date
WHERE ACC_ID = @acc_id
IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

DECLARE @saldo money
SET @saldo = -dbo.acc_get_balance (@acc_id, @annul_date, 0, 0, 0)
DECLARE @rec_id int

IF @blocked_amount = $0.00
BEGIN
	IF (@realiz_acc_id IS NOT NULL) AND (@realiz_acc_id <> @acc_id) AND (@saldo > $0.00)
	BEGIN
		DECLARE @descrip varchar(150)
		SET @descrip = 'ÃÄÐÏÆÉÔÉÃÀÍ ÌÉÌÃÉÍÀÒÄ ÀÍÂÀÒÉÛÆÄ ÈÀÍáÉÓ ÂÀÃÀÔÀÍÀ (áÄËÛ. #'+ ISNULL(@dno, '') + ')' 

		EXEC @r = dbo.ADD_DOC4
		   @rec_id = @doc_rec_id OUTPUT
		  ,@user_id = @user_id
		  ,@doc_type = 98
		  ,@doc_date = @annul_date
		  ,@doc_date_in_doc = @annul_date
		  ,@debit_id = @acc_id
		  ,@credit_id = @realiz_acc_id
		  ,@iso = @iso
		  ,@amount = @saldo
		  ,@rec_state = 0
		  ,@descrip = @descrip
		  ,@op_code = 'CASH'
		  ,@parent_rec_id = 0
		  ,@doc_num = 0
		  ,@account_extra = @acc_id
		  ,@dept_no = @dept_no
		  ,@channel_id = 800
		  ,@flags = 6
		  ,@check_saldo = 1
		  ,@add_tariff = 0
		  ,@info = 0
		IF @@ERROR<>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		SET @saldo = $0.00
	END
END

IF @saldo = $0.00
BEGIN
	UPDATE dbo.ACCOUNTS
	SET REC_STATE = 2, DATE_CLOSE = @annul_date
	WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP)
	VALUES (@acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : REC_STATE DATE_CLOSE (ÀÍÀÁÒÉÓ ÃÀÒÙÅÄÅÀ)')
	IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		
	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END
ELSE
BEGIN
	DECLARE
		@rec_state tinyint

	SELECT @rec_state = REC_STATE
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @acc_id

	IF @rec_state = 4
	BEGIN
		UPDATE dbo.ACCOUNTS
		SET REC_STATE = 1
		WHERE ACC_ID = @acc_id
	    IF @@ERROR<>0 RETURN(1)

		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : REC_STATE (ÀÍÀÁÒÉÓ ÃÀÒÙÅÄÅÀ)')
		IF @@ERROR<>0 RETURN(1)

		SET @rec_id = SCOPE_IDENTITY()
	
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @acc_id
		IF @@ERROR<>0 RETURN(1)
	END
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN (0)
GO
