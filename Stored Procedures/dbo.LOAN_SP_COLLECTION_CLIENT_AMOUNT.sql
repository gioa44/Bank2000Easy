SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_COLLECTION_CLIENT_AMOUNT]
	@user_id int,
	@date smalldatetime,
	@loan_id int,
	@iso TISO,
	@acc_id int,
	@client_no int,
	@debt_amount money,
	@simulate bit = 0,
	@client_amount money OUTPUT
AS
SET NOCOUNT ON;

DECLARE
	@r int


CREATE TABLE #acc_balance
(
	PRIORITY_ID	int NOT NULL PRIMARY KEY,
	ACC_ID int NOT NULL,
	ISO char(3) NOT NULL,
	AMOUNT money NOT NULL,
	AMOUNT_EQU money NULL,
	ACC_TYPE tinyint NULL,
	ACC_SUBTYPE int NULL,
	RATE_AMOUNT money NULL,
	RATE_ITEMS int NULL,
	RATE_REVERSE bit NULL,
	DOC_REC_ID int NULL
)

DECLARE
	@acc_overlimit_amount money

EXEC  @r = dbo.ON_USER_BEFORE_LOAN_SP_COLLECTION_CLIENT_AMOUNT
	@user_id = @user_id,
	@date = @date,
	@loan_id = @loan_id,
	@iso = @iso,
	@acc_id = @acc_id,
	@client_no = @client_no,
	@debt_amount = @debt_amount,
	@acc_overlimit_amount = @acc_overlimit_amount out,
	@simulate = @simulate
IF @@ERROR<>0 OR @r<>0 BEGIN DROP TABLE #acc_balance; RETURN @r END

SET @client_amount = -@acc_overlimit_amount

DECLARE
	@internal_transaction bit

DECLARE
	@parent_rec_id int,
	@rec_id_1 int,
	@rec_id_2 int

DECLARE
	@rate_amount money,
	@rate_items int,
	@rate_reverse bit

SET @internal_transaction = 0
IF @simulate = 0 AND @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

CREATE TABLE #docs
(
	REC_ID int PRIMARY KEY NOT NULL IDENTITY (1,1),
	PRIORITY_ID int NOT NULL,
	DEBIT_ID int NOT NULL,
	CREDIT_ID int NOT NULL,
	ISO char(3)	NOT NULL,
	AMOUNT	money NOT NULL,
	ISO2 char(3) NULL,
	AMOUNT2	money NULL,
	RATE_AMOUNT money NULL,
	RATE_ITEMS int NULL,
	RATE_REVERSE bit NULL
)

DECLARE
	@agreement_no varchar(100),
	@doc_descrip varchar(150),
	@conv_doc_descrip varchar(150)

SELECT @agreement_no = AGREEMENT_NO
FROM dbo.LOANS (NOLOCK)
WHERE LOAN_ID = @loan_id

SET @doc_descrip = 'ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÃÀÓÀ×ÀÒÀÃ (# ' + @agreement_no + ')'

DECLARE
	@c_acc_priority_id int,
	@c_acc_acc_id int,
	@c_acc_iso char(3),
	@c_acc_amount money,
	@c_acc_amount_equ money


DECLARE c_acc CURSOR FOR
SELECT PRIORITY_ID, ACC_ID, ISO, AMOUNT, AMOUNT_EQU, RATE_AMOUNT, RATE_ITEMS, RATE_REVERSE
FROM #acc_balance
ORDER BY PRIORITY_ID

OPEN c_acc
FETCH NEXT FROM c_acc
INTO @c_acc_priority_id, @c_acc_acc_id,	@c_acc_iso,	@c_acc_amount, @c_acc_amount_equ, @rate_amount, @rate_items, @rate_reverse

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @client_amount = @client_amount + ISNULL(@c_acc_amount_equ, @c_acc_amount)

	IF @c_acc_acc_id = @acc_id GOTO _next  

	INSERT INTO #docs(PRIORITY_ID, DEBIT_ID, CREDIT_ID, ISO, AMOUNT, ISO2, AMOUNT2, RATE_AMOUNT, RATE_ITEMS, RATE_REVERSE)
	VALUES (@c_acc_priority_id, @c_acc_acc_id, @acc_id, @c_acc_iso, @c_acc_amount, @iso, @c_acc_amount_equ, @rate_amount, @rate_items, @rate_reverse)
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN CLOSE c_acc; DEALLOCATE c_acc; GOTO _ret_err; END

_next:
	FETCH NEXT FROM c_acc
	INTO @c_acc_priority_id, @c_acc_acc_id,	@c_acc_iso,	@c_acc_amount, @c_acc_amount_equ, @rate_amount, @rate_items, @rate_reverse
END

CLOSE c_acc
DEALLOCATE c_acc

IF (@client_amount < $0.00)
	SET @client_amount = $0.00

IF @simulate <> 0 GOTO _skip_docs

SET @parent_rec_id = CASE WHEN ISNULL(@c_acc_priority_id, 0) > 1 THEN -1 ELSE 0 END

