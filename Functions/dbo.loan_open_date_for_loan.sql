SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_open_date_for_loan](@loan_id int)
RETURNS smalldatetime AS
BEGIN
	DECLARE
		@calc_date smalldatetime 

	SELECT @calc_date = CALC_DATE
	FROM dbo.LOAN_DETAILS
	WHERE LOAN_ID = @loan_id
	
	RETURN (@calc_date)
END
GO
