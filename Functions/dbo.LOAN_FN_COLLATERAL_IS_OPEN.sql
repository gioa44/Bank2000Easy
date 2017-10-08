SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[LOAN_FN_COLLATERAL_IS_OPEN] (@collateral_id int)
RETURNS bit
BEGIN

DECLARE
	@result bit

SET @result = 0
	
	IF EXISTS (SELECT * FROM	
			(SELECT L.STATE AS [STATE] FROM dbo.LOAN_COLLATERALS_LINK lnk (NOLOCK)
			INNER JOIN dbo.LOANS L (NOLOCK) ON lnk.LOAN_ID = L.LOAN_ID 
			WHERE lnk.COLLATERAL_ID = @collateral_id

			UNION 

			SELECT L.STATE AS [STATE] FROM dbo.LOAN_COLLATERALS C (NOLOCK)
			INNER JOIN dbo.LOANS L (NOLOCK) ON C.LOAN_ID = L.LOAN_ID
			WHERE C.COLLATERAL_ID = @collateral_id) A 
			WHERE (A.[STATE] >= dbo.loan_const_op_auth_level1()) AND (A.[STATE] < dbo.loan_const_state_closed()))
		SET @result = 1
	ELSE 
		IF EXISTS (SELECT * FROM	
				(SELECT L.STATE AS [STATE] FROM dbo.LOAN_CREDIT_LINE_COLLATERALS_LINK lnk (NOLOCK)
				INNER JOIN dbo.LOAN_CREDIT_LINES L (NOLOCK) ON lnk.CREDIT_LINE_ID = L.CREDIT_LINE_ID
				WHERE lnk.COLLATERAL_ID = @collateral_id

				UNION 

				SELECT L.STATE AS [STATE] FROM dbo.LOAN_COLLATERALS C (NOLOCK)
				INNER JOIN dbo.LOAN_CREDIT_LINES L (NOLOCK) ON C.CREDIT_LINE_ID = L.CREDIT_LINE_ID
				WHERE C.COLLATERAL_ID = @collateral_id) A 
				WHERE (A.[STATE] >= dbo.loan_credit_line_const_op_authorize_1()) AND (A.[STATE] < dbo.loan_credit_line_const_state_closed()))
			SET @result = 1
		
	RETURN @result
END

GO
