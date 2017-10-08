SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [export].[get_close_date](@loan_id int)
RETURNS smalldatetime
AS
BEGIN

DECLARE
	@op_date smalldatetime

	SELECT 
		@op_date = OP_DATE 
	FROM dbo.LOAN_OPS (NOLOCK) 
	WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_close()

	RETURN @op_date
END
GO
