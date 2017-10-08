SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CHECK_OFF_BALANCE_ACCOUNT_LIMITS]
	@calc_day smalldatetime = NULL
AS
SET NOCOUNT ON;
DECLARE
	@user_id int
	
SET @user_id = 1 --_CLOSE_D ÃÙÉÓ ÃÀáÖÒÅÉÓ ÌÏÃÖËÉ
SET @calc_day = ISNULL(@calc_day, dbo.bank_open_date()) -- ÃÙÄ ÒÏÌËÉÓÈÅÉÓÀÝ ÃÀÀÍÂÀÒÉÛÃÄÁÀ ÀÓÀÈÅÉÓÄÁÄËÉ ÈÀÍáÄÁÉ

DECLARE
	@off_bal_st_dt smalldatetime,
	@off_balance_bal_accs varchar(255)
	
SELECT @off_bal_st_dt = CONVERT(smalldatetime, VALS)
FROM dbo.INI_DT (NOLOCK) 
WHERE IDS = 'OFF_BAL_ST_DT'

IF @off_bal_st_dt > dbo.bank_open_date()
	RETURN 0;
	
SELECT @off_balance_bal_accs = VALS
FROM dbo.INI_STR (NOLOCK) 
WHERE IDS = 'OFF_BALANCE_BAL_ACCS'

DECLARE
	@r int

DECLARE @PREV_LIMITS TABLE(
	ACC_ID int NOT NULL PRIMARY KEY,
	ISO CHAR(3) NOT NULL,
	DATE smalldatetime NOT NULL,
	BALANCE money NOT NULL,
	APPROVED_LIMIT money NOT NULL,
	DISBURSE_LIMIT money NOT NULL,
	UNDISBURSE_LIMIT money NOT NULL,
	LIMIT_MATURITY_DATE smalldatetime NULL)

DECLARE @NEXT_LIMITS TABLE(
	ACC_ID int NOT NULL PRIMARY KEY,
	ISO CHAR(3) NOT NULL,
	DATE smalldatetime NOT NULL,
	BALANCE money NOT NULL,
	APPROVED_LIMIT money NOT NULL,
	DISBURSE_LIMIT money NOT NULL,
	UNDISBURSE_LIMIT AS (case when [LIMIT_MATURITY_DATE] IS NOT NULL AND [DATE]>[LIMIT_MATURITY_DATE] then ($0.0000) when ([LIMIT_MATURITY_DATE] IS NULL OR [DATE]<=[LIMIT_MATURITY_DATE]) AND [APPROVED_LIMIT]<($0.0000) then ($0.0000) when ([LIMIT_MATURITY_DATE] IS NULL OR [DATE]<=[LIMIT_MATURITY_DATE]) AND [APPROVED_LIMIT]>=($0.0000) then case when [APPROVED_LIMIT]-[DISBURSE_LIMIT] < $0.00 then $0.00 else [APPROVED_LIMIT]-[DISBURSE_LIMIT] end end),
	LIMIT_MATURITY_DATE smalldatetime NULL)


