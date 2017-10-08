SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[call_center_check_fx_limits] 
	@iso_d char(3), 
	@iso_c char(3), 
	@debit_id int, 
	@credit_id int,
	@amount_d money,
	@amount_c money,
	@doc_date smalldatetime,
	@rec_state tinyint OUTPUT
AS

SET NOCOUNT ON;

DECLARE 
	@sum money,
	@acc_type int

SET @rec_state = 20

SELECT @acc_type = ACC_TYPE
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @credit_id

IF @acc_type <> 200	-- Not card account
BEGIN
	DECLARE @limit money

	IF @iso_d = 'GEL' AND @iso_c = 'USD'
		SET @limit = 300000
	ELSE
		SET @limit = 100000
	IF DATEPART (hour, GETDATE()) >= 18
		SET @limit = 50000

	IF dbo.get_equ(@amount_d, @iso_d, @doc_date) > @limit
		SET @rec_state = 0
	RETURN 0
END

SELECT @sum = SUM(D.AMOUNT)
FROM dbo.OPS_0000 D (NOLOCK)
WHERE D.CREDIT_ID = @credit_id AND D.DOC_DATE = @doc_date AND CHANNEL_ID = 50 -- Call center channel

SET @sum = ISNULL(@sum, $0.00) + @amount_c
SET @sum = dbo.get_equ(@sum, @iso_c, @doc_date)

IF @sum > 4000
BEGIN
	RAISERROR('ËÉÌÉÔÉÓ ÃÀÒÙÅÄÅÀ',16,1) 
	RETURN (1) 
END
ELSE
	RETURN (0)
GO
