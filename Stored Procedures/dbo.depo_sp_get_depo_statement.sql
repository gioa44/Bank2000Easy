SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[depo_sp_get_depo_statement]
	@depo_id int,
	@date smalldatetime	= NULL,
	@result_type tinyint
AS	
SET NOCOUNT ON;

DECLARE
	@depo_start_date smalldatetime,
	@depo_end_date smalldatetime,
	@depo_annulment_date smalldatetime,
	@iso CHAR(3),
	@depo_acc_id int,
	@depo_account TACCOUNT,
	@depo_realize_acc_id int,
	@depo_realize_account TACCOUNT,
	@depo_interest_realize_acc_id int,
	@depo_interest_realize_account TACCOUNT
	
DECLARE
	@depo_accounts varchar(2000)
	
SELECT @depo_start_date = [START_DATE], @depo_end_date = END_DATE, @depo_annulment_date = ANNULMENT_DATE, @iso = ISO,
	@depo_acc_id = DEPO_ACC_ID, @depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @depo_interest_realize_acc_id = INTEREST_REALIZE_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

SELECT @depo_account = ACCOUNT FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @depo_acc_id
SELECT @depo_realize_account = ACCOUNT FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @depo_realize_acc_id
SELECT @depo_interest_realize_account = ACCOUNT FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @depo_interest_realize_acc_id

DECLARE @DEPO_ACCS TABLE (ACC_ID int NOT NULL, ISO CHAR(3) NOT NULL PRIMARY KEY (ACC_ID, ISO))

INSERT INTO @DEPO_ACCS(ACC_ID, ISO)
SELECT DISTINCT A.DEPO_ACC_ID, A.ISO
FROM (
	SELECT DEPO_ACC_ID, ISO FROM dbo.DEPO_DEPOSITS_HISTORY (NOLOCK) WHERE DEPO_ID = @depo_id
	UNION ALL
	SELECT DEPO_ACC_ID, ISO FROM dbo.DEPO_DEPOSITS (NOLOCK) WHERE DEPO_ID = @depo_id
) A

SET @depo_accounts = ''

SELECT @depo_accounts = @depo_accounts + CASE WHEN @depo_accounts = '' THEN '' ELSE '; ' END + CONVERT(varchar(15), A.ACCOUNT) + '/' + A.ISO
FROM dbo.ACCOUNTS A (NOLOCK)
	INNER JOIN @DEPO_ACCS DA ON A.ACC_ID = DA.ACC_ID

IF @result_type = 1
BEGIN
	SELECT @depo_start_date AS DEPO_START_DATE, @depo_end_date AS DEPO_END_DATE, @depo_annulment_date AS DEPO_ANNULMENT_DATE, @iso AS ISO,
		@depo_accounts AS DEPO_ACCOUNTS,
		@depo_acc_id AS DEPO_ACC_ID, @depo_account AS DEPO_ACCOUNT, @depo_realize_acc_id AS DEPO_REALIZE_ACC_ID, @depo_realize_account AS DEPO_REALIZE_ACCOUNT,
		@depo_interest_realize_acc_id AS DEPO_INTEREST_REALIZE_ACC_ID, @depo_interest_realize_account AS DEPO_INTEREST_REALIZE_ACCOUNT
	RETURN 0;
END;


SELECT D.*
INTO #docs
FROM dbo.DOCS_FULL_ALL D
	INNER JOIN @DEPO_ACCS A ON D.ACCOUNT_EXTRA = A.ACC_ID
WHERE D.DOC_DATE >= @depo_start_date
ORDER BY D.REC_ID

DECLARE @STATEMENT TABLE (
	REC_ID int NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	OP_ID int NULL,
	OP_DATE varchar(10) NOT NULL,
	OP_TYPE smallint NULL,
	OP_DESCRIP varchar(150) NULL,
	ISO CHAR(3) NULL,
	DEPOSIT_AMOUNT money NULL,
	DEPOSIT_INTEREST_AMOUNT money NULL,
	WITHDRAW_AMOUNT money NULL,
	WITHDRAW_INTEREST_AMOUNT money NULL,
	REVERT_INTEREST_AMOUNT money NULL,
	INTEREST_TAX money NULL,
	REVERT_INTEREST_TAX money NULL,
	DEPOSIT_SALDO money NULL
)