IF EXISTS(SELECT * FROM dbo.OFF_BALANCE_ACCOUNT_LIMITS (NOLOCK) WHERE DATE = @calc_day)
BEGIN
	INSERT INTO @PREV_LIMITS(ACC_ID, ISO, DATE, BALANCE, APPROVED_LIMIT, DISBURSE_LIMIT, UNDISBURSE_LIMIT, LIMIT_MATURITY_DATE)
	SELECT ACC_ID, ISO, DATE, BALANCE, APPROVED_LIMIT, DISBURSE_LIMIT, UNDISBURSE_LIMIT, LIMIT_MATURITY_DATE
	FROM dbo.OFF_BALANCE_ACCOUNT_LIMITS (NOLOCK)
	WHERE DATE = @calc_day
	
	IF @@ERROR <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÍÀÛÈÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ',16,1); RETURN (1); END 

	
	INSERT INTO @NEXT_LIMITS(ACC_ID, ISO, DATE, BALANCE, APPROVED_LIMIT, DISBURSE_LIMIT, LIMIT_MATURITY_DATE)
	SELECT A.ACC_ID, A.ISO, L.DATE, -1 * dbo.acc_get_balance(A.ACC_ID, @calc_day, 0, 0, 0), -1 * dbo.acc_get_min_amount(A.ACC_ID, @calc_day), dbo.acc_get_disburse_limit(L.ACC_ID, L.DATE), L.LIMIT_MATURITY_DATE
	FROM dbo.ACCOUNTS A (NOLOCK)
		INNER JOIN dbo.OFF_BALANCE_ACCOUNT_LIMITS L (NOLOCK) ON A.ACC_ID = L.ACC_ID
		INNER JOIN dbo.fn_split_list_str(@off_balance_bal_accs, ',') B ON A.BAL_ACC_ALT = CONVERT(decimal(6,2) , B.ID)
	WHERE L.DATE = @calc_day
	
	IF @@ERROR <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÍÀÛÈÄÁÉÓ ÂÄÍÄÒÀÝÉÉÓÀÓ',16,1); RETURN (1); END 

	UPDATE N
		SET	N.APPROVED_LIMIT = P.APPROVED_LIMIT
			,N.DISBURSE_LIMIT = P.DISBURSE_LIMIT
			,N.LIMIT_MATURITY_DATE = P.LIMIT_MATURITY_DATE
	FROM @NEXT_LIMITS N
		INNER JOIN @PREV_LIMITS P ON N.ACC_ID = P.ACC_ID
	WHERE N.BALANCE = P.BALANCE	
	
	IF @@ERROR <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÃÀáÖÒÖËÉ ÃÙÉÓ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÍÀÛÈÄÁÉÓ ÂÄÍÄÒÀÝÉÉÓÀÓ',16,1); RETURN (1); END 
	
	UPDATE P
		SET	P.BALANCE = N.BALANCE
			,P.APPROVED_LIMIT = N.APPROVED_LIMIT
			,P.DISBURSE_LIMIT = N.DISBURSE_LIMIT
			,P.LIMIT_MATURITY_DATE = N.LIMIT_MATURITY_DATE
	FROM @NEXT_LIMITS N
		INNER JOIN dbo.OFF_BALANCE_ACCOUNT_LIMITS P (NOLOCK) ON N.ACC_ID = P.ACC_ID
	WHERE P.DATE = @calc_day AND N.BALANCE <> P.BALANCE	
	
	IF @@ERROR <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÃÀáÖÒÖËÉ ÃÙÉÓ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÍÀÛÈÄÁÉÓ ÂÄÍÄÒÀÝÉÉÓÀÓ',16,1); RETURN (1); END 
END
ELSE
BEGIN
	INSERT INTO @NEXT_LIMITS(ACC_ID, ISO, DATE, BALANCE, APPROVED_LIMIT, DISBURSE_LIMIT, LIMIT_MATURITY_DATE)
	SELECT A.ACC_ID, A.ISO, @calc_day, -1 * dbo.acc_get_balance(A.ACC_ID, @calc_day, 0, 0, 0), -1 * dbo.acc_get_min_amount(A.ACC_ID, @calc_day), dbo.acc_get_disburse_limit(A.ACC_ID, @calc_day), A.MIN_AMOUNT_CHECK_DATE  
	FROM dbo.ACCOUNTS A (NOLOCK)
		INNER JOIN dbo.fn_split_list_str(@off_balance_bal_accs, ',') B ON A.BAL_ACC_ALT = CONVERT(decimal(6,2) , B.ID)
	WHERE A.REC_STATE NOT IN (2, 128) AND dbo.acc_get_min_amount(A.ACC_ID, @calc_day) < $0.00 AND (A.MIN_AMOUNT_CHECK_DATE IS NULL OR A.MIN_AMOUNT_CHECK_DATE > @calc_day)
	IF @@ERROR <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÍÀÛÈÄÁÉÓ ÂÄÍÄÒÀÝÉÉÓÀÓ',16,1); RETURN (1); END 

	INSERT INTO dbo.OFF_BALANCE_ACCOUNT_LIMITS(ACC_ID, ISO, DATE, BALANCE, APPROVED_LIMIT, DISBURSE_LIMIT, LIMIT_MATURITY_DATE)
	SELECT ACC_ID, ISO, DATE, BALANCE, APPROVED_LIMIT, DISBURSE_LIMIT, LIMIT_MATURITY_DATE
	FROM @NEXT_LIMITS
	IF @@ERROR <> 0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÉ ÍÀÛÈÄÁÉÓ ÂÄÍÄÒÀÝÉÉÓÀÓ',16,1); RETURN (1); END 
END

DECLARE
	@branch_id int,
	@iso CHAR(3),
	@undisburse_limit money,
	@account_balance money,
	@acc_id int

DECLARE
	@rec_id int,
	@doc_date smalldatetime,
	@amount money,
	@debit_id int,
	@credit_id int,
	@descrip varchar(150)
	
DECLARE
	@debit_dept int,
	@debit TACCOUNT,
	@credit_dept int,
	@credit TACCOUNT,
	@bank_head_branch_id int


SET @bank_head_branch_id = dbo.bank_head_branch_id()
	
SET @doc_date = @calc_day

