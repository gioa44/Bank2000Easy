SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_STATEMENT]
	@loan_id int,
	@dt smalldatetime
AS
BEGIN
SET NOCOUNT ON
DECLARE	@tbl_statement_list TABLE (
	REC_ID int NOT NULL PRIMARY KEY, 
	DATE smalldatetime NULL, -- ÈÀÒÉÙÉ
	DISBURSE_AMOUNT money NULL, -- ÓÄÓáÉÓ ÂÀÝÄÌÀ
	SUM_PAYMENT money NULL, -- ÓÖË ÃÀ×ÀÒÅÀ
	PRINCIPAL_PAYMENT money NULL, -- ÅÀÃÉÀÍÉ ÞÉÒÉÓ ÃÀ×ÀÒÅÀ
	OVERDUE_PRINCIPAL_PAYMENT money NULL, -- ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÞÉÒÉÓ ÃÀ×ÀÒÅÀ
	WRITEOFF_PRINCIPAL_PAYMENT money NULL, -- ÜÀÌÏßÄÒÉËÉ ÞÉÒÉÓ ÃÀ×ÀÒÅÀ
	INTEREST_PAYMENT money NULL, -- ÅÀÃÉÀÍÉ ÐÒÏÝÄÍÔÉÓ ÃÀ×ÀÒÅÀ
	NU_INTEREST_PAYMENT money NULL, -- ÀÖÈÅÉÓÄÁÄË ÞÉÒÆÄ ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉÓ ÃÀ×ÀÒÅÀ
	OVERDUE_PERCENT_PAYMENT money NULL, -- ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÃÀ×ÀÒÅÀ
	WRITEOFF_PERCENT_PAYMENT money NULL, -- ÜÀÌÏßÄÒÉËÉ ÐÒÏÝÒÍÔÉÓ ÃÀ×ÀÒÅÀ
	PENALTY_PAYMENT money NULL, -- ãÀÒÉÌÉÓ ÃÀ×ÀÒÅÀ
	PREPAYMENT_PENALTY_PAYMENT money NULL, -- ßÉÍÓßÒÄÁÉÓ ãÀÒÉÌÀ
	OVERDUE_PRINCIPAL money NULL, -- ÞÉÒÉÈÀÃÉ ÈÀÍáÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ
	OVERDUE_PERCENT money NULL, -- ÐÒÏÝÄÍÔÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ
	PRINCIPAL_BALANCE money NULL -- ÓÀÓÄÓáÏ ÍÀÛÈÉ
)

DECLARE
	@rec_id int,
	@date smalldatetime,
	@disburse_amount money,
	@sum_payment money,
	@principal_payment money,
	@principal_payment1 money,
	@overdue_principal_payment money,
	@overdue_principal_payment1 money,
	@writeoff_principal_payment money,
	@writeoff_principal_payment1 money,
	@interest_payment money,
	@nu_interest_payment money,
	@overdue_percent_payment money,
	@writeoff_percent_payment money,
	@penalty_payment money,
	@prepayment_penalty_payment money,
	@overdue_principal money,
	@overdue_percent money,
	@principal_balance money

DECLARE
	@cr_op_id int,
	@cr_date smalldatetime,
	@cr_op_date smalldatetime,
	@cr_op_type tinyint,
	@cr_op_amount money

SET @rec_id = 1
SET @cr_date = NULL
SET @disburse_amount = $0.00
SET @sum_payment = $0.00
SET @principal_payment = $0.00
SET @overdue_principal_payment = $0.00
SET @writeoff_principal_payment = $0.00
SET @interest_payment = $0.00
SET @nu_interest_payment = $0.00
SET @overdue_percent_payment = $0.00
SET @writeoff_percent_payment = $0.00
SET @penalty_payment = $0.00
SET @prepayment_penalty_payment = $0.00

SET @overdue_principal = $0.00
SET @overdue_percent = $0.00
SET @principal_balance = $0.00