DECLARE
	@c_docs_priority_id int,
	@c_docs_debit_id int,
	@c_docs_credit_id int,
	@c_docs_iso char(3),
	@c_docs_amount money,
	@c_docs_iso2 char(3),
	@c_docs_amount2 money

DECLARE c_docs CURSOR FOR
SELECT PRIORITY_ID, DEBIT_ID, CREDIT_ID, ISO, AMOUNT, ISO2, AMOUNT2, RATE_AMOUNT, RATE_ITEMS, RATE_REVERSE
FROM #docs
ORDER BY REC_ID

OPEN c_docs
FETCH NEXT FROM c_docs
INTO @c_docs_priority_id, @c_docs_debit_id, @c_docs_credit_id, @c_docs_iso, @c_docs_amount, @c_docs_iso2, @c_docs_amount2, @rate_amount, @rate_items, @rate_reverse

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @iso = ISNULL(@c_docs_iso, @c_docs_iso2)
		EXEC @r = dbo.ADD_DOC4
			@rec_id				= @rec_id_1 OUTPUT,
			@user_id			= @user_id,
			@doc_type			= 98, 
			@doc_num			= NULL,
			@doc_date			= @date,
			@debit_id			= @c_docs_debit_id,
			@credit_id			= @c_docs_credit_id,
			@iso				= @iso, 
			@amount				= @c_docs_amount,
			@rec_state			= 20,
			@descrip			= @doc_descrip,
			@op_code			= '*LCOL',
			@parent_rec_id		= @parent_rec_id,
			@account_extra		= @loan_id,
			@prod_id			= 7,
			@channel_id			= 700,

			@check_saldo		= 0,
			@add_tariff			= 0,
			@info				= 0
	ELSE
	IF @c_docs_amount > 0.00 AND @c_docs_amount2 > 0.00
	BEGIN
	
	 	SET @conv_doc_descrip = @doc_descrip + ' (ÊÒÏÓ-ÊÖÒÓÉ: ' + CONVERT(varchar(10), @rate_items) + ' ' +
			CASE 
				WHEN @c_docs_amount < @c_docs_amount2 THEN @c_docs_iso + ' = ' + CONVERT(varchar(10), @rate_amount, 126) + ' ' + @c_docs_iso2 + ')'
			ELSE @c_docs_iso2 + ' = ' + CONVERT(varchar(10), @rate_amount, 126) + ' ' + @c_docs_iso + ')'
			END			
						
		EXEC @r = dbo.ADD_CONV_DOC4
			@rec_id_1			= @rec_id_1 OUTPUT,
			@rec_id_2			= @rec_id_2 OUTPUT,
			@user_id			= @user_id,
			@doc_num			= NULL,
			@doc_date			= @date,
			@iso_d				= @c_docs_iso,              
			@iso_c				= @c_docs_iso2,              
			@amount_d			= @c_docs_amount,          
			@amount_c			= @c_docs_amount2,
			@debit_id			= @c_docs_debit_id,
			@credit_id			= @c_docs_credit_id,
			@account_extra		= @loan_id,
			@descrip1			= @conv_doc_descrip,   
			@descrip2			= @conv_doc_descrip,   
			@rec_state			= 20,
			@relation_id		= @parent_rec_id,
			@prod_id			= 7,
			@channel_id			= 700,
			
			@rate_items			= @rate_items,
			@rate_amount		= @rate_amount,
			@rate_reverse		= @rate_reverse,

			@check_saldo		= 0,
			@add_tariff			= 0,
			@info				= 0

		IF @@ERROR<>0 OR @r<>0 BEGIN CLOSE c_docs; DEALLOCATE c_docs; GOTO _ret_err; END
		IF (@parent_rec_id = -1) SET @parent_rec_id = @rec_id_1
	END

	UPDATE #acc_balance
	SET DOC_REC_ID = @rec_id_1
	WHERE PRIORITY_ID = @c_docs_priority_id

	FETCH NEXT FROM c_docs
	INTO @c_docs_priority_id, @c_docs_debit_id, @c_docs_credit_id, @c_docs_iso, @c_docs_amount, @c_docs_iso2, @c_docs_amount2, @rate_amount, @rate_items, @rate_reverse
END

CLOSE c_docs
DEALLOCATE c_docs

_skip_docs:

DROP TABLE #docs

IF @simulate = 0 AND @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

EXEC @r = dbo.ON_USER_AFTER_LOAN_SP_COLLECTION_CLIENT_AMOUNT
	@user_id = @user_id,
	@date = @date,
	@loan_id = @loan_id,
	@iso = @iso,
	@acc_id = @acc_id,
	@client_no = @client_no,
	@debt_amount = @debt_amount,
	@simulate = @simulate,
	@client_amount = @client_amount
IF @@ERROR<>0 OR @r<>0 BEGIN DROP TABLE #acc_balance; RETURN @r END

DROP TABLE #acc_balance

RETURN (0)

_ret_err:
	DROP TABLE #acc_balance
	DROP TABLE #docs

	IF @internal_transaction=1 AND @@TRANCOUNT>0
		ROLLBACK
	RETURN (1)
GO
