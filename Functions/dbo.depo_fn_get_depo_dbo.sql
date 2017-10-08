SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_depo_dbo]
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

	SELECT @result = SUM(AMOUNT)
	FROM dbo.OPS_FULL O (NOLOCK)
		INNER JOIN dbo.OPS_HELPER_FULL H (NOLOCK) ON O.REC_ID = H.REC_ID AND O.DEBIT_ID = H.ACC_ID
	WHERE H.ACC_ID = @acc_id AND H.DT BETWEEN @start_date AND @end_date AND ISNULL(O.OP_CODE, '') <> '*%TX*'

	RETURN(ISNULL(@result, $0.00))
END
GO
