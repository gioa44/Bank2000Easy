SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_PROCESSING_PAYMENT]
	@loan_id							int,
	@date								smalldatetime,
	@op_commit							bit OUTPUT,
	@amount								money OUTPUT,
	@schedule_date						smalldatetime,
	@schedule_principal					money OUTPUT,
	@schedule_interest					money OUTPUT,
	@schedule_nu_interest				money OUTPUT,
	@schedule_insurance					money OUTPUT,
	@schedule_service_fee				money OUTPUT,
	@schedule_defered_interest			money OUTPUT,
	@schedule_defered_overdue_interest	money OUTPUT,	
	@schedule_defered_penalty			money OUTPUT,
	@schedule_defered_fine				money OUTPUT,
	@writeoff_date						smalldatetime OUTPUT,
	@writeoff_principal					money OUTPUT,
	@writeoff_principal_penalty			money OUTPUT,
	@writeoff_percent					money OUTPUT,
	@writeoff_percent_penalty			money OUTPUT,
	@writeoff_penalty					money OUTPUT,
	@calloff_date						smalldatetime OUTPUT,
	@calloff_principal					money OUTPUT,
	@calloff_principal_interest			money OUTPUT,
	@calloff_principal_penalty			money OUTPUT,
	@calloff_percent					money OUTPUT,
	@calloff_percent_penalty			money OUTPUT,
	@calloff_penalty					money OUTPUT,
	@overdue_date						smalldatetime OUTPUT,
	@overdue_principal					money OUTPUT,
	@overdue_principal_interest			money OUTPUT,
	@overdue_principal_penalty			money OUTPUT,
	@overdue_percent					money OUTPUT,
	@overdue_percent_penalty			money OUTPUT,
	@late_date							smalldatetime OUTPUT,
	@late_principal						money OUTPUT,
	@late_percent						money OUTPUT,
	@nu_interest						money OUTPUT,
	@interest							money OUTPUT,
	@principal							money OUTPUT,
	@overdue_insurance					money OUTPUT,
	@overdue_service_fee				money OUTPUT,
	@deferable_interest					money OUTPUT,
	@deferable_overdue_interest			money OUTPUT,
	@deferable_penalty					money OUTPUT,
	@deferable_fine						money OUTPUT

AS
  
SET NOCOUNT ON
SET @op_commit = 0

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@writeoff_percent_penalty, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @writeoff_percent_penalty
	BEGIN
		SET @writeoff_percent_penalty = @writeoff_percent_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @writeoff_percent_penalty
		SET @writeoff_percent_penalty = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@writeoff_principal_penalty, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @writeoff_principal_penalty
	BEGIN
		SET @writeoff_principal_penalty = @writeoff_principal_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @writeoff_principal_penalty
		SET @writeoff_principal_penalty = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@writeoff_penalty, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @writeoff_penalty
	BEGIN
		SET @writeoff_penalty = @writeoff_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @writeoff_penalty
		SET @writeoff_penalty = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@writeoff_percent, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @writeoff_percent
	BEGIN
		SET @writeoff_percent = @writeoff_percent - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @writeoff_percent
		SET @writeoff_percent = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@writeoff_principal, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @writeoff_principal
	BEGIN
		SET @writeoff_principal = @writeoff_principal - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @writeoff_principal
		SET @writeoff_principal = $0.00
	END
END

