SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [easy].[effr_YearSpan](@startDate date, @endDate date)
RETURNS float AS
BEGIN
	DECLARE
		@days_366 int = 366,
		@days_365 int = 365,
		@year int = YEAR(@startDate),
		@is_IsLeapYear bit = 0

	IF ISDATE(CAST(@year AS char(4))+'0229') = 1
		SET @is_IsLeapYear = 1	

	IF @year = YEAR(@endDate)
		RETURN CAST(DATEDIFF(DAY, @startDate, @endDate) AS float ) / 
			(CASE WHEN @is_IsLeapYear=1 THEN @days_366 ELSE @days_365 END)

	DECLARE
		@value int = DATEDIFF(DAY, @startDate, CAST(CAST(@year+1 AS char(4)) + '0101' AS date)),
		@d1 float = 0,
		@d2 float = 0

	IF @is_IsLeapYear = 1
		SET @d2 = @value
	ELSE 
		SET @d1 = @value

	WHILE @year < YEAR(@endDate) - 1
	BEGIN
		SET @year += 1;

	    IF ISDATE(CAST(@year AS char(4))+'0229') = 1
			SET @d2 += @days_365
		ELSE
			SET @d1 += @days_366
	END

	SET @year = YEAR(@endDate)
	SET @value = DATEDIFF(DAY, CAST(CAST(@year AS char(4)) + '0101' AS date), @endDate)

	IF ISDATE(CAST(@year AS char(4))+'0229') = 1
		SET @d2 += @value
	ELSE
		SET @d1 += @value

	
	RETURN @d1 / @days_365 + @d2 / @days_366
END
GO