DECLARE cr CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR SELECT OP_ID, OP_DATE, OP_TYPE, AMOUNT FROM dbo.LOAN_OPS (NOLOCK)
WHERE LOAN_ID = @loan_id AND OP_DATE <= @dt AND OP_TYPE IN (dbo.loan_const_op_disburse(), dbo.loan_const_op_disburse_transh(), dbo.loan_const_op_overdue(), dbo.loan_const_op_payment(), dbo.loan_const_op_payment_writedoff(), dbo.loan_const_op_guar_disburse(), dbo.loan_const_op_guar_payment())
ORDER BY OP_ID

OPEN cr

FETCH NEXT FROM cr 
INTO @cr_op_id, @cr_op_date, @cr_op_type, @cr_op_amount

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @cr_date IS NULL
		SET @cr_date = @cr_op_date

	IF @cr_op_type IN (dbo.loan_const_op_disburse(), dbo.loan_const_op_disburse_transh(), dbo.loan_const_op_guar_disburse())
	BEGIN
		SET @disburse_amount = @disburse_amount + @cr_op_amount
		SET @principal_balance = @principal_balance + @cr_op_amount
	END

	IF @cr_op_type = dbo.loan_const_op_overdue()
	BEGIN
		SELECT
			@overdue_principal = @overdue_principal + OVERDUE_PRINCIPAL,
			@overdue_percent = @overdue_percent + OVERDUE_PERCENT + ISNULL(OVERDUE_DEFERED_INTEREST, $0.00)
		FROM dbo.LOAN_VW_LOAN_OP_OVERDUE
		WHERE OP_ID = @cr_op_id
	END

	IF @cr_op_type = dbo.loan_const_op_payment()
	BEGIN
		SELECT
			@principal_payment = @principal_payment + ISNULL(PRINCIPAL, $0.00),
			@principal_payment1 = ISNULL(PRINCIPAL, $0.00),
			@overdue_principal_payment = @overdue_principal_payment + ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(OVERDUE_PRINCIPAL, $0.00),
			@overdue_principal_payment1 = ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(OVERDUE_PRINCIPAL, $0.00),
			@interest_payment = @interest_payment + ISNULL(INTEREST, $0.00) + ISNULL(OVERDUE_PRINCIPAL_INTEREST, $0.00) + ISNULL(DEFERED_INTEREST, $0.00),
			@nu_interest_payment = @nu_interest_payment + ISNULL(NU_INTEREST, $0.00),
			@overdue_percent_payment = @overdue_percent_payment + ISNULL(LATE_PERCENT, $0.00) + ISNULL(OVERDUE_PERCENT, $0.00),
			@penalty_payment = @penalty_payment + ISNULL(OVERDUE_PERCENT_PENALTY, $0.00) + ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00),
			@prepayment_penalty_payment = @prepayment_penalty_payment + ISNULL(PREPAYMENT_PENALTY, $0.00)
		FROM dbo.LOAN_VW_LOAN_OP_PAYMENT_DETAILS
		WHERE OP_ID = @cr_op_id

		SET @sum_payment = @sum_payment + @cr_op_amount
		SET @principal_balance = @principal_balance - (@principal_payment1 + @overdue_principal_payment1)
	END
	
	IF @cr_op_type = dbo.loan_const_op_guar_payment()
	BEGIN
		SELECT
			@interest_payment = @interest_payment + ISNULL(INTEREST, $0.00),
			@overdue_percent_payment = @overdue_percent_payment + ISNULL(OVERDUE_PERCENT, $0.00),
			@penalty_payment = @penalty_payment + ISNULL(PENALTY, $0.00)
		FROM dbo.LOAN_VW_GUARANTEE_OP_PAYMENT
		WHERE OP_ID = @cr_op_id

		SET @sum_payment = @sum_payment + @cr_op_amount
	END

	IF @cr_op_type = dbo.loan_const_op_payment_writedoff()
	BEGIN
		SELECT 
			@writeoff_principal_payment = @writeoff_principal_payment + ISNULL(WRITEOFF_PRINCIPAL, $0.00),
			@writeoff_principal_payment1 = ISNULL(WRITEOFF_PRINCIPAL, $0.00),
			@writeoff_percent_payment = @writeoff_percent_payment + ISNULL(WRITEOFF_PERCENT, $0.00)
		FROM dbo.LOAN_VW_LOAN_OP_PAYMENT_WRITEDOFF
		WHERE OP_ID = @cr_op_id

		SET @sum_payment = @sum_payment + @cr_op_amount
		SET @principal_balance = @principal_balance - @writeoff_principal_payment1
	END	

	FETCH NEXT FROM cr 
	INTO @cr_op_id, @cr_op_date, @cr_op_type, @cr_op_amount

	IF @cr_date <> @cr_op_date
	BEGIN
		INSERT INTO @tbl_statement_list(REC_ID, DATE, DISBURSE_AMOUNT, SUM_PAYMENT,	PRINCIPAL_PAYMENT, OVERDUE_PRINCIPAL_PAYMENT, WRITEOFF_PRINCIPAL_PAYMENT, INTEREST_PAYMENT, NU_INTEREST_PAYMENT, OVERDUE_PERCENT_PAYMENT, WRITEOFF_PERCENT_PAYMENT,	PENALTY_PAYMENT, PREPAYMENT_PENALTY_PAYMENT, OVERDUE_PRINCIPAL, OVERDUE_PERCENT, PRINCIPAL_BALANCE)
		VALUES(@rec_id, @cr_date,
			CASE WHEN @disburse_amount = $0.00 THEN NULL ELSE @disburse_amount END,
			CASE WHEN @sum_payment = $0.00 THEN NULL ELSE @sum_payment END,	
			CASE WHEN @principal_payment = $0.00 THEN NULL ELSE @principal_payment END,	
			CASE WHEN @overdue_principal_payment = $0.00 THEN NULL ELSE @overdue_principal_payment END,	
			CASE WHEN @writeoff_principal_payment = $0.00 THEN NULL ELSE @writeoff_principal_payment END,	
			CASE WHEN @interest_payment = $0.00 THEN NULL ELSE @interest_payment END,	
			CASE WHEN @nu_interest_payment = $0.00 THEN NULL ELSE @nu_interest_payment END,	
			CASE WHEN @overdue_percent_payment = $0.00 THEN NULL ELSE @overdue_percent_payment END,	
			CASE WHEN @writeoff_percent_payment = $0.00 THEN NULL ELSE @writeoff_percent_payment END,	
			CASE WHEN @penalty_payment = $0.00 THEN NULL ELSE @penalty_payment END,	
			CASE WHEN @prepayment_penalty_payment = $0.00 THEN NULL ELSE @prepayment_penalty_payment END,	
			CASE WHEN @overdue_principal = $0.00 THEN NULL ELSE @overdue_principal END,
			CASE WHEN @overdue_percent = $0.00 THEN NULL ELSE @overdue_percent END,
			@principal_balance)

		SET @cr_date = @cr_op_date
		SET @rec_id = @rec_id + 1
		SET @disburse_amount = $0.00
		SET @sum_payment = $0.00
		SET @principal_payment = $0.00
		SET @overdue_principal_payment = $0.00
		SET @writeoff_principal_payment = $0.00
		SET @interest_payment = $0.00
		SET @nu_interest_payment = $0.00
		SET @overdue_percent_payment = $0.00
		SET @writeoff_percent_payment = $0.00
		SET @penalty_payment = $0.00
		SET @prepayment_penalty_payment = $0.00
		SET @overdue_principal = $0.00
		SET @overdue_percent = $0.00
	END
