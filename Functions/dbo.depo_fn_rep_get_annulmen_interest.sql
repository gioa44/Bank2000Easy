SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_rep_get_annulmen_interest](@start_date smalldatetime, @annulment_date smalldatetime, @days_in_year int, @depo_amount money, @annulment_amount money)
--აბრუნდებს დარღვევამდან გამომდინარე, ანაბრის ფაქტობრივ პროცენტს
RETURNS money
AS
BEGIN
	DECLARE
		@result decimal(32, 12),
		@depo_life_days float
		
	SET @depo_life_days = DATEDIFF(DAY, @start_date, @annulment_date)

	IF (ISNULL(@depo_life_days, 0) = 0) OR (ISNULL(@depo_amount, $0.00) = 0) 
		RETURN $0.00

	SET @result = @annulment_amount * 100.00 * @days_in_year / @depo_amount / @depo_life_days

	RETURN ROUND(@result, 2)
END
GO
