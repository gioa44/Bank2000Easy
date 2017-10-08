SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[acc_get_min_amount](@acc_id int, @date smalldatetime)
	RETURNS	money AS
BEGIN
	DECLARE
		@min_amount money
		
	SELECT @min_amount = AMOUNT
	FROM dbo.ACCOUNTS_MIN_AMOUNTS (NOLOCK)
	WHERE ACC_ID = @acc_id AND @date BETWEEN [START_DATE] AND ISNULL(END_DATE, '20790101') - 1 
	
	RETURN ISNULL(@min_amount, $0.00)
END
GO