END

IF (@cr_date = @cr_op_date) AND (@disburse_amount + @sum_payment + @overdue_principal + @overdue_percent <> $0.00)
BEGIN
	INSERT INTO @tbl_statement_list(REC_ID, DATE, DISBURSE_AMOUNT, SUM_PAYMENT,	PRINCIPAL_PAYMENT, OVERDUE_PRINCIPAL_PAYMENT, WRITEOFF_PRINCIPAL_PAYMENT, INTEREST_PAYMENT, NU_INTEREST_PAYMENT, OVERDUE_PERCENT_PAYMENT, WRITEOFF_PERCENT_PAYMENT,	PENALTY_PAYMENT, PREPAYMENT_PENALTY_PAYMENT, OVERDUE_PRINCIPAL, OVERDUE_PERCENT, PRINCIPAL_BALANCE)
	VALUES(@rec_id, @cr_op_date,
		CASE WHEN @disburse_amount = $0.00 THEN NULL ELSE @disburse_amount END,
		CASE WHEN @sum_payment = $0.00 THEN NULL ELSE @sum_payment END,	
		CASE WHEN @principal_payment = $0.00 THEN NULL ELSE @principal_payment END,	
		CASE WHEN @overdue_principal_payment = $0.00 THEN NULL ELSE @overdue_principal_payment END,	
		CASE WHEN @writeoff_principal_payment = $0.00 THEN NULL ELSE @writeoff_principal_payment END,	
		CASE WHEN @interest_payment = $0.00 THEN NULL ELSE @interest_payment END,	
		CASE WHEN @nu_interest_payment = $0.00 THEN NULL ELSE @nu_interest_payment END,	
		CASE WHEN @overdue_percent_payment = $0.00 THEN NULL ELSE @overdue_percent_payment END,	
		CASE WHEN @writeoff_percent_payment = $0.00 THEN NULL ELSE @writeoff_percent_payment END,	
		CASE WHEN @penalty_payment = $0.00 THEN NULL ELSE @penalty_payment END,	
		CASE WHEN @prepayment_penalty_payment = $0.00 THEN NULL ELSE @prepayment_penalty_payment END,	
		CASE WHEN @overdue_principal = $0.00 THEN NULL ELSE @overdue_principal END,
		CASE WHEN @overdue_percent = $0.00 THEN NULL ELSE @overdue_percent END,
		@principal_balance)
