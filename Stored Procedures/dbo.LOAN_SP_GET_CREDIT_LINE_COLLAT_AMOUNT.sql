SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_CREDIT_LINE_COLLAT_AMOUNT]
	@credit_line_id int,
	@loan_amount money = null,
	@loan_iso TISO = null
AS

DECLARE
	@ensure_type int,
	@amount money,
	@credit_line_iso TISO,
	@ensures_loan bit,
	@loan_open_date smalldatetime

	SET @loan_open_date = dbo.loan_open_date()

	SET @ensures_loan = 0

	SELECT @ensure_type = ENSURE_TYPE, @credit_line_iso = ISO
	FROM dbo.LOAN_CREDIT_LINES 
	WHERE CREDIT_LINE_ID = @credit_line_id

	IF @ensure_type = 4 -- ÓÀÁËÀÍÊÏ
	BEGIN
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SELECT @amount = SUM(dbo.get_cross_amount(AMOUNT, ISO, @credit_line_iso, @loan_open_date))
		FROM dbo.LOAN_COLLATERALS 
		WHERE CREDIT_LINE_ID = @credit_line_id OR 
			  COLLATERAL_ID IN (SELECT COLLATERAL_ID FROM dbo.LOAN_CREDIT_LINE_COLLATERALS_LINK WHERE CREDIT_LINE_ID = @credit_line_id)

		IF @loan_amount IS NOT NULL
			SET @loan_amount = dbo.get_cross_amount(@loan_amount, @loan_iso, @credit_line_iso, @loan_open_date)

		IF @loan_amount IS NOT NULL AND @loan_iso IS NOT NULL AND (@amount >= @loan_amount)
			SET @ensures_loan = 1
			
	END

	SELECT @credit_line_id AS CREDIT_LINE_ID, @ensure_type AS ENSURE_TYPE, 
		   @amount AS COLLATERAL_AMOUNT, @credit_line_iso AS ISO, @loan_amount	AS LOAN_AMOUNT_EQU,
		   @ensures_loan AS ENSURES_LOAN	

RETURN
GO
