SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[call_center_check_limits]
	@iso char(3), 
	@debit_id int, 
	@credit_id int,
	@amount money,
	@doc_date smalldatetime,
	@doc_type smallint,
	@rec_state tinyint OUTPUT
AS

SET NOCOUNT ON;

DECLARE 
	@sum money,
	@acc_type int,
	@client_no_d int,
	@client_no_c int

SELECT @client_no_d = CLIENT_NO
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @debit_id

SELECT @client_no_c = CLIENT_NO
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @credit_id

IF @client_no_d = @client_no_c  -- Internal money transfer
BEGIN
	SET @rec_state = 20

	SELECT @acc_type = ACC_TYPE
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @credit_id

	IF @acc_type <> 200 	-- Not card account
		RETURN 0

	SELECT @sum = SUM(D.AMOUNT)
	FROM dbo.OPS_0000 D (NOLOCK)
	WHERE D.CREDIT_ID = @credit_id AND D.DOC_DATE = @doc_date AND CHANNEL_ID = 50 -- Call center channel

	SET @sum = ISNULL(@sum, $0.00) + @amount
	SET @sum = dbo.get_equ(@sum, @iso, @doc_date)

	IF @sum > 4000
	BEGIN
		RAISERROR('ËÉÌÉÔÉÓ ÃÀÒÙÅÄÅÀ',16,1) 
		RETURN (1) 
	END
	ELSE
		RETURN (0)
END

IF @doc_type IN (100,101,110,111) -- Internal and Inter branch
BEGIN
	SET @rec_state = 20

	SELECT @sum = SUM(D.AMOUNT)
	FROM dbo.OPS_0000 D (NOLOCK)
		INNER JOIN dbo.ACCOUNTS A ON A.ACC_ID = D.CREDIT_ID
	WHERE D.DEBIT_ID = @debit_id AND D.DOC_DATE = @doc_date AND 
		A.CLIENT_NO <> @client_no_d AND
		D.CHANNEL_ID = 50 AND -- Call center channel
		D.DOC_TYPE IN (100,101,110,111)
END
ELSE
IF @doc_type = 102 -- Out
BEGIN
	SELECT @sum = SUM(D.AMOUNT)
	FROM dbo.OPS_0000 D (NOLOCK)
	WHERE D.DEBIT_ID = @debit_id AND D.DOC_DATE = @doc_date AND D.CHANNEL_ID = 50 AND -- Call center channel
		D.DOC_TYPE = @doc_type 
END
ELSE
IF @doc_type = 112 -- Out val
BEGIN
	RAISERROR('ËÉÌÉÔÉÓ ÃÀÒÙÅÄÅÀ',16,1) 
	RETURN (2)
END
ELSE
	RETURN 0

SET @sum = ISNULL(@sum, $0.00) + @amount
SET @sum = dbo.get_equ(@sum, @iso, @doc_date)

IF @sum  > 1000 BEGIN RAISERROR('ËÉÌÉÔÉÓ ÃÀÒÙÅÄÅÀ',16,1) RETURN (2) END
GO
