SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_correct_depo_accruals]
      @depo_id int, 
      @calc_date smalldatetime,
      @doc_date smalldatetime,
      @amount money,
      @accrual_type int,
      @user_id int
AS
BEGIN

DECLARE 
	@internal_transaction bit,
	@sign int,
	@r int,
	@rec_id int,
	@doc_type int,
	@debit_id int,
	@credit_id int,
	@iso varchar(3),
	@descrip varchar(100),
	@acc_id int,
	@dept_no int,
	@prev_date smalldatetime, 
	@prev_last_calc_date smalldatetime,
	@min_processing_date smalldatetime,
	@min_processing_total_calc_amount money,
	@account TACCOUNT

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

SET @sign = 1
IF @accrual_type = 1 SET @sign = -1

IF @amount = $0.00 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('AMOUNT ERROR!', 16, 1) RETURN(1) END

SELECT	@iso = DD.ISO, @acc_id = AP.ACC_ID, 
		@prev_last_calc_date = AP.LAST_CALC_DATE,
		@debit_id = CASE WHEN @sign = 1 THEN AP.PERC_BANK_ACCOUNT ELSE AP.PERC_CLIENT_ACCOUNT END,
		@credit_id = CASE WHEN @sign = 1 THEN AP.PERC_CLIENT_ACCOUNT ELSE AP.PERC_BANK_ACCOUNT END,
		@min_processing_date = MIN_PROCESSING_DATE, 
		@min_processing_total_calc_amount = ISNULL(MIN_PROCESSING_TOTAL_CALC_AMOUNT, $0.00)
FROM dbo.DEPO_DEPOSITS (NOLOCK) DD
	INNER JOIN dbo.ACCOUNTS_CRED_PERC (NOLOCK) AP ON AP.ACC_ID = DD.DEPO_ACC_ID
WHERE DD.DEPO_ID = @depo_id	
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR. DEPO DATA NOT FOUND!', 16, 1) RETURN(1) END

IF @doc_date < @prev_last_calc_date BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ÃÄÐÏÆÉÔÆÄ ÖÊÅÄ ÌÏáÃÀ ÃÀÒÉÝáÅÀ ÛÄÌÃÂÏÌÉ ÈÀÒÉÙÄÁÉÈ!', 16, 1) RETURN(1) END

SELECT @account = ACCOUNT
FROM dbo.ACCOUNTS (NOLOCK)A
WHERE ACC_ID = @acc_id
IF (@@ERROR <> 0) OR (@@ROWCOUNT <> 1) OR (@account IS NULL) BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR. ACCOUNT DATA NOT FOUND!', 16, 1) RETURN(1) END

SELECT @dept_no = DEPT_NO
FROM dbo.USERS (NOLOCK)
WHERE [USER_ID] = @user_id
IF (@@ERROR <> 0) OR (@@ROWCOUNT <> 1) OR (@dept_no IS NULL) BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR. USER DATA NOT FOUND!', 16, 1) RETURN(1) END

IF @accrual_type = 0
	SET @descrip = 'ÐÒÏÝÄÍÔÉÓ ÃÀÒÉÝáÅÀ'
ELSE
	SET @descrip = 'ÐÒÏÝÄÍÔÉÓ ÃÀÒÉÝáÅÉÓ ÛÄØÝÄÅÀ'	
	
SET @descrip = @descrip + ' - ' + CONVERT(varchar(34), @account) + '/' + @iso + ' (ÊÏÒÄØÝÉÀ)'

EXEC @r = dbo.ADD_DOC4
	@rec_id = @rec_id OUTPUT,			
	@user_id = @user_id,
	@owner = @user_id,
	@doc_type = 30, --@doc_type,
	@doc_date = @doc_date,
	@doc_date_in_doc = @calc_date,
	@debit_id = @debit_id,
	@credit_id = @credit_id,
	@iso = @iso,
	@amount = @amount,
	@rec_state = 20,
	@descrip = @descrip,
	@op_code = '*%AC*',
	@parent_rec_id = 0,
	@account_extra = @acc_id,
	@dept_no = @dept_no,
	@check_saldo = 0,		-- შეამოწმოს თუ არა მინ. ნაშთი
	@add_tariff = 0,		-- დაამატოს თუ არა ტარიფის საბუთი
	@info = 0				-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RAISERROR('ERROR ADD DOC!', 16, 1) RETURN(1) END

INSERT INTO dbo.DOC_DETAILS_PERC (DOC_REC_ID, ACC_ID, ID, ACCR_DATE, PREV_DATE, AMOUNT4, PREV_MIN_PROCESSING_DATE, PREV_MIN_PROCESSING_TOTAL_CALC_AMOUNT)
VALUES (@rec_id, @acc_id, @depo_id, @calc_date, @prev_date, @sign*@amount, @min_processing_date, @min_processing_total_calc_amount)
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RAISERROR('ERROR INSERT DOC_DETAILS_PERC!', 16, 1) RETURN(1) END

UPDATE dbo.ACCOUNTS_CRED_PERC
SET LAST_CALC_DATE = @calc_date, 
	CALC_AMOUNT = ISNULL(CALC_AMOUNT, $0.0000) + @sign * @amount, 
	TOTAL_CALC_AMOUNT = ISNULL(TOTAL_CALC_AMOUNT, $0.0000) + @sign * @amount
WHERE ACC_ID = @acc_id
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RAISERROR('ERROR UPDATE ACCOUNTS_CRED_PERC!', 16, 1) RETURN(1) END


IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN 0

END
GO
