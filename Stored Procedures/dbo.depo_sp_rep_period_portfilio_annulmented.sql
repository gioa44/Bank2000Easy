SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_rep_period_portfilio_annulmented]
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
	,ANNULMENT_DATE smalldatetime NOT NULL
	,ANNUL_INTRATE money NULL
	,ACCRUAL_AMOUNT money NULL
	,ACCRUAL_EQU money NULL	
	,ACCRUAL_REVERSE_AMOUNT money NULL
	,ACCRUAL_REVERSE_EQU money NULL
	,TAX_AMOUNT money NULL
	,TAX_EQU money NULL
	,TAX_REVERSE_AMOUNT money NULL
	,TAX_REVERSE_EQU money NULL
	,ACCRUAL_ANNUL_AMOUNT money NULL
	,ACCRUAL_ANNUL_EQU money NULL	
	,REALIZE_ANNUL_AMOUNT money NULL
	,REALIZE_ANNUL_EQU money NULL	
	,TAX_ANNUL_AMOUNT money NULL
	,TAX_ANNUL_EQU money NULL

	,BLOCK_AMOUNT money NULL
	,BLOCK_EQU money NULL
	,BLOCK_NOTE varchar(1000) NULL
	)

DECLARE
	@depo_id int,
	@acc_id int,
	@annul_intrate money,
	@accrual_amount money,
	@accrual_equ money,	
	@accrual_reverse_amount money,
	@accrual_reverse_equ money,
	@tax_amount money,
	@tax_equ money,
	@tax_reverse_amount money,
	@tax_reverse_equ money,
	@accrual_annul_amount money,
	@accrual_annul_equ money,
	@realize_annul_amount money,
	@realize_annul_equ money,
	@tax_annul_amount money,
	@tax_annul_equ money,
	@block_amount money,
	@block_equ money,
	@block_note varchar(1000)
	
DECLARE
	@depo_amount money,
	@days_in_year int,
	@annul_doc_rec_id int,
	@start_date smalldatetime,
	@iso CHAR(3),
	@annulment_date smalldatetime
	
DECLARE cc CURSOR FOR
SELECT D.DEPO_ID, D.START_DATE, D.AGREEMENT_AMOUNT, D.ISO, D.DEPO_ACC_ID, D.ANNULMENT_DATE, DP.DAYS_IN_YEAR 
FROM dbo.DEPO_DEPOSITS D (NOLOCK)
	INNER JOIN dbo.DEPO_PRODUCT DP (NOLOCK) ON DP.PROD_ID = D.PROD_ID
	INNER JOIN @PRODUCTS P ON D.PROD_ID = P.PROD_ID
WHERE (dbo.depo_fn_get_state_by_period(@date1, @date2, D.STATE, D.START_DATE, D.END_DATE, D.ANNULMENT_DATE, NULL) IN (240, 241, 245)) AND 
	(@agreement_no_filter IS NULL OR D.AGREEMENT_NO = @agreement_no_filter) AND 
	(@iso_filter IS NULL OR D.ISO = @iso_filter) AND 
	(@dept_no_filter IS NULL OR D.DEPO_ID = @dept_no_filter) AND
	(@user_id_filter IS NULL OR D.RESPONSIBLE_USER_ID = @user_id_filter)

OPEN cc

