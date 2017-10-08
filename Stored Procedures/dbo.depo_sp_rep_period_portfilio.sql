SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_rep_period_portfilio]
	@date1 smalldatetime,
	@date2 smalldatetime,
	@agreement_no_filter varchar(100) = NULL,
	@iso_filter CHAR(3) = NULL,
	@dept_no_filter int = NULL,
	@product_filter varchar(255) = NULL,
	@user_id_filter int = NULL
AS

SET NOCOUNT ON;


DECLARE @PRODUCTS TABLE(PROD_ID int NOT NULL PRIMARY KEY)

IF @product_filter IS NULL
	INSERT INTO @PRODUCTS(PROD_ID)
	SELECT PROD_ID FROM dbo.DEPO_PRODUCT (NOLOCK)
ELSE
	INSERT INTO @PRODUCTS(PROD_ID)
	SELECT [ID] FROM dbo.fn_split_list_int(@product_filter, default)
	
DECLARE @REPORT TABLE
	(DEPO_ID int NOT NULL
	,ACC_ID int NOT NULL
	,DEPO_SALDO_START money NULL
	,DEPO_SALDO_START_EQU money NULL
	,DEPO_CREDIT_AMOUNT money NULL
	,DEPO_CREDIT_EQU money NULL
	,DEPO_DEBIT_AMOUNT money NULL
	,DEPO_DEBIT_EQU money NULL
	,DEPO_SALDO_END money NULL
	,DEPO_SALDO_END_EQU money NULL
	,TOTAL_ACCRUAL_AMOUNT money NULL
	,TOTAL_ACCRUAL_EQU money NULL	
	,TOTAL_ACCRUAL_REVERSE_AMOUNT money NULL
	,TOTAL_ACCRUAL_REVERSE_EQU money NULL	
	,REALIZE_AMOUNT money NULL
	,REALIZE_EQU money NULL	
	,REALIZE_REVERSE_AMOUNT money NULL
	,REALIZE_REVERSE_EQU money NULL
	,ACCRUAL_AMOUNT money NULL
	,ACCRUAL_EQU money NULL
	,REALIZE_ADV_AMOUNT money NULL
	,REALIZE_ADV_EQU money NULL
	,REALIZE_ADV_SALDO money NULL
	,REALIZE_ADV_SALDO_EQU money NULL
	,TAX_AMOUNT money NULL
	,TAX_EQU money NULL
	,TAX_REVERSE_AMOUNT money NULL
	,TAX_REVERSE_EQU money NULL
	,LAST_REALIZE_DATE smalldatetime NULL
	,BLOCK_AMOUNT money NULL
	,BLOCK_EQU money NULL
	,BLOCK_NOTE varchar(1000) NULL
	)

DECLARE
	@depo_id int,
	@acc_id int,
	@depo_saldo_start money,
	@depo_saldo_start_equ money,
	@depo_credit_amount money,
	@depo_credit_equ money,
	@depo_debit_amount money,
	@depo_debit_equ money,
	@depo_saldo_end money,
	@depo_saldo_end_equ money,
	@total_accrual_amount money,
	@total_accrual_equ money,	
	@total_accrual_reverse_amount money,
	@total_accrual_reverse_equ money,
	@realize_amount money,
	@realize_equ money,	
	@realize_reverse_amount money,
	@realize_reverse_equ money,
	@accrual_amount money,
	@accrual_equ money,
	@realize_adv_amount money,
	@realize_adv_equ money,
	@realize_adv_saldo money,
	@realize_adv_saldo_equ money,
	@tax_amount money,
	@tax_equ money,
	@tax_reverse_amount money,
	@tax_reverse_equ money,
	@last_realize_date smalldatetime,
	@block_amount money,
	@block_equ money,
	@block_note varchar(1000)
	
DECLARE
	@start_date smalldatetime,
	@iso CHAR(3),
	@interest_realize_adv bit,
	@interest_realize_adv_op_id int,
	@convertible bit

