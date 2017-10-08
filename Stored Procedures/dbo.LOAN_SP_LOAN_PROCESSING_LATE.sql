SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_PROCESSING_LATE]
	@loan_id				int,
	@date					smalldatetime,
	@op_commit				bit OUTPUT,
	@schedule_date			smalldatetime,
	@schedule_nu_interest	money OUTPUT,
	@schedule_interest		money OUTPUT,
	@schedule_principal		money OUTPUT,
	@nu_interest			money OUTPUT,
	@interest				money OUTPUT,
	@principal				money OUTPUT,
	@late_date				smalldatetime OUTPUT,
	@late_percent			money OUTPUT,
	@late_principal			money OUTPUT,
	@step_late_date			smalldatetime OUTPUT,
	@step_late_percent		money OUTPUT,
	@step_late_principal	money OUTPUT

AS
  
SET NOCOUNT ON
SET @op_commit = 0

IF (@schedule_date = @date)
BEGIN
    IF ISNULL(@schedule_nu_interest, $0.00) + ISNULL(@schedule_interest, $0.00) > $0.00 OR
		ISNULL(@schedule_principal, $0.00) > $0.00 
	BEGIN
		SET @op_commit = 1
		SET @step_late_date = @date
		SET @step_late_percent = ISNULL(@schedule_nu_interest, $0.00) + ISNULL(@schedule_interest, $0.00) 
		SET @step_late_principal = ISNULL(@schedule_principal, $0.00)

		IF @late_date IS NULL
			SET @late_date = @step_late_date
		SET @late_percent = @late_percent + @step_late_percent
		SET @late_principal = @late_principal + @step_late_principal

		SET @nu_interest = $0.00
		SET @interest = $0.00
		SEt @principal = @principal - @schedule_principal
		SET @schedule_nu_interest = $0.00
		SET @schedule_interest = $0.00
		SET @schedule_principal = $0.00
	END
END
RETURN(0)
GO
