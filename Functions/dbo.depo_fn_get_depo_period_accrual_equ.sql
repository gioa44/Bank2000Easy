SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_depo_period_accrual_equ]
(
	@acc_id int,
	@start_date smalldatetime,
	@end_date smalldatetime
)
RETURNS money
AS
BEGIN

DECLARE 
	@result money	

	SELECT @result = SUM(AMOUNT_EQU)
	FROM dbo.OPS_FULL O (NOLOCK)
	WHERE O.DOC_DATE BETWEEN @start_date AND @end_date AND O.ACCOUNT_EXTRA = @acc_id AND ISNULL(O.OP_CODE, '') = '*%AC*'

	RETURN(ISNULL(@result, $0.00))
END
GO
