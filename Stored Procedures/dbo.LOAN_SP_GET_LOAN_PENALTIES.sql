SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOAN_PENALTIES]
	@loan_id int
AS 

	SELECT
		ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00) AS OVERDUE_PRINCIPAL_PENALTY,
		ISNULL(OVERDUE_PERCENT_PENALTY, $0.00) AS OVERDUE_PERCENT_PENALTY,
		ISNULL(CALLOFF_PRINCIPAL_PENALTY, $0.00) AS CALLOFF_PRINCIPAL_PENALTY,
		ISNULL(CALLOFF_PERCENT_PENALTY, $0.00) AS CALLOFF_PERCENT_PENALTY,
		ISNULL(WRITEOFF_PRINCIPAL_PENALTY, $0.00) AS WRITEOFF_PRINCIPAL_PENALTY,
		ISNULL(WRITEOFF_PERCENT_PENALTY, $0.00) AS WRITEOFF_PERCENT_PENALTY,
		ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00) + ISNULL(OVERDUE_PERCENT_PENALTY, $0.00) + ISNULL(CALLOFF_PRINCIPAL_PENALTY, $0.00) +
			   ISNULL(CALLOFF_PERCENT_PENALTY, $0.00) + ISNULL(WRITEOFF_PRINCIPAL_PENALTY, $0.00) + ISNULL(WRITEOFF_PERCENT_PENALTY, $0.00) AS PENALTY_SUM
	FROM dbo.LOAN_DETAILS
	WHERE LOAN_ID = @loan_id


GO
