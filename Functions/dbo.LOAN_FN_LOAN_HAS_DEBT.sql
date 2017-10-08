SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[LOAN_FN_LOAN_HAS_DEBT](@loan_id int)
RETURNS bit
AS
BEGIN
DECLARE
    @loan_debt money,
	@result bit

SELECT 
	@loan_debt = ISNULL(PRINCIPAL, $0.00) + ISNULL(INTEREST, $0.00) + ISNULL(NU_INTEREST, $0.00) + 
			     ISNULL(LATE_PRINCIPAL, $0.00) + ISNULL(LATE_PERCENT, $0.00) + 
 			     ISNULL(OVERDUE_PRINCIPAL, $0.00) + ISNULL(OVERDUE_PRINCIPAL_INTEREST, $0.00) + ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00) + 
			     ISNULL(OVERDUE_PERCENT, $0.00) + ISNULL(OVERDUE_PERCENT_PENALTY, $0.00) + ISNULL(CALLOFF_PRINCIPAL, $0.00) + 
			     ISNULL(CALLOFF_PRINCIPAL_INTEREST, $0.00) + ISNULL(CALLOFF_PRINCIPAL_PENALTY, $0.00) + ISNULL(CALLOFF_PERCENT, $0.00) + 
			     ISNULL(CALLOFF_PERCENT_PENALTY, $0.00) + ISNULL(CALLOFF_PENALTY, $0.00) + ISNULL(WRITEOFF_PRINCIPAL, $0.00) + 
			     ISNULL(WRITEOFF_PRINCIPAL_PENALTY, $0.00) + ISNULL(WRITEOFF_PERCENT, $0.00) + 
			     ISNULL(WRITEOFF_PERCENT_PENALTY, $0.00) + ISNULL(WRITEOFF_PENALTY, $0.00) +
			     ISNULL(OVERDUE_INSURANCE, $0.00) + ISNULL(OVERDUE_SERVICE_FEE, $0.00) +
				 ISNULL(DEFERABLE_INTEREST, $0.00) + ISNULL(DEFERABLE_OVERDUE_INTEREST, $0.00) + ISNULL(DEFERABLE_PENALTY, $0.00) + ISNULL(DEFERABLE_FINE, $0.00) +
				 ISNULL(REMAINING_FEE, $0.00)
FROM dbo.LOAN_DETAILS WHERE LOAN_ID = @loan_id

RETURN CASE WHEN @loan_debt > 0 THEN 1 ELSE 0 END

END

GO
