SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[loan_get_loan_detail_data](@loan_id int, @date smalldatetime)
RETURNS
	@loan_detail_data TABLE (
	LOAN_ID int NOT NULL PRIMARY KEY,
	CALC_DATE smalldatetime NOT NULL,
	NU_PRINCIPAL money NULL,
	NU_INTEREST money NULL,
	PRINCIPAL money NULL,
	INTEREST money NULL,
		
	LATE_PRINCIPAL money NULL, 
	LATE_PERCENT money NULL,

	OVERDUE_DAYS int NULL,
	OVERDUE_DATE smalldatetime NULL,
    OVERDUE_PRINCIPAL money NULL,
	OVERDUE_PRINCIPAL_INTEREST money NULL,
	OVERDUE_PRINCIPAL_PENALTY money NULL,

	OVERDUE_PERCENT money NULL,
	OVERDUE_PERCENT_PENALTY money NULL,

	WRITEOFF_PRINCIPAL money NULL,
	WRITEOFF_PERCENT money NULL,
	WRITEOFF_PENALTY money NULL,
	REMAINING_FEE money NULL,
	CATEGORY_1 money NULL,
	CATEGORY_2 money NULL,
	CATEGORY_3 money NULL,
	CATEGORY_4 money NULL,
	CATEGORY_5 money NULL	
)
AS
BEGIN
DECLARE 
	@first_prolong_date smalldatetime,
	@second_prolong_date smalldatetime
	
	SELECT @first_prolong_date = MIN(OP_DATE) FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = 130
	SELECT @second_prolong_date = MIN(OP_DATE) FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = 130 AND OP_DATE > @first_prolong_date


	IF EXISTS (SELECT LOAN_ID FROM dbo.LOAN_DETAILS WHERE CALC_DATE = @date AND LOAN_ID = @loan_id)
	BEGIN
		INSERT INTO @loan_detail_data
		(LOAN_ID, CALC_DATE, NU_PRINCIPAL, NU_INTEREST, PRINCIPAL, INTEREST, LATE_PRINCIPAL, LATE_PERCENT, 
		 OVERDUE_DAYS, OVERDUE_DATE, OVERDUE_PRINCIPAL, OVERDUE_PRINCIPAL_INTEREST, OVERDUE_PRINCIPAL_PENALTY, OVERDUE_PERCENT, OVERDUE_PERCENT_PENALTY,
		 WRITEOFF_PRINCIPAL, WRITEOFF_PERCENT, WRITEOFF_PENALTY, REMAINING_FEE,
		 CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4, CATEGORY_5)
		SELECT LOAN_ID, CALC_DATE, ISNULL(NU_PRINCIPAL, $0.00), ISNULL(NU_INTEREST, $0.00), ISNULL(PRINCIPAL, $0.00), ISNULL(INTEREST, $0.00) + ISNULL(DEFERABLE_INTEREST, $0.00), 
				ISNULL(LATE_PRINCIPAL, $0.00), ISNULL(LATE_PERCENT, $0.00),
                DATEDIFF(DAY, OVERDUE_DATE, @date) AS OVERDUE_DAYS, OVERDUE_DATE, 
				ISNULL(OVERDUE_PRINCIPAL, $0.0), ISNULL(OVERDUE_PRINCIPAL_INTEREST, $0.0), ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.0), 
				ISNULL(OVERDUE_PERCENT, $0.0), ISNULL(OVERDUE_PERCENT_PENALTY, $0.0),
				ISNULL(WRITEOFF_PRINCIPAL, $0.0), ISNULL(WRITEOFF_PERCENT, $0.0), ISNULL(WRITEOFF_PENALTY, $0.0), ISNULL(REMAINING_FEE, $0.0),
				ISNULL(CATEGORY_1, $0.0), ISNULL(CATEGORY_2, $0.0), ISNULL(CATEGORY_3, $0.0), ISNULL(CATEGORY_4, $0.0), ISNULL(CATEGORY_5, $0.0)
		FROM dbo.LOAN_DETAILS
		WHERE LOAN_ID = @loan_id
	END
	ELSE
	BEGIN
		INSERT INTO @loan_detail_data
		(LOAN_ID, CALC_DATE, NU_PRINCIPAL, NU_INTEREST, PRINCIPAL, INTEREST, LATE_PRINCIPAL, LATE_PERCENT, OVERDUE_DAYS,
		 OVERDUE_DATE, OVERDUE_PRINCIPAL, OVERDUE_PRINCIPAL_INTEREST, OVERDUE_PRINCIPAL_PENALTY, OVERDUE_PERCENT, OVERDUE_PERCENT_PENALTY,
		 WRITEOFF_PRINCIPAL, WRITEOFF_PERCENT, WRITEOFF_PENALTY, REMAINING_FEE,
		 CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4, CATEGORY_5)
		SELECT LOAN_ID, CALC_DATE, ISNULL(NU_PRINCIPAL, $0.00), ISNULL(NU_INTEREST, $0.00), ISNULL(PRINCIPAL, $0.00), ISNULL(INTEREST, $0.00) + ISNULL(DEFERABLE_INTEREST, $0.00), 
				ISNULL(LATE_PRINCIPAL, $0.00), ISNULL(LATE_PERCENT, $0.00),
                DATEDIFF(DAY, OVERDUE_DATE, @date) AS OVERDUE_DAYS, OVERDUE_DATE, 
				ISNULL(OVERDUE_PRINCIPAL, $0.0), ISNULL(OVERDUE_PRINCIPAL_INTEREST, $0.0), ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.0), 
				ISNULL(OVERDUE_PERCENT, $0.0), ISNULL(OVERDUE_PERCENT_PENALTY, $0.0),
				ISNULL(WRITEOFF_PRINCIPAL, $0.0), ISNULL(WRITEOFF_PERCENT, $0.0), ISNULL(WRITEOFF_PENALTY, $0.0), ISNULL(REMAINING_FEE, $0.0),
				ISNULL(CATEGORY_1, $0.0), ISNULL(CATEGORY_2, $0.0), ISNULL(CATEGORY_3, $0.0), ISNULL(CATEGORY_4, $0.0), ISNULL(CATEGORY_5, $0.0)
		FROM dbo.LOAN_DETAILS_HISTORY
		WHERE CALC_DATE = @date AND LOAN_ID = @loan_id
	END	
RETURN
END
GO