DECLARE cc CURSOR FOR
SELECT A.BRANCH_ID, L.ISO, SUM(UNDISBURSE_LIMIT)
FROM @NEXT_LIMITS L
	INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = L.ACC_ID 
GROUP BY A.BRANCH_ID, L.ISO

OPEN cc

FETCH NEXT FROM cc INTO @branch_id, @iso, @undisburse_limit

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @credit_id = NULL
	SET @debit_id = NULL
	SET @account_balance = NULL
	
	SELECT @debit_dept = OFF_BAL_DEBIT_DEPT, @debit = CASE WHEN @iso = 'GEL' THEN OFF_BAL_DEBIT_ACC ELSE OFF_BAL_DEBIT_ACC_V END,
		@credit_dept = OFF_BAL_CREDIT_DEPT, @credit = CASE WHEN @iso = 'GEL' THEN OFF_BAL_CREDIT_ACC ELSE OFF_BAL_CREDIT_ACC_V END
	FROM dbo.DEPTS (NOLOCK)
	WHERE BRANCH_ID = @branch_id AND DEPT_NO = @branch_id

	IF @credit_dept = 0
	BEGIN
		SET @credit_id = dbo.acc_get_acc_id(@bank_head_branch_id, @credit, @iso)
		SET @account_balance = -1 * dbo.acc_get_balance(@credit_id, @calc_day, 0, 0, 0)	
	END		
	ELSE
	BEGIN
		SET @credit_id = dbo.acc_get_acc_id(@branch_id, @credit, @iso)
		SET @account_balance = -1 * dbo.acc_get_balance(@credit_id, @calc_day, 0, 0, 0)	
	END		
	
	IF @@ERROR <> 0 OR @credit_id IS NULL BEGIN CLOSE cc; DEALLOCATE cc; RAISERROR('ÛÄÝÃÏÌÀ ÊÒÄÃÉÔÉÓ ÀÍÂÀÒÉÛÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ',16,1); RETURN (1); END 
	
	
	SET @amount = @undisburse_limit - @account_balance 
	
	IF @amount = $0.00 GOTO _next
	
	IF @debit_dept = 0
		SET @debit_id = dbo.acc_get_acc_id(@bank_head_branch_id, @debit, @iso)
	ELSE
		SET @debit_id = dbo.acc_get_acc_id(@branch_id, @debit, @iso)
	
	IF @@ERROR <> 0 OR @debit_id IS NULL BEGIN CLOSE cc; DEALLOCATE cc; RAISERROR('ÛÄÝÃÏÌÀ ÃÄÁÄÔÉÓ ÀÍÂÀÒÉÛÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ',16,1); RETURN (1); END 
	
	IF @amount < $0.00
	BEGIN
		SET @acc_id = @debit_id
		SET @debit_id = @credit_id
		SET @credit_id = @acc_id
		SET @amount = -@amount

		SET @descrip = 'ÂÀÒÄÁÀËÀÍÓÖÒÉÃÀÍ ÈÀÍáÉÓ ÃÀÁÒÖÍÄÁÀ /' + @iso + '/ ' + CONVERT(varchar(50), @account_balance) + ' >> '  + CONVERT(varchar(50), @account_balance - @amount)
	END
	ELSE
	BEGIN
		SET @descrip = 'ÂÀÒÄÁÀËÀÍÓÖÒÆÄ ÈÀÍáÉÓ ÂÀÔÀÍÀ /' + @iso + '/ ' + CONVERT(varchar(50), @account_balance) + ' >> '  + CONVERT(varchar(50), @account_balance + @amount)
	END
	
	EXEC @r = dbo.ADD_DOC4
		@rec_id				= @rec_id OUTPUT,
		@user_id			= @user_id,
		@doc_type			= 200, 
		@doc_date			= @doc_date,
		@doc_date_in_doc	= @doc_date,
		@debit_id			= @debit_id,
		@credit_id			= @credit_id,
		@iso				= @iso, 
		@amount				= @amount,
		@rec_state			= 20,
		@descrip			= @descrip,
		@op_code			= '*OOV*',
		@check_saldo		= 1,
		@add_tariff			= 0,
		@info				= 0
	
	IF @@ERROR <> 0 OR @r <> 0 BEGIN CLOSE cc; DEALLOCATE cc; RAISERROR('ÛÄÝÃÏÌÀ ÂÀÒÄÁÀËÀÍÓÖÒÆÄ ÈÀÍáÉÓ ÂÀÔÀÍÀ/ÃÀÁÒÖÍÄÁÉÓ ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÉÓÀÓ',16,1); RETURN (1); END 		
_next:
	FETCH NEXT FROM cc INTO @branch_id, @iso, @undisburse_limit
END

CLOSE cc
DEALLOCATE cc

RETURN 0
GO