FETCH NEXT FROM cc INTO @depo_id, @start_date, @depo_amount, @iso, @acc_id, @annulment_date, @days_in_year
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @annul_doc_rec_id = NULL
	
	SELECT @annul_doc_rec_id = ACCRUE_DOC_REC_ID
	FROM dbo.DEPO_OP (NOLOCK)
	WHERE DEPO_ID = @depo_id AND OP_TYPE IN (240, 241, 245)
	
	SET	@accrual_amount = NULL
	SET	@accrual_equ = NULL
	SET	@accrual_reverse_amount = NULL
	SET	@accrual_reverse_equ = NULL

	SELECT @accrual_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @annulment_date) AND (O.REC_ID IS NULL OR O.REC_ID < @annul_doc_rec_id) AND
		(P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%AC*') AND (P.AMOUNT4 > $0.00)
	
	SET @accrual_equ = ROUND(dbo.get_equ(@accrual_amount, @iso, @date2), 2)
	
	SELECT @accrual_reverse_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
			INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @annulment_date) AND (O.REC_ID IS NULL OR O.REC_ID < @annul_doc_rec_id) AND
		(P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%AC*') AND (P.AMOUNT4 < $0.00)

	SET @accrual_reverse_equ = ROUND(dbo.get_equ(@accrual_reverse_amount, @iso, @date2), 2)
	

	SET @annul_intrate = NULL
	SET @accrual_annul_amount = NULL
	SET @accrual_annul_equ = NULL
	SET @realize_annul_amount = $0.00
	SET @realize_annul_equ = NULL
	
	SELECT @accrual_annul_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE = @annulment_date) AND (P.ACC_ID = @acc_id) AND (O.REC_ID IS NULL OR O.REC_ID >= @annul_doc_rec_id) AND
		(O.OP_CODE = '*%AC*') AND (P.AMOUNT4 > $0.00)
	
	SET @accrual_annul_equ = ROUND(dbo.get_equ(@accrual_annul_amount, @iso, @date2), 2)

	SELECT @realize_annul_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00)
	FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
	WHERE ACC_ID = @acc_id
	
	SET @realize_annul_equ = ROUND(dbo.get_equ(@realize_annul_amount, @iso, @date2), 2)
	
	SET @annul_intrate = dbo.depo_fn_rep_get_annulmen_interest(@start_date, @annulment_date, @days_in_year, @depo_amount, @realize_annul_amount)
		
	SET @tax_amount = NULL
	SET @tax_equ = NULL
	SET @tax_reverse_amount = NULL
	SET @tax_reverse_equ = NULL
	
	SELECT @tax_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @annulment_date) AND (O.REC_ID IS NULL OR O.REC_ID < @annul_doc_rec_id) AND
		(P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%TX*') AND (P.AMOUNT4 > $0.00)
	
	SET @tax_equ = ROUND(dbo.get_equ(@tax_amount, @iso, @date2), 2)
	
	SELECT @tax_reverse_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE BETWEEN @start_date AND @annulment_date) AND (O.REC_ID IS NULL OR O.REC_ID < @annul_doc_rec_id) AND
		(P.ACC_ID = @acc_id) AND (O.OP_CODE = '*%TX*') AND (P.AMOUNT4 < $0.00)
	
	SET @tax_reverse_equ = ROUND(dbo.get_equ(@tax_reverse_amount, @iso, @date2), 2)


	SET @tax_annul_amount = NULL
	SET @tax_annul_equ = NULL
		
	SELECT @tax_annul_amount = SUM(O.AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PERC_FULL P (NOLOCK) ON O.REC_ID = P.DOC_REC_ID
	WHERE (O.DOC_DATE = @annulment_date) AND (P.ACC_ID = @acc_id) AND (O.REC_ID IS NULL OR O.REC_ID >= @annul_doc_rec_id) AND
		(O.OP_CODE = '*%TX*') AND (P.AMOUNT4 > $0.00)
	
	SET @tax_annul_equ = ROUND(dbo.get_equ(@tax_annul_amount, @iso, @date2), 2)


	SET @block_amount = NULL
	SET @block_note = NULL
	
	SELECT @block_amount = CASE WHEN @block_amount IS NULL THEN $0.00 ELSE @block_amount END + AMOUNT,
		@block_note = CASE WHEN @block_note IS NULL THEN '' ELSE @block_note + '; ' END + CONVERT(varchar, AMOUNT) + ' - ' + ISNULL(COMMENT, 'N/A')		 
	FROM dbo.ACCOUNTS_BLOCKS (NOLOCK)
	WHERE ACC_ID = @acc_id AND IS_ACTIVE = 1
	
	SET @block_equ = ROUND(dbo.get_equ(@block_amount, @iso, @date2), 2)
	
	INSERT INTO @REPORT(DEPO_ID, ACC_ID, ANNULMENT_DATE, ANNUL_INTRATE,
		ACCRUAL_AMOUNT, ACCRUAL_EQU, ACCRUAL_REVERSE_AMOUNT, ACCRUAL_REVERSE_EQU,
		TAX_AMOUNT, TAX_EQU, TAX_REVERSE_AMOUNT, TAX_REVERSE_EQU,
		ACCRUAL_ANNUL_AMOUNT, ACCRUAL_ANNUL_EQU, REALIZE_ANNUL_AMOUNT, REALIZE_ANNUL_EQU, TAX_ANNUL_AMOUNT, TAX_ANNUL_EQU,
		BLOCK_AMOUNT, BLOCK_EQU, BLOCK_NOTE)	
	VALUES(@depo_id, @acc_id, @annulment_date, @annul_intrate,
		@accrual_amount, @accrual_equ, @accrual_reverse_amount, @accrual_reverse_equ,
		@tax_amount, @tax_equ, @tax_reverse_amount, @tax_reverse_equ,
		@accrual_annul_amount, @accrual_annul_equ, @realize_annul_amount, @realize_annul_equ, @tax_annul_amount, @tax_annul_equ,
		@block_amount, @block_equ, @block_note)

	FETCH NEXT FROM cc INTO @depo_id, @start_date, @depo_amount, @iso, @acc_id, @annulment_date, @days_in_year
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
	D.INTRATE, R.ANNUL_INTRATE AS REAL_INTRATE, D.START_DATE, D.PERIOD_DAYS, dbo.date_month_between(D.START_DATE, D.END_DATE) AS PERIOD_MONTHS, R.ANNULMENT_DATE AS ANNULMENT_DATE, D.END_DATE,
	R.ACCRUAL_AMOUNT, R.ACCRUAL_EQU, R.ACCRUAL_REVERSE_AMOUNT, R.ACCRUAL_REVERSE_EQU,
	R.ACCRUAL_ANNUL_AMOUNT, R.ACCRUAL_ANNUL_EQU, R.REALIZE_ANNUL_AMOUNT, R.REALIZE_ANNUL_EQU,
	R.TAX_AMOUNT, R.TAX_EQU, R.TAX_REVERSE_AMOUNT, R.TAX_REVERSE_EQU, R.TAX_ANNUL_AMOUNT, R.TAX_ANNUL_EQU,
	R.BLOCK_AMOUNT, R.BLOCK_EQU, R.BLOCK_NOTE, D.RESPONSIBLE_USER_ID, D.RESPONSIBLE_USER
FROM dbo.DEPO_VW_DEPO_REP_LIST D (NOLOCK)
	INNER JOIN @REPORT R ON R.DEPO_ID = D.DEPO_ID
	LEFT OUTER JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA ON CA.CLIENT_NO = D.CLIENT_NO  AND CA.ATTRIB_CODE = 'WORK_SEGMENT'
GO