-- გამოთხოვილი დავალიანების დაფარვა
IF @amount = $0.00 GOTO _check_date
IF ISNULL(@calloff_percent_penalty, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @calloff_percent_penalty
	BEGIN
		SET @calloff_percent_penalty = @calloff_percent_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @calloff_percent_penalty
		SET @calloff_percent_penalty = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@calloff_principal_penalty, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @calloff_principal_penalty
	BEGIN
		SET @calloff_principal_penalty = @calloff_principal_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @calloff_principal_penalty
		SET @calloff_principal_penalty = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@calloff_principal_interest, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @calloff_principal_interest
	BEGIN
		SET @calloff_principal_interest = @calloff_principal_interest - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @calloff_principal_interest
		SET @calloff_principal_interest = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@calloff_penalty, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @calloff_penalty
	BEGIN
		SET @calloff_penalty = @calloff_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @calloff_penalty
		SET @calloff_penalty = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@calloff_percent, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @calloff_percent
	BEGIN
		SET @calloff_percent = @calloff_percent - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @calloff_percent
		SET @calloff_percent = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@calloff_principal, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @calloff_principal
	BEGIN
		SET @calloff_principal = @calloff_principal - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @calloff_principal
		SET @calloff_principal = $0.00
	END
END

-- ვადაგადაცილებული დაზღვევის დაფარვა

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@overdue_insurance, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @overdue_insurance
	BEGIN
		SET @overdue_insurance = @overdue_insurance - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @overdue_insurance
		SET @overdue_insurance = $0.00
	END
END

-- ვადაგადაცილებული მომსახურების გადასახადის დაფარვა

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@overdue_service_fee, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @overdue_service_fee
	BEGIN
		SET @overdue_service_fee = @overdue_service_fee - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @overdue_service_fee
		SET @overdue_service_fee = $0.00
	END
END

-- მომსახურების გადასახადის დაფარვა

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@schedule_service_fee, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @schedule_service_fee
	BEGIN
		SET @schedule_service_fee = @schedule_service_fee - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @schedule_service_fee
		SET @schedule_service_fee = $0.00
	END
END

-- ვადაგადაცილებული დავალიანების დაფარვა

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@overdue_percent_penalty, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @overdue_percent_penalty
	BEGIN
		SET @overdue_percent_penalty = @overdue_percent_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @overdue_percent_penalty
		SET @overdue_percent_penalty = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@overdue_principal_penalty, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @overdue_principal_penalty
	BEGIN
		SET @overdue_principal_penalty = @overdue_principal_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @overdue_principal_penalty
		SET @overdue_principal_penalty = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@overdue_percent, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @overdue_percent
	BEGIN
		SET @overdue_percent = @overdue_percent - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @overdue_percent
		SET @overdue_percent = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@overdue_principal, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @overdue_principal
	BEGIN
		SET @overdue_principal = @overdue_principal - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @overdue_principal
		SET @overdue_principal = $0.00
	END
END

-- დაგვიანებული დავალიანების დაფარვა

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@late_percent, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @late_percent
	BEGIN
		SET @late_percent = @late_percent - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @late_percent
		SET @late_percent = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@late_principal, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @late_principal
	BEGIN
		SET @late_principal = @late_principal - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @late_principal
		SET @late_principal = $0.00
	END
END

IF @amount = $0.00 GOTO _check_date
IF @schedule_date = @date AND ISNULL(@schedule_defered_penalty, $0.00) > $0.00
BEGIN	
	SET @op_commit = 1
	IF @amount < @schedule_defered_penalty
	BEGIN
		SET @deferable_penalty = @deferable_penalty - @amount
		SET @schedule_defered_penalty = @schedule_defered_penalty - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @schedule_defered_penalty
		SET @deferable_penalty = @deferable_penalty - @schedule_defered_penalty
		SET @schedule_defered_penalty = $0.000 
	END
END

IF @amount = $0.00 GOTO _check_date
IF @schedule_date = @date AND ISNULL(@schedule_defered_fine, $0.00) > $0.00
BEGIN	
	SET @op_commit = 1
	IF @amount < @schedule_defered_fine
	BEGIN
		SET @deferable_fine = @deferable_fine - @amount
		SET @schedule_defered_fine = @schedule_defered_fine - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @schedule_defered_fine
		SET @deferable_fine = @deferable_fine - @schedule_defered_fine
		SET @schedule_defered_fine = $0.000 
	END
END

IF @amount = $0.00 GOTO _check_date
IF @schedule_date = @date AND ISNULL(@schedule_defered_overdue_interest, $0.00) > $0.00
BEGIN	
	SET @op_commit = 1
	IF @amount < @schedule_defered_overdue_interest
	BEGIN
		SET @deferable_overdue_interest = @deferable_overdue_interest - @amount
		SET @schedule_defered_overdue_interest = @schedule_defered_overdue_interest - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @schedule_defered_overdue_interest
		SET @deferable_overdue_interest = @deferable_overdue_interest - @schedule_defered_overdue_interest
		SET @schedule_defered_overdue_interest = $0.000 
	END
END

IF @amount = $0.00 GOTO _check_date
IF @schedule_date = @date AND ISNULL(@schedule_defered_interest, $0.00) > $0.00
BEGIN	
	SET @op_commit = 1
	IF @amount < @schedule_defered_interest
	BEGIN
		SET @deferable_interest = @deferable_interest - @amount
		SET @schedule_defered_interest = @schedule_defered_interest - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @schedule_defered_interest
		SET @deferable_interest = @deferable_interest - @schedule_defered_interest
		SET @schedule_defered_interest = $0.000 
	END
END

IF @amount = $0.00 GOTO _check_date
IF @schedule_date = @date AND ISNULL(@schedule_insurance, $0.00) > $0.00
BEGIN
	DECLARE 
		@insurance_tmp money,
		@interest_tmp money

	SET @interest_tmp = @interest + @nu_interest + @overdue_principal_interest

	IF (@amount < @interest_tmp + @schedule_insurance)
	BEGIN
		SET @insurance_tmp = ROUND(@schedule_insurance / (@interest_tmp + @schedule_insurance) * @amount, 2)

		SET @amount = @amount - @insurance_tmp
		SET @schedule_insurance = @schedule_insurance - @insurance_tmp
	END
	ELSE
	BEGIN
		SET @amount = @amount - @schedule_insurance
		SET @schedule_insurance = $0.00 
	END
END

IF @amount = $0.00 GOTO _check_date
IF ISNULL(@overdue_principal_interest, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @overdue_principal_interest
	BEGIN
		SET @overdue_principal_interest = @overdue_principal_interest - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @overdue_principal_interest
		SET @overdue_principal_interest = $0.00
	END
END

-- ვადიანი დავალიანების დაფარვა
IF @amount = $0.00 GOTO _check_date
IF @schedule_date = @date
BEGIN
	IF @interest > $0.00
	BEGIN
		SET @op_commit = 1
		IF @amount < @interest
		BEGIN
			SET @interest = @interest - @amount
			SET @schedule_interest = @schedule_interest - @amount
			SET @amount = $0.000
		END
		ELSE
		BEGIN
			SET @amount = @amount - @interest
			SET @schedule_interest = @schedule_interest - @interest
			SET @interest = $0.000
		END
	END

	IF @nu_interest > $0.00
	BEGIN
		SET @op_commit = 1
		IF @amount < @nu_interest
		BEGIN
			SET @nu_interest = @nu_interest - @amount
			SET @schedule_nu_interest = @schedule_nu_interest - @amount
			SET @amount = $0.000
		END
		ELSE
		BEGIN
			SET @amount = @amount - @nu_interest
			SET @schedule_nu_interest = @schedule_nu_interest - @nu_interest
			SET @nu_interest = $0.000
		END
	END

	-- ძირითადი თანხის დაფარვა
	IF @amount = $0.00 GOTO _check_date
	IF @principal > $0.00
	BEGIN	
		SET @op_commit = 1
		IF @amount < @schedule_principal
		BEGIN
			SET @principal = @principal - @amount
			SET @schedule_principal = @schedule_principal - @amount
			SET @amount = $0.00
		END
		ELSE
		BEGIN
			SET @amount = @amount - @schedule_principal
			SET @principal = @principal - @schedule_principal
			SET @schedule_principal = $0.000 
		END
	END
END
-- დაგროვილი გადაუხდელი დავალიანების დაფარვა
/*IF @amount = $0.00 GOTO _check_date
IF ISNULL(@defered_amount, $0.00) > $0.00
BEGIN
	SET @op_commit = 1
	IF @amount < @defered_amount
	BEGIN
		SET @defered_amount = @defered_amount - @amount
		SET @amount = $0.00
	END
	ELSE
	BEGIN
		SET @amount = @amount - @defered_amount
		SET @defered_amount = $0.000
	END
END*/

_check_date:


IF (@writeoff_date IS NOT NULL) AND (@writeoff_principal + @writeoff_principal_penalty + @writeoff_percent + @writeoff_percent_penalty + @writeoff_penalty = $0.00)
	SET @writeoff_date = NULL
IF (@calloff_date IS NOT NULL) AND (@calloff_principal + @calloff_principal_interest + @calloff_principal_penalty + @calloff_percent + @calloff_percent_penalty + @calloff_penalty = $0.00)
	SET @calloff_date = NULL

RETURN(0)

GO
