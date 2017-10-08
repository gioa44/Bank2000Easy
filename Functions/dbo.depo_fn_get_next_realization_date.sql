SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_next_realization_date](@date datetime, @start_date datetime, @end_date datetime, @realize_type int, @realize_count int, @realize_count_type int, @perc_flags int)
RETURNS smalldatetime
AS
BEGIN
	-- Constants 
	DECLARE
		@pmtEachPeriod  int,
		@pmtEndPeriod   int,

		@pmtByEnd       int,
		@pmtByDay       int,
		@pmtByMonth     int,
		@pmtByMonth30   int,

		@pfDontIncludeStartDate int


	SET	@pmtEachPeriod  = 1
	SET	@pmtEndPeriod   = 2

	SET	@pmtByEnd       = 0
	SET	@pmtByDay       = 1
	SET	@pmtByMonth     = 2
	SET	@pmtByMonth30   = 3

	SET	@pfDontIncludeStartDate = 1

	---

	DECLARE
		@mm int,
		@d datetime,
		@dd datetime,
		@delta int
		
	DECLARE 
		@result smalldatetime
		

	IF @date = @end_date
	BEGIN
		SET @result = @date
		RETURN(@result)
	END 

	IF @realize_type = @pmtEndPeriod AND DAY(@date + 1) = 1 AND
		MONTH(@date) = MONTH(@end_date) AND YEAR(@date) = YEAR(@end_date)
	BEGIN
		SET @result = @date
		RETURN(@result)
	END

	IF @date > @end_date
	BEGIN
		SET @result = NULL
		RETURN(@result)
	END
	 
	IF @date = @start_date
	BEGIN
		IF @perc_flags & @pfDontIncludeStartDate <> 0 
		BEGIN
			SET @result = NULL
			RETURN(@result)
		END	
		ELSE
		BEGIN
			SET @result = @date
			RETURN(@result)
		END
	END

	IF @realize_type = @pmtEachPeriod  -- every xxx yy
	BEGIN
		IF @realize_count_type = @pmtByDay -- every xxx day
		BEGIN
			IF @realize_count = 1
			BEGIN
				SET @result = @date
				RETURN(@result)
			END

			SET @result = DATEADD(DAY, @realize_count, @start_date)
			WHILE @result < @date
				SET @result = DATEADD(DAY, @realize_count, @result)
			RETURN(@result)
		END
		ELSE
		IF @realize_count_type IN (@pmtByMonth, @pmtByMonth30) --   pmtByMonth = 2;  pmtByMonth30 = 3, every xxx month
		BEGIN
			SET @result = @start_date
			WHILE @result < @date
				SET @result = DATEADD(month, @realize_count, @result)
			RETURN(@result)	
		END
	END
	ELSE
	IF @realize_type = 2 -- pmtEndPeriod   = 2, at end of xxx yy
	BEGIN
		IF @realize_count_type = @pmtByEnd -- at end of end_date
		BEGIN
			SET @result = @end_date
			RETURN(@result)
		END
		ELSE
		IF @realize_count_type = @pmtByMonth -- at end of every xxx month
		BEGIN
			SET @result  = CONVERT(datetime, CONVERT(char(4),YEAR(@start_date)) + '0101')
			WHILE DATEADD(DAY, -1, @result) < ISNULL(@end_date, @start_date)
				SET @result = DATEADD(month, @realize_count, @result)
			SET @result = DATEADD(DAY, -1, @result)
			RETURN(@result)
		END
	END
	RETURN 0

	SET @result = NULL

	RETURN(@result)
END
GO