DECLARE cc CURSOR FOR
SELECT D.DEPO_ID, D.START_DATE, D.ISO, D.DEPO_ACC_ID, D.INTEREST_REALIZE_ADV, D.CONVERTIBLE
FROM dbo.DEPO_DEPOSITS D (NOLOCK)
	INNER JOIN @PRODUCTS P ON D.PROD_ID = P.PROD_ID
	LEFT OUTER JOIN dbo.DEPO_OP O (NOLOCK) ON (O.DEPO_ID = D.DEPO_ID) AND (O.OP_TYPE IN (248, 250))
WHERE (dbo.depo_fn_get_state_by_period(@date1, @date2, D.STATE, D.START_DATE, D.END_DATE, D.ANNULMENT_DATE, O.OP_DATE) IN (50, 250)) AND 
	(@agreement_no_filter IS NULL OR D.AGREEMENT_NO = @agreement_no_filter) AND 
	(@iso_filter IS NULL OR D.ISO = @iso_filter) AND 
	(@dept_no_filter IS NULL OR D.DEPO_ID = @dept_no_filter) AND
	(@user_id_filter IS NULL OR D.RESPONSIBLE_USER_ID = @user_id_filter)

OPEN cc

FETCH NEXT FROM cc INTO @depo_id, @start_date, @iso, @acc_id, @interest_realize_adv, @convertible

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @depo_saldo_start = NULL
	SET @depo_saldo_start_equ = NULL
	SET @depo_credit_amount = NULL
	SET @depo_credit_equ = NULL
	SET @depo_debit_amount = NULL
	SET @depo_debit_equ = NULL
	SET @depo_saldo_end = NULL
	SET @depo_saldo_end_equ = NULL
	
	
	SET @depo_saldo_start = -dbo.acc_get_balance(@acc_id, @date1, 0, 0, 0)
	SET @depo_saldo_start_equ = ROUND(dbo.get_equ(@depo_saldo_start, @iso, @date1), 2)
	
	SELECT @depo_credit_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.OPS_HELPER_FULL H (NOLOCK) ON O.REC_ID = H.REC_ID
	WHERE (H.ACC_ID = @acc_id) AND (H.DT BETWEEN @date1 AND @date2) AND (O.CREDIT_ID = @acc_id)
	
	SET @depo_credit_equ = ROUND(dbo.get_equ(@depo_credit_amount, @iso, @date2), 2)
	
	SELECT @depo_debit_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.OPS_HELPER_FULL H (NOLOCK) ON O.REC_ID = H.REC_ID
	WHERE (H.ACC_ID = @acc_id) AND (H.DT BETWEEN @date1 AND @date2) AND (O.DEBIT_ID = @acc_id)
	
	SET @depo_debit_equ = ROUND(dbo.get_equ(@depo_debit_amount, @iso, @date2), 2)
	
	SET @depo_saldo_end = -dbo.acc_get_balance(@acc_id, @date2, 0, 0, 0)
	SET @depo_saldo_end_equ = ROUND(dbo.get_equ(@depo_saldo_end, @iso, @date2), 2)
	
	SET	@total_accrual_amount = NULL
	SET	@total_accrual_equ = NULL
	SET	@total_accrual_reverse_amount = NULL
	SET	@total_accrual_reverse_equ = NULL

	SELECT @total_accrual_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @date2) AND (P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%AC*') AND (P.AMOUNT4 > $0.00)
	
	SET @total_accrual_equ = ROUND(dbo.get_equ(@total_accrual_amount, @iso, @date2), 2)
	
	SELECT @total_accrual_reverse_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
			INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @date2) AND (P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%AC*') AND (P.AMOUNT4 < $0.00)
	
	SET @total_accrual_reverse_equ = ROUND(dbo.get_equ(@total_accrual_reverse_amount, @iso, @date2), 2)
	
	
	SET	@realize_amount = NULL
	SET	@realize_equ = NULL
	SET	@realize_reverse_amount = NULL
	SET	@realize_reverse_equ = NULL
	SET @last_realize_date = NULL

	SELECT @realize_amount = SUM(O.AMOUNT), @last_realize_date = MAX(DOC_DATE)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @date2) AND (P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%RL*') AND (P.AMOUNT4 > $0.00)
	
	SET @realize_equ = ROUND(dbo.get_equ(@realize_amount, @iso, @date2), 2)
	
	SELECT @realize_reverse_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
			INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @date2) AND (P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%RL*') AND (P.AMOUNT4 < $0.00)

	SET @realize_reverse_equ = ROUND(dbo.get_equ(@realize_reverse_amount, @iso, @date2), 2)
	
	SET @accrual_amount = (ISNULL(@total_accrual_amount, $0.00) - ISNULL(@total_accrual_reverse_amount, $0.00)) -
		(ISNULL(@realize_amount, $0.00) - ISNULL(@total_accrual_reverse_amount, $0.00))
	
	SET @accrual_equ = (ISNULL(@total_accrual_equ, $0.00) - ISNULL(@total_accrual_reverse_equ, $0.00)) -
		(ISNULL(@realize_equ, $0.00) - ISNULL(@total_accrual_reverse_equ, $0.00))
		
	SET @interest_realize_adv_op_id = NULL
	SET @realize_adv_amount = NULL
	SET @realize_adv_equ = NULL
	SET @realize_adv_saldo = NULL
	SET @realize_adv_saldo_equ = NULL
	
	IF @interest_realize_adv = 1
	BEGIN
		SELECT @interest_realize_adv_op_id = MIN(OP_ID)
		FROM dbo.DEPO_OP (NOLOCK)
		WHERE DEPO_ID = @depo_id
		
		SELECT @realize_adv_amount = O.AMOUNT
		FROM dbo.OPS_FULL O (NOLOCK)
			INNER JOIN dbo.DEPO_OP P (NOLOCK) ON O.DOC_DATE = P.OP_DATE AND O.PARENT_REC_ID = P.DOC_REC_ID
		WHERE (P.OP_ID = @interest_realize_adv_op_id) AND (O.OP_CODE = '*%RL*')
		
		SET @realize_adv_equ = ROUND(dbo.get_equ(@realize_adv_amount, @iso, @date2), 2)
		
		SET @realize_adv_saldo = ISNULL(@realize_adv_amount, $0.00) - ISNULL(@realize_amount, $0.00)
		SET @realize_adv_saldo_equ = ROUND(dbo.get_equ(@realize_adv_saldo, @iso, @date2), 2)
	END

	SET @tax_amount = NULL
	SET @tax_equ = NULL
	SET @tax_reverse_amount = NULL
	SET @tax_reverse_equ = NULL
	
	SELECT @tax_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @date2) AND (P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%TX*') AND (P.AMOUNT4 > $0.00)
	
	SET @tax_equ = ROUND(dbo.get_equ(@tax_amount, @iso, @date2), 2)
	
	SELECT @tax_reverse_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @date2) AND (P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%TX*') AND (P.AMOUNT4 < $0.00)
	
	SET @tax_reverse_equ = ROUND(dbo.get_equ(@tax_reverse_amount, @iso, @date2), 2)
	
	
	SET @block_amount = NULL
	SET @block_note = NULL
	
	SELECT @block_amount = CASE WHEN @block_amount IS NULL THEN $0.00 ELSE @block_amount END + AMOUNT,
		@block_note = CASE WHEN @block_note IS NULL THEN '' ELSE @block_note + '; ' END + CONVERT(varchar, AMOUNT) + ' - ' + ISNULL(COMMENT, 'N/A')		 
	FROM dbo.ACCOUNTS_BLOCKS (NOLOCK)
	WHERE ACC_ID = @acc_id AND IS_ACTIVE = 1
	
	SET @block_equ = ROUND(dbo.get_equ(@block_amount, @iso, @date2), 2)
	
	INSERT INTO @REPORT(DEPO_ID, ACC_ID, DEPO_SALDO_START, DEPO_SALDO_START_EQU, DEPO_SALDO_END, DEPO_SALDO_END_EQU, DEPO_CREDIT_AMOUNT, DEPO_CREDIT_EQU, DEPO_DEBIT_AMOUNT, DEPO_DEBIT_EQU,
		TOTAL_ACCRUAL_AMOUNT, TOTAL_ACCRUAL_EQU, TOTAL_ACCRUAL_REVERSE_AMOUNT, TOTAL_ACCRUAL_REVERSE_EQU,
		REALIZE_AMOUNT, REALIZE_EQU, REALIZE_REVERSE_AMOUNT, REALIZE_REVERSE_EQU,
		ACCRUAL_AMOUNT, ACCRUAL_EQU, REALIZE_ADV_AMOUNT, REALIZE_ADV_EQU, REALIZE_ADV_SALDO, REALIZE_ADV_SALDO_EQU,
		TAX_AMOUNT, TAX_EQU, TAX_REVERSE_AMOUNT, TAX_REVERSE_EQU,
		LAST_REALIZE_DATE, BLOCK_AMOUNT, BLOCK_EQU, BLOCK_NOTE)	
	VALUES(@depo_id, @acc_id, @depo_saldo_start, @depo_saldo_start_equ, @depo_saldo_end, @depo_saldo_end_equ, @depo_credit_amount, @depo_credit_equ, @depo_debit_amount, @depo_debit_equ,
		@total_accrual_amount, @total_accrual_equ, @total_accrual_reverse_amount, @total_accrual_reverse_equ,
		@realize_amount, @realize_equ, @realize_reverse_amount, @realize_reverse_equ,
		@accrual_amount, @accrual_equ, @realize_adv_amount, @realize_adv_equ, @realize_adv_saldo, @realize_adv_saldo_equ,
		@tax_amount, @tax_equ, @tax_reverse_amount, @tax_reverse_equ,
		@last_realize_date, @block_amount, @block_equ, @block_note)

	FETCH NEXT FROM cc INTO @depo_id, @start_date, @iso, @acc_id, @interest_realize_adv, @convertible
END

CLOSE cc
DEALLOCATE cc

SELECT D.DEPO_ID, D.STATE, D.DEPT_NO, D.ALIAS, D.DEPT_DESCRIP,
	D.CLIENT_NO, D.CLIENT_DESCRIP, D.COUNTRY, D.IS_RESIDENT, D.IS_INSIDER, D.TAX_INSP_CODE,
	D.CLIENT_TYPE, D.CLIENT_TYPE_DESCRIP, D.CLIENT_SUBTYPE, D.CLIENT_SUBTYPE_DESCRIP, D.CLIENT_SUBTYPE2_DESCRIP, CA.ATTRIB_VALUE AS CLIENT_SEGMENT,		
	D.PROD_ID, D.PROD_CODE, D.PROD_NO, D.PROD_DESCRIP,
	D.AGREEMENT_NO, D.DEPO_ACC_ID, D.DEPO_ACCOUNT,	D.DEPO_ACCOUNT_BAL_ACC,	D.ISO,
	D.ACCRUAL_ACC_ID, D.ACCRUAL_ACCOUNT, D.ACCRUAL_ACCOUNT_BAL_ACC,
	D.AGREEMENT_AMOUNT, ROUND(dbo.get_equ(D.AGREEMENT_AMOUNT, D.ISO, @date2), 2) AS AGREEMENT_EQU, D.AMOUNT, ROUND(dbo.get_equ(D.AMOUNT, D.ISO, @date2), 2) AS AMOUNT_EQU,
	D.INTRATE, D.REAL_INTRATE, D.START_DATE, D.PERIOD_DAYS, dbo.date_month_between(D.START_DATE, D.END_DATE) AS PERIOD_MONTHS, D.END_DATE,
	DATEDIFF(day, @date2, D.END_DATE) AS DAYS_UNTIL_END, dbo.date_month_between(@date2, D.END_DATE) AS MONTHS_UNTIL_END,
	R.DEPO_SALDO_START, R.DEPO_SALDO_START_EQU, R.DEPO_CREDIT_AMOUNT, R.DEPO_CREDIT_EQU, R.DEPO_DEBIT_AMOUNT, R.DEPO_DEBIT_EQU, R.DEPO_SALDO_END, R.DEPO_SALDO_END_EQU,
	R.TOTAL_ACCRUAL_AMOUNT, R.TOTAL_ACCRUAL_EQU, R.TOTAL_ACCRUAL_REVERSE_AMOUNT, R.TOTAL_ACCRUAL_REVERSE_EQU,
	R.REALIZE_AMOUNT, R.REALIZE_EQU, R.REALIZE_REVERSE_AMOUNT, R.REALIZE_REVERSE_EQU,	R.ACCRUAL_AMOUNT, R.ACCRUAL_EQU, 
	R.REALIZE_ADV_AMOUNT, R.REALIZE_ADV_EQU, R.REALIZE_ADV_SALDO, R.REALIZE_ADV_SALDO_EQU,
	R.TAX_AMOUNT, R.TAX_EQU, R.TAX_REVERSE_AMOUNT, R.TAX_REVERSE_EQU,
	R.LAST_REALIZE_DATE,
	CASE D.REALIZE_TYPE
		WHEN 1 THEN
			CASE D.REALIZE_COUNT_TYPE
				WHEN 1 THEN 'ÚÏÅÄË ' + CONVERT(varchar, D.REALIZE_COUNT) + ' ÃÙÄÛÉ'
				WHEN 2 THEN 'ÚÏÅÄË ' + CONVERT(varchar, D.REALIZE_COUNT) + ' ÈÅÄÛÉ'
				WHEN 3 THEN 'ÚÏÅÄË ' + CONVERT(varchar, D.REALIZE_COUNT) + ' ÈÅÄÛÉ (30)'
			END
		WHEN 2 THEN
			CASE D.REALIZE_COUNT_TYPE
				WHEN 1 THEN 'ÅÀÃÉÓ ÁÏËÏÓ'
				ELSE 'ÚÏÅÄËÉ ' + CONVERT(varchar, D.REALIZE_COUNT) + ' ÈÅÉÓ ÁÏËÏÓ'
			END
		WHEN 3 THEN
			'ÃÀÒÉÝáÅÉÓÀÓ'	
		WHEN 4 THEN
			'ÀÒÀÓÏÃÄÓ'
		ELSE NULL
	END AS REALIZE_PERIOD,	
	D.PERC_FLAGS, D.REALIZE_TYPE, D.REALIZE_COUNT, D.REALIZE_COUNT_TYPE,
	CASE WHEN D.STATE = 50 THEN dbo.depo_fn_get_next_realization_date(@date2, D.START_DATE, D.END_DATE, D.REALIZE_TYPE, D.REALIZE_COUNT, D.REALIZE_COUNT_TYPE, D.PERC_FLAGS) ELSE NULL END AS NEXT_REALIZATION_DATE, 
	R.BLOCK_AMOUNT, R.BLOCK_EQU, R.BLOCK_NOTE, D.RESPONSIBLE_USER_ID, D.RESPONSIBLE_USER
FROM dbo.DEPO_VW_DEPO_REP_LIST D (NOLOCK)
	INNER JOIN @REPORT R ON R.DEPO_ID = D.DEPO_ID
	LEFT OUTER JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA ON CA.CLIENT_NO = D.CLIENT_NO  AND CA.ATTRIB_CODE = 'WORK_SEGMENT'

GO
