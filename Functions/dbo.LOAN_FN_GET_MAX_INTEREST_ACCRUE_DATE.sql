SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[LOAN_FN_GET_MAX_INTEREST_ACCRUE_DATE](@loan_id int)
RETURNS smalldatetime
AS
BEGIN
	DECLARE
		@max_date smalldatetime

	DECLARE
		@interest_date				smalldatetime,
		@overdue_interest_date		smalldatetime,
		@overdue_interest30_date	smalldatetime,
		@penalty_date				smalldatetime,
		@writeoff_date				smalldatetime


	SELECT @interest_date = INTEREST_DATE,
		@overdue_interest_date = OVERDUE_INTEREST_DATE,
		@overdue_interest30_date = OVERDUE_INTEREST30_DATE,
		@penalty_date = PENALTY_DATE,
		@writeoff_date = WRITEOFF_DATE
	FROM dbo.LOAN_ACCOUNT_BALANCE (NOLOCK) 
	WHERE LOAN_ID=@loan_id

	SET @max_date = @interest_date

	IF ISNULL(@max_date, convert(smalldatetime, 0)) < ISNULL(@overdue_interest_date, convert(smalldatetime, 0))
		SET @max_date = @overdue_interest_date

	IF ISNULL(@max_date, convert(smalldatetime, 0)) < ISNULL(@overdue_interest30_date, convert(smalldatetime, 0))
		SET @max_date = @overdue_interest30_date

	IF ISNULL(@max_date, convert(smalldatetime, 0)) < ISNULL(@penalty_date, convert(smalldatetime, 0))
		SET @max_date = @penalty_date

	IF ISNULL(@max_date, convert(smalldatetime, 0)) < ISNULL(@writeoff_date, convert(smalldatetime, 0))
		SET @max_date = @writeoff_date
	
	RETURN @max_date
END
GO
