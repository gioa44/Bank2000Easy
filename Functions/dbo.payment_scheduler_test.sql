SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[payment_scheduler_test] (@day tinyint, @pay_date smalldatetime, @last_pay_date smalldatetime)
RETURNS bit
AS
BEGIN

	DECLARE
		@last_day_of_this_month tinyint,
		@result bit

	SET @result = 0
	SET @last_day_of_this_month = day(dateadd(ms,-3,dateadd(mm, datediff(m,0, @pay_date )+1, 0)))

	IF (@day = 254 AND (datediff(d,@last_pay_date,@pay_date) >= 1) )
	BEGIN
		SET @result = 1
	END
	ELSE
	IF ((@day = 255) AND (DAY(@pay_date) >= @last_day_of_this_month) AND (datediff(d,@last_pay_date,@pay_date) > 0) )
	BEGIN
		SET @result = 1
	END
	ELSE
	IF (@day < @last_day_of_this_month) AND (@day >= DAY(@pay_date)) AND (@day <= DAY(@pay_date)) AND (datediff(d,@last_pay_date,@pay_date) > 0)
	BEGIN
		SET @result = 1
	END
	ELSE
	IF (@day < DAY(@pay_date) AND (datediff(d,@last_pay_date,@pay_date) > DAY(@pay_date) - @day))
	BEGIN
		SET @result = 1
	END
	ELSE
	IF (@day >= @last_day_of_this_month) AND DAY(@pay_date) = @last_day_of_this_month  AND datediff(d,@last_pay_date,@pay_date) > 0
	BEGIN
		SET @result = 1
	END

	RETURN @result
END
GO
