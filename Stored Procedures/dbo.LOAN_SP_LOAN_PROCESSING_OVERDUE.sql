SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_PROCESSING_OVERDUE]
	@loan_id					int,
	@date						smalldatetime,
	@op_commit					bit OUTPUT,
	@late_percent				money OUTPUT,
	@late_principal				money OUTPUT,
	@schedule_date				smalldatetime,
	@schedule_nu_interest		money OUTPUT,
	@schedule_interest			money OUTPUT,
	@schedule_principal			money OUTPUT,
	@schedule_insurance			money OUTPUT,
	@schedule_service_fee		money OUTPUT,
	@schedule_defered_interest	money OUTPUT,
	@nu_interest				money OUTPUT,
	@interest					money OUTPUT,
	@principal					money OUTPUT,
	@deferable_interest			money OUTPUT,
	@l_late_days				int, 
	@overdue_percent			money OUTPUT,
	@overdue_principal			money OUTPUT,
	@step_overdue_percent		money OUTPUT,
	@step_overdue_principal		money OUTPUT,
	@overdue_insurance			money OUTPUT,
	@overdue_service_fee		money OUTPUT,
	@step_overdue_insurance		money OUTPUT,
	@step_overdue_service_fee	money OUTPUT,
	@step_defered_interest		money OUTPUT,
	@op_details					xml OUTPUT
AS
  
SET NOCOUNT ON
SET @op_commit = 0

SELECT @step_overdue_principal = SUM(ISNULL(LATE_PRINCIPAL, $0.00)), @step_overdue_percent = SUM(ISNULL(LATE_PERCENT, $0.00))
FROM #tbl_late
WHERE LOAN_ID = @loan_id AND DATEDIFF(dd, LATE_DATE, @date) >= @l_late_days AND 
	(ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(LATE_PERCENT, $0.00)) <> $0.00

SET @op_details =
(SELECT LOAN_ID,LATE_DATE,LATE_OP_ID,LATE_PRINCIPAL,LATE_PERCENT
FROM #tbl_late
WHERE LOAN_ID = @loan_id AND DATEDIFF(dd, LATE_DATE, @date) >= @l_late_days AND 
	(ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(LATE_PERCENT, $0.00)) <> $0.00
FOR XML RAW, ROOT)

INSERT INTO #tbl_overdue(LOAN_ID, OVERDUE_DATE, LATE_OP_ID, OVERDUE_OP_ID, OVERDUE_PRINCIPAL, OVERDUE_PERCENT)
SELECT @loan_id, @date, LATE_OP_ID, -1, LATE_PRINCIPAL, LATE_PERCENT
FROM #tbl_late
WHERE LOAN_ID = @loan_id AND DATEDIFF(dd, LATE_DATE, @date) >= @l_late_days AND 
	(ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(LATE_PERCENT, $0.00)) <> $0.00

UPDATE #tbl_late
SET LATE_PRINCIPAL = $0.00, LATE_PERCENT = $0.00
WHERE LOAN_ID = @loan_id AND DATEDIFF(dd, LATE_DATE, @date) >= @l_late_days AND 
	(ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(LATE_PERCENT, $0.00)) <> $0.00

IF @@ROWCOUNT <> 0
BEGIN
	SET @op_commit = 1

	SET @overdue_percent = @overdue_percent + @step_overdue_percent
	SET @overdue_principal = @overdue_principal + @step_overdue_principal

	SET @late_percent = @late_percent - @step_overdue_percent
	SET @late_principal = @late_principal - @step_overdue_principal
END

IF @l_late_days = 0
BEGIN
	IF (@schedule_date = @date)
	BEGIN
		IF ISNULL(@schedule_nu_interest, $0.00) + ISNULL(@schedule_interest, $0.00) > $0.00 OR
			ISNULL(@schedule_principal, $0.00) > $0.00
		BEGIN
			SET @op_commit = 1
			SET @step_overdue_percent = ISNULL(@schedule_nu_interest, $0.00) + ISNULL(@schedule_interest, $0.00) 
			SET @step_defered_interest = ISNULL(@schedule_defered_interest, $0.00)
			SET @overdue_percent = @overdue_percent + @step_overdue_percent + @step_defered_interest
			SET @step_overdue_principal = ISNULL(@schedule_principal, $0.00)
			SET @overdue_principal = @overdue_principal + @step_overdue_principal

			INSERT INTO #tbl_overdue(LOAN_ID, OVERDUE_DATE, OVERDUE_OP_ID, OVERDUE_PRINCIPAL, OVERDUE_PERCENT)
			VALUES(@loan_id, @date, -1, @step_overdue_principal, @step_overdue_percent + @step_defered_interest) 

			SET @nu_interest = $0.00
			SET @interest = $0.00
			SET @principal = @principal - @schedule_principal
			SET @deferable_interest = @deferable_interest - @step_defered_interest
			SET @schedule_nu_interest = $0.00
			SET @schedule_interest = $0.00
			SET @schedule_principal = $0.00
		END

		SET @step_overdue_insurance = $0.00
		SET @step_overdue_service_fee = $0.00
		IF ISNULL(@schedule_insurance, $0.00) > $0.00 OR ISNULL(@schedule_service_fee, $0.00) > $0.00
		BEGIN
			SET @step_overdue_insurance = ISNULL(@schedule_insurance, $0.00)
			SET @overdue_insurance = ISNULL(@overdue_insurance, $0.00) + @step_overdue_insurance

			SET @step_overdue_service_fee = ISNULL(@schedule_service_fee, $0.00)
			SET @overdue_service_fee = @overdue_service_fee + @step_overdue_service_fee
		END
	END
END

RETURN(0)

GO