DECLARE
	@deposit_amount money,
	@deposit_interest_amount money,
	@withdraw_amount money,
	@withdraw_interest_amount money,
	@revert_interest_amount money,
	@interest_tax money,
	@revert_interest_tax money,
	@deposit_saldo money
	
SET	@deposit_amount = NULL
SET	@deposit_interest_amount = NULL
SET	@withdraw_amount = NULL
SET	@withdraw_interest_amount = NULL
SET	@revert_interest_amount = NULL
SET	@interest_tax = NULL
SET	@revert_interest_tax = NULL
SET	@deposit_saldo = NULL


SET @deposit_saldo = $0.00

DECLARE
	@op_num int,
	@doc_rec_id int,
	@doc_date smalldatetime,
	@credit_id int,
	@debit_id int,
	@amount money,
	@op_code CHAR(5),
	@doc_op_type smallint,
	@doc_op_descrip varchar(150)

DECLARE
	@op_id int,
	@op_date smalldatetime,
	@op_date_str varchar(10),
	@op_type smallint,
	@op_descrip varchar(150),
	@op_amount money,
	@op_iso CHAR(3),
	@op_doc_rec_id int,
	@op_accrue_doc_rec_id int
	
DECLARE cc CURSOR FOR
SELECT O.OP_ID, O.OP_DATE, O.OP_TYPE, T.DESCRIP, O.AMOUNT, O.ISO, O.DOC_REC_ID, O.ACCRUE_DOC_REC_ID 
FROM dbo.DEPO_OP (NOLOCK) O
	INNER JOIN dbo.DEPO_OP_TYPES (NOLOCK) T ON T.[TYPE_ID] = O.OP_TYPE
WHERE O.DEPO_ID = @depo_id
ORDER BY O.OP_ID

OPEN cc

FETCH NEXT FROM cc
INTO @op_id, @op_date, @op_type, @op_descrip, @op_amount, @op_iso, @op_doc_rec_id, @op_accrue_doc_rec_id

