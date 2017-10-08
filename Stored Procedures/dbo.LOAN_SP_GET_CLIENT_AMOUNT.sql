SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_CLIENT_AMOUNT]
	@client_no int,
	@iso TISO,
	@loan_id int,
	@debt_amount money,
	@client_amount money OUTPUT
AS
SET NOCOUNT ON

DECLARE
	@r int

SET @client_amount = $0.00

DECLARE
	@acc_id int

SELECT @acc_id = ACC_ID
FROM dbo.LOAN_ACCOUNTS
WHERE LOAN_ID = @loan_id AND ACCOUNT_TYPE = 20 -- ÓÄÓáÉÓ ÀÍÂÀÒÉÛÓßÏÒÄÁÉÓ ÀÍÂÀÒÉÛÉ

IF @acc_id IS NULL
  RETURN 0

EXEC @r = dbo.acc_get_usable_amount 
	@acc_id = @acc_id,
	@usable_amount = @client_amount OUTPUT,
	@use_overdraft = 0
IF @r <> 0 OR @@ERROR <> 0 RETURN 1

SET @client_amount = ISNULL(@client_amount, $0.00)

IF @client_amount < @debt_amount
BEGIN
	SET @debt_amount = @debt_amount - @client_amount

	EXEC @r = dbo.LOAN_SP_COLLECTION_CLIENT_AMOUNT
		@client_no = @client_no,
		@iso = @iso,
		@loan_id = @loan_id,
		@acc_id = @acc_id,
		@debt_amount = @debt_amount

	IF @r <> 0 OR @@ERROR <> 0 RETURN 1

	EXEC @r = dbo.acc_get_usable_amount 
		@acc_id = @acc_id,
		@usable_amount = @client_amount OUTPUT,
		@use_overdraft = 0
	IF @r <> 0 OR @@ERROR <> 0 RETURN 1

	SET @client_amount = ISNULL(@client_amount, $0.00)
END


RETURN

GO
