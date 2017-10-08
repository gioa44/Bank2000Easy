SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_COLLECT_CLIENT_AMOUNT]
	@date smalldatetime,
	@client_no int,
	@iso TISO,
	@loan_id int,
	@debt_amount money,
	@user_id int,
	@simulate bit = 0,
	@client_amount money OUTPUT
AS
SET NOCOUNT ON

SET @client_amount = $0.00

DECLARE
	@main_acc_usable_amount0 money,
	@main_acc_usable_amount1 money,
	@main_acc_type tinyint,
	@acc_id int,
	@r int

SELECT @acc_id = L.ACC_ID, @main_acc_type = A.ACC_TYPE
FROM dbo.LOAN_ACCOUNTS L
	INNER JOIN dbo.ACCOUNTS A ON L.ACC_ID = A.ACC_ID
WHERE L.LOAN_ID = @loan_id AND L.ACCOUNT_TYPE = 20 -- ÓÄÓáÉÓ ÀÍÂÀÒÉÛÓßÏÒÄÁÉÓ ÀÍÂÀÒÉÛÉ

IF @acc_id IS NULL
  RETURN 0

SET @main_acc_usable_amount0 = NULL
SET @main_acc_usable_amount1 = NULL

EXEC dbo.acc_get_usable_amount @acc_id = @acc_id, @usable_amount = @main_acc_usable_amount0 OUTPUT, @use_overdraft = 0
IF @main_acc_usable_amount0 < $0.00
	SET @main_acc_usable_amount0 = $0.00

EXEC @r = dbo.acc_get_usable_amount @acc_id = @acc_id, @usable_amount = @main_acc_usable_amount1 OUTPUT, @use_overdraft = 1

SET @main_acc_usable_amount0 = ISNULL(@main_acc_usable_amount0, $0.00)
SET @main_acc_usable_amount1 = ISNULL(@main_acc_usable_amount1, $0.00)


IF @main_acc_usable_amount1 < $0.00
BEGIN
	SET @debt_amount = @debt_amount - @main_acc_usable_amount1  -- ÃÀÖÌÀÔÄ ÀÒÀÓÀÍØÝÉÒÄÁÖËÉ ÏÅÄÒÃÒÀ×ÔÉÓ ÈÀÍáÀ
	SET @client_amount = @main_acc_usable_amount1
END

SET @main_acc_usable_amount1 = @main_acc_usable_amount1 - @main_acc_usable_amount0 -- ÀØ ÀÒÉÓ ÓÖ×ÈÀ ÏÅÄÒÃÒÀ×ÔÉ
IF @main_acc_usable_amount1 < $0.00
	SET @main_acc_usable_amount1 = $0.00


DECLARE @accounts TABLE
(
	PRIORITY_ID	int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	ACC_ID int NOT NULL,
	USE_OVERDRAFT bit NOT NULL,
	ACC_TYPE int NULL
)


INSERT INTO @accounts (ACC_ID, USE_OVERDRAFT, ACC_TYPE)
SELECT ACC_ID, 0, ACC_TYPE
FROM dbo.ACCOUNTS (NOLOCK)
WHERE CLIENT_NO = @client_no AND ISO = @iso AND ACC_TYPE IN (100, 200) AND IS_INCASSO = 0 AND REC_STATE = 1
ORDER BY CASE WHEN ACC_ID = @acc_id THEN 0 ELSE ACC_TYPE END

INSERT INTO @accounts (ACC_ID, USE_OVERDRAFT, ACC_TYPE)
SELECT ACC_ID, 1, ACC_TYPE
FROM @accounts
WHERE ACC_TYPE = 200
ORDER BY PRIORITY_ID


DECLARE
	@agreement_no varchar(100),
	@doc_descrip varchar(150)

SELECT @agreement_no = AGREEMENT_NO
FROM dbo.LOANS (NOLOCK)
WHERE LOAN_ID = @loan_id

SET @doc_descrip = 'ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÃÀÓÀ×ÀÒÀÃ (# ' + @agreement_no + ')'

DECLARE 
	@cr_acc_id int,
	@acc_usable_amount money,
	@use_overdraft bit,
	@acc_type tinyint,
	@rec_id int,
	@doc_amount money

DECLARE cr CURSOR LOCAL FAST_FORWARD FOR
SELECT ACC_ID, USE_OVERDRAFT, ACC_TYPE
FROM @accounts
ORDER BY PRIORITY_ID

OPEN cr

FETCH NEXT FROM cr INTO @cr_acc_id, @use_overdraft, @acc_type

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @doc_amount = $0.00
	SET @acc_usable_amount = NULL
		
	IF @cr_acc_id = @acc_id -- Main Account
		SET @acc_usable_amount = CASE WHEN @use_overdraft = 0 THEN @main_acc_usable_amount0 ELSE @main_acc_usable_amount1 END
	ELSE
	BEGIN
		EXEC @r = dbo.acc_get_usable_amount @acc_id = @cr_acc_id, @usable_amount = @acc_usable_amount OUTPUT, @use_overdraft = @use_overdraft
		IF @r <> 0 OR @@ERROR <> 0 GOTO _err

		SET @acc_usable_amount = ISNULL(@acc_usable_amount, $0.00)
		IF @acc_usable_amount < $0.00
			SET @acc_usable_amount = $0.00
	END
	
	
	IF @acc_usable_amount > $0.00
	BEGIN
		IF @acc_usable_amount >= @debt_amount
		BEGIN
			SET @doc_amount = @debt_amount
			SET @debt_amount = $0.00
		END
		ELSE
		BEGIN
			SET @doc_amount = @acc_usable_amount
			SET @debt_amount = @debt_amount - @acc_usable_amount
		END
		
		SET @client_amount = @client_amount + @doc_amount

        IF @simulate = 0 AND @acc_id <> @cr_acc_id
		BEGIN
			EXEC @r = dbo.ADD_DOC4
				@rec_id				= @rec_id OUTPUT,
				@user_id			= @user_id,
				@doc_type			= 98, 
				@doc_num			= 0,
				@doc_date			= @date,
				@debit_id			= @cr_acc_id,
				@credit_id			= @acc_id,
				@iso				= @iso, 
				@amount				= @doc_amount,
				@rec_state			= 20,
				@descrip			= @doc_descrip,
				@op_code			= '*LCOL',
				@account_extra		= @loan_id,
				@prod_id			= 7,
				@channel_id			= 700,

				@check_saldo		= 0,
				@add_tariff			= 0,
				@info				= 0

			IF @@ERROR<>0 OR @r<>0 GOTO _err
		END
	END

	IF @debt_amount <= $0.00 GOTO _ok

	FETCH NEXT FROM cr INTO @cr_acc_id, @use_overdraft, @acc_type
END

GOTO _ok

_err:
CLOSE cr
DEALLOCATE cr
RETURN 1

_ok:
CLOSE cr
DEALLOCATE cr

RETURN 0
GO