WHILE @@FETCH_STATUS = 0
BEGIN
	SET	@deposit_amount = NULL
	SET	@deposit_interest_amount = NULL
	SET	@withdraw_amount = NULL
	SET	@withdraw_interest_amount = NULL
	SET	@revert_interest_amount = NULL
	SET	@interest_tax = NULL
	SET	@revert_interest_tax = NULL


	IF @op_accrue_doc_rec_id IS NOT NULL
	BEGIN
		IF EXISTS (SELECT * FROM #docs WHERE OP_NUM < @op_accrue_doc_rec_id AND OP_CODE IN ('*%RL*', '*%TX*'))
		BEGIN
			DECLARE cc_docs CURSOR FOR
			SELECT OP_NUM, REC_ID, DOC_DATE, ISO, CREDIT_ID, AMOUNT, OP_CODE
			FROM #docs
			WHERE OP_NUM < @op_accrue_doc_rec_id AND OP_CODE = '*%RL*'
			ORDER BY REC_ID ASC

			OPEN cc_docs
			
			FETCH NEXT FROM cc_docs
			INTO @op_num, @doc_rec_id, @doc_date, @iso, @credit_id, @amount, @op_code
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @op_date_str = CONVERT(varchar(10), @doc_date, 103)
				
				SET	@deposit_amount = NULL
				SET	@deposit_interest_amount = NULL
				SET	@withdraw_amount = NULL
				SET	@withdraw_interest_amount = NULL
				SET	@revert_interest_amount = NULL
				SET	@interest_tax = NULL
				SET	@revert_interest_tax = NULL

				SELECT @interest_tax = AMOUNT FROM #docs WHERE OP_NUM = @op_num AND OP_CODE = '*%TX*'
				
				IF @credit_id = @depo_acc_id
				BEGIN
					SET @deposit_interest_amount = @amount
					
					SET	@deposit_saldo = @deposit_saldo + @amount - @interest_tax
					
					SET @doc_op_type = dbo.depo_fn_const_op_realize_interest()
					SELECT @doc_op_descrip = DESCRIP FROM dbo.DEPO_OP_TYPES WHERE [TYPE_ID] = @doc_op_type
				END
				ELSE
				BEGIN
					SET @withdraw_interest_amount = @amount
					
					SET @doc_op_type = dbo.depo_fn_const_op_realize_interest()
					SELECT @doc_op_descrip = DESCRIP FROM dbo.DEPO_OP_TYPES WHERE [TYPE_ID] = @doc_op_type
				END
				
				INSERT INTO @STATEMENT(OP_ID, OP_DATE, OP_TYPE, OP_DESCRIP, ISO, DEPOSIT_AMOUNT, DEPOSIT_INTEREST_AMOUNT, WITHDRAW_AMOUNT, WITHDRAW_INTEREST_AMOUNT, REVERT_INTEREST_AMOUNT, INTEREST_TAX, REVERT_INTEREST_TAX, DEPOSIT_SALDO)
				VALUES(@op_id, @op_date_str, @doc_op_type, @doc_op_descrip, @iso, @deposit_amount, @deposit_interest_amount, @withdraw_amount, @withdraw_interest_amount, @revert_interest_amount, @interest_tax, @revert_interest_tax, @deposit_saldo)
				
				FETCH NEXT FROM cc_docs
				INTO @op_num, @doc_rec_id, @doc_date, @iso, @credit_id, @amount, @op_code
			END
			
			CLOSE cc_docs
			DEALLOCATE cc_docs
		END		
	END
	IF @op_type IN (dbo.depo_fn_const_op_active(), dbo.depo_fn_const_op_accumulate())
	BEGIN
		SET @op_date_str = CONVERT(varchar(10), @op_date, 103)
		
		IF @op_type IN (dbo.depo_fn_const_op_active(), dbo.depo_fn_const_op_accumulate())
		BEGIN
			SET @deposit_saldo = @deposit_saldo + ISNULL(@op_amount, $0.00)
			
			SET	@deposit_amount = ISNULL(@op_amount, $0.00)
		END 
		INSERT INTO @STATEMENT(OP_ID, OP_DATE, OP_TYPE, OP_DESCRIP, ISO, DEPOSIT_AMOUNT, DEPOSIT_INTEREST_AMOUNT, WITHDRAW_AMOUNT, WITHDRAW_INTEREST_AMOUNT, REVERT_INTEREST_AMOUNT, INTEREST_TAX, REVERT_INTEREST_TAX, DEPOSIT_SALDO)
		VALUES(@op_id, @op_date_str, @op_type, @op_descrip, @iso, @deposit_amount, @deposit_interest_amount, @withdraw_amount, @withdraw_interest_amount, @revert_interest_amount, @interest_tax, @revert_interest_tax, @deposit_saldo)
	END
	IF @op_type IN (dbo.depo_fn_const_op_realize_interest(), dbo.depo_fn_const_op_bonus())
	BEGIN
		SET @op_date_str = CONVERT(varchar(10), @op_date, 103)

		SELECT @credit_id = CREDIT_ID
		FROM dbo.DOCS_FULL_ALL (NOLOCK)
		WHERE DOC_DATE = @op_date AND REC_ID = @op_doc_rec_id

		IF @credit_id = @depo_acc_id
		BEGIN
			SET @deposit_interest_amount = @op_amount
			SET	@deposit_saldo = @deposit_saldo + @op_amount
		END
		ELSE
			SET @withdraw_interest_amount = @op_amount

		SELECT @doc_op_descrip = DESCRIP FROM dbo.DEPO_OP_TYPES WHERE [TYPE_ID] = @op_type

		INSERT INTO @STATEMENT(OP_ID, OP_DATE, OP_TYPE, OP_DESCRIP, ISO, DEPOSIT_AMOUNT, DEPOSIT_INTEREST_AMOUNT, WITHDRAW_AMOUNT, WITHDRAW_INTEREST_AMOUNT, REVERT_INTEREST_AMOUNT, INTEREST_TAX, REVERT_INTEREST_TAX, DEPOSIT_SALDO)
		VALUES(@op_id, @op_date_str, @op_type, @op_descrip, @iso, @deposit_amount, @deposit_interest_amount, @withdraw_amount, @withdraw_interest_amount, @revert_interest_amount, @interest_tax, @revert_interest_tax, @deposit_saldo)
	END
	ELSE
	IF @op_type = dbo.depo_fn_const_op_withdraw_interest_tax()
	BEGIN
		SET @op_date_str = CONVERT(varchar(10), @op_date, 103)

		SELECT @debit_id = DEBIT_ID
		FROM dbo.DOCS_FULL_ALL (NOLOCK)
		WHERE DOC_DATE = @op_date AND REC_ID = @op_doc_rec_id

		SET @interest_tax = @op_amount

		IF @debit_id = @depo_acc_id
			SET	@deposit_saldo = @deposit_saldo - @op_amount

		SELECT @doc_op_descrip = DESCRIP FROM dbo.DEPO_OP_TYPES WHERE [TYPE_ID] = @op_type

		INSERT INTO @STATEMENT(OP_ID, OP_DATE, OP_TYPE, OP_DESCRIP, ISO, DEPOSIT_AMOUNT, DEPOSIT_INTEREST_AMOUNT, WITHDRAW_AMOUNT, WITHDRAW_INTEREST_AMOUNT, REVERT_INTEREST_AMOUNT, INTEREST_TAX, REVERT_INTEREST_TAX, DEPOSIT_SALDO)
		VALUES(@op_id, @op_date_str, @op_type, @op_descrip, @iso, @deposit_amount, @deposit_interest_amount, @withdraw_amount, @withdraw_interest_amount, @revert_interest_amount, @interest_tax, @revert_interest_tax, @deposit_saldo)
	END
	ELSE
	IF @op_type IN (dbo.depo_fn_const_op_withdraw(), dbo.depo_fn_const_op_withdraw_schedule())
	BEGIN
		SET @op_date_str = CONVERT(varchar(10), @op_date, 103)


		SELECT @withdraw_amount = AMOUNT
		FROM #docs
		WHERE REC_ID = @op_doc_rec_id AND OP_CODE = '*DCA*'
		
		SELECT @credit_id = D.CREDIT_ID, @amount = D.AMOUNT
		FROM #docs D
			INNER JOIN dbo.DOC_DETAILS_PERC P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		WHERE OP_NUM = @op_accrue_doc_rec_id AND D.OP_CODE = '*%RL*' AND ROUND(P.AMOUNT4, 2) > $0.00
		
		IF @credit_id = @depo_acc_id
			SET @deposit_interest_amount = @amount
		ELSE
			SET @withdraw_interest_amount = @amount	
			
		SELECT @interest_tax = D.AMOUNT
		FROM #docs D
			INNER JOIN dbo.DOC_DETAILS_PERC P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		WHERE OP_NUM = @op_accrue_doc_rec_id AND D.OP_CODE = '*%TX*' AND ROUND(P.AMOUNT4, 2) > $0.00
		
		SET @deposit_saldo = @deposit_saldo - ISNULL(@withdraw_amount, $0.00)


		SELECT @doc_op_descrip = DESCRIP FROM dbo.DEPO_OP_TYPES WHERE [TYPE_ID] = @op_type

		INSERT INTO @STATEMENT(OP_ID, OP_DATE, OP_TYPE, OP_DESCRIP, ISO, DEPOSIT_AMOUNT, DEPOSIT_INTEREST_AMOUNT, WITHDRAW_AMOUNT, WITHDRAW_INTEREST_AMOUNT, REVERT_INTEREST_AMOUNT, INTEREST_TAX, REVERT_INTEREST_TAX, DEPOSIT_SALDO)
		VALUES(@op_id, @op_date_str, @op_type, @op_descrip, @iso, @deposit_amount, @deposit_interest_amount, @withdraw_amount, @withdraw_interest_amount, @revert_interest_amount, @interest_tax, @revert_interest_tax, @deposit_saldo)
	END
	ELSE
	IF @op_type IN (dbo.depo_fn_const_op_annulment(), dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_annulment_positive(), dbo.depo_fn_const_op_close_default())
	BEGIN
		SET @op_date_str = CONVERT(varchar(10), @op_date, 103)
		
		SELECT @withdraw_amount = AMOUNT
		FROM #docs
		WHERE REC_ID = @op_doc_rec_id AND OP_CODE = '*DCA*'
		
		SELECT @credit_id = D.CREDIT_ID, @amount = D.AMOUNT
		FROM #docs D
			INNER JOIN dbo.DOC_DETAILS_PERC P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		WHERE OP_NUM = @op_accrue_doc_rec_id AND D.OP_CODE = '*%RL*' AND ROUND(P.AMOUNT4, 2) > $0.00
		
		IF @credit_id = @depo_acc_id
			SET @deposit_interest_amount = @amount
		ELSE
			SET @withdraw_interest_amount = @amount	

		SELECT @interest_tax = D.AMOUNT
		FROM #docs D
			INNER JOIN dbo.DOC_DETAILS_PERC P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		WHERE OP_NUM = @op_accrue_doc_rec_id AND D.OP_CODE = '*%TX*' AND ROUND(P.AMOUNT4, 2) > $0.00
		
		SELECT @revert_interest_amount = D.AMOUNT
		FROM #docs D
			INNER JOIN dbo.DOC_DETAILS_PERC P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		WHERE OP_NUM = @op_accrue_doc_rec_id AND D.OP_CODE = '*%RL*' AND D.DEBIT_ID = @credit_id AND ROUND(P.AMOUNT4, 2) < $0.00
		
		SELECT @revert_interest_tax = D.AMOUNT
		FROM #docs D
			INNER JOIN dbo.DOC_DETAILS_PERC P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		WHERE OP_NUM = @op_accrue_doc_rec_id AND D.OP_CODE = '*%RL*' AND D.DEBIT_ID <> @credit_id AND ROUND(P.AMOUNT4, 2) < $0.00

		SET @deposit_saldo = @deposit_saldo - ISNULL(@withdraw_amount, $0.00) - ISNULL(@revert_interest_amount, $0.00) + ISNULL(@revert_interest_tax, $0.00)
		
		INSERT INTO @STATEMENT(OP_ID, OP_DATE, OP_TYPE, OP_DESCRIP, ISO, DEPOSIT_AMOUNT, DEPOSIT_INTEREST_AMOUNT, WITHDRAW_AMOUNT, WITHDRAW_INTEREST_AMOUNT, REVERT_INTEREST_AMOUNT, INTEREST_TAX, REVERT_INTEREST_TAX, DEPOSIT_SALDO)
		VALUES(@op_id, @op_date_str, @op_type, @op_descrip, @iso, @deposit_amount, @deposit_interest_amount, @withdraw_amount, @withdraw_interest_amount, @revert_interest_amount, @interest_tax, @revert_interest_tax, @deposit_saldo)
	END
	ELSE
	IF @op_type = dbo.depo_fn_const_op_close()
	BEGIN
		SET @op_date_str = CONVERT(varchar(10), @op_date, 103)
		
		SELECT @withdraw_amount = AMOUNT
		FROM #docs
		WHERE REC_ID = @op_doc_rec_id AND OP_CODE = '*DCA*'
		
		SELECT @credit_id = D.CREDIT_ID, @amount = D.AMOUNT
		FROM #docs D
			INNER JOIN dbo.DOC_DETAILS_PERC P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		WHERE OP_NUM = @op_accrue_doc_rec_id AND D.OP_CODE = '*%RL*' AND ROUND(P.AMOUNT4, 2) > $0.00
		
		IF @credit_id = @depo_acc_id
			SET @deposit_interest_amount = @amount
		ELSE
			SET @withdraw_interest_amount = @amount	

		SELECT @interest_tax = D.AMOUNT
		FROM #docs D
			INNER JOIN dbo.DOC_DETAILS_PERC P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		WHERE OP_NUM = @op_accrue_doc_rec_id AND D.OP_CODE = '*%TX*' AND ROUND(P.AMOUNT4, 2) > $0.00
		
		SET @deposit_saldo = @deposit_saldo - ISNULL(@withdraw_amount, $0.00)
		
		INSERT INTO @STATEMENT(OP_ID, OP_DATE, OP_TYPE, OP_DESCRIP, ISO, DEPOSIT_AMOUNT, DEPOSIT_INTEREST_AMOUNT, WITHDRAW_AMOUNT, WITHDRAW_INTEREST_AMOUNT, REVERT_INTEREST_AMOUNT, INTEREST_TAX, REVERT_INTEREST_TAX, DEPOSIT_SALDO)
		VALUES(@op_id, @op_date_str, @op_type, @op_descrip, @iso, @deposit_amount, @deposit_interest_amount, @withdraw_amount, @withdraw_interest_amount, @revert_interest_amount, @interest_tax, @revert_interest_tax, @deposit_saldo)
	END
		
	IF @op_accrue_doc_rec_id IS NOT NULL		
	BEGIN
		DELETE FROM #docs
		WHERE OP_NUM <= @op_accrue_doc_rec_id AND OP_NUM <> @op_doc_rec_id
	END
	
	FETCH NEXT FROM cc
	INTO @op_id, @op_date, @op_type, @op_descrip, @op_amount, @op_iso, @op_doc_rec_id, @op_accrue_doc_rec_id
END

CLOSE cc
DEALLOCATE cc

DROP TABLE #docs


DECLARE
	@sum_deposit_amount money,
	@sum_deposit_interest_amount money,
	@sum_withdraw_amount money,
	@sum_withdraw_interest_amount money,
	@sum_revert_interest_amount money,
	@sum_interest_tax money,
	@sum_revert_interest_tax money
	
SELECT @sum_deposit_amount = SUM(ISNULL(DEPOSIT_AMOUNT, $0.00)), @sum_deposit_interest_amount = SUM(ISNULL(DEPOSIT_INTEREST_AMOUNT, $0.00)),
	@sum_withdraw_amount = SUM(ISNULL(WITHDRAW_AMOUNT, $0.00)), @sum_withdraw_interest_amount = SUM(ISNULL(WITHDRAW_INTEREST_AMOUNT, $0.00)),
	@sum_revert_interest_amount = SUM(ISNULL(REVERT_INTEREST_AMOUNT, $0.00)),
	@sum_interest_tax = SUM(ISNULL(INTEREST_TAX, $0.00)), @sum_revert_interest_tax = SUM(ISNULL(REVERT_INTEREST_TAX, $0.00))
FROM @STATEMENT

INSERT INTO @STATEMENT(OP_ID, OP_DATE, OP_TYPE, OP_DESCRIP, ISO, DEPOSIT_AMOUNT, DEPOSIT_INTEREST_AMOUNT, WITHDRAW_AMOUNT, WITHDRAW_INTEREST_AMOUNT, REVERT_INTEREST_AMOUNT, INTEREST_TAX, REVERT_INTEREST_TAX, DEPOSIT_SALDO)
VALUES(NULL, 'ÓÖË:', NULL, NULL, NULL, @sum_deposit_amount, @sum_deposit_interest_amount, @sum_withdraw_amount, @sum_withdraw_interest_amount, @sum_revert_interest_amount, @sum_interest_tax, @sum_revert_interest_tax, @deposit_saldo)

SELECT * FROM @STATEMENT
ORDER BY REC_ID
RETURN 0

GO