END

CLOSE cr
DEALLOCATE cr

SET @rec_id = @rec_id + 1
SELECT
	@disburse_amount = SUM(ISNULL(DISBURSE_AMOUNT, $0.00)),
	@sum_payment = SUM(ISNULL(SUM_PAYMENT, $0.00)),
	@principal_payment = SUM(ISNULL(PRINCIPAL_PAYMENT, $0.00)),
	@overdue_principal_payment = SUM(ISNULL(OVERDUE_PRINCIPAL_PAYMENT, $0.00)),
	@writeoff_principal_payment = SUM(ISNULL(WRITEOFF_PRINCIPAL_PAYMENT, $0.00)),
	@interest_payment = SUM(ISNULL(INTEREST_PAYMENT, $0.00)),
	@nu_interest_payment = SUM(ISNULL(NU_INTEREST_PAYMENT, $0.00)),
	@overdue_percent_payment = SUM(ISNULL(OVERDUE_PERCENT_PAYMENT, $0.00)),
	@writeoff_percent_payment = SUM(ISNULL(WRITEOFF_PERCENT_PAYMENT, $0.00)),
	@penalty_payment = SUM(ISNULL(PENALTY_PAYMENT, $0.00)),
	@prepayment_penalty_payment = SUM(ISNULL(PREPAYMENT_PENALTY_PAYMENT, $0.00)),
	@overdue_principal = SUM(ISNULL(OVERDUE_PRINCIPAL, $0.00)),
	@overdue_percent = SUM(ISNULL(OVERDUE_PERCENT, $0.00))
FROM @tbl_statement_list

INSERT INTO @tbl_statement_list(REC_ID, DATE, DISBURSE_AMOUNT, SUM_PAYMENT,	PRINCIPAL_PAYMENT, OVERDUE_PRINCIPAL_PAYMENT, WRITEOFF_PRINCIPAL_PAYMENT, INTEREST_PAYMENT, NU_INTEREST_PAYMENT, OVERDUE_PERCENT_PAYMENT, WRITEOFF_PERCENT_PAYMENT,	PENALTY_PAYMENT, PREPAYMENT_PENALTY_PAYMENT, OVERDUE_PRINCIPAL, OVERDUE_PERCENT, PRINCIPAL_BALANCE)
VALUES(@rec_id, NULL, @disburse_amount, @sum_payment, @principal_payment, @overdue_principal_payment, @writeoff_principal_payment, @interest_payment, @nu_interest_payment, @overdue_percent_payment, @writeoff_percent_payment, @penalty_payment, @prepayment_penalty_payment, @overdue_principal, @overdue_percent, NULL)


SELECT * FROM @tbl_statement_list
	RETURN
END
GO
