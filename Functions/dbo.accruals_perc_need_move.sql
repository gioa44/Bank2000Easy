SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[accruals_perc_need_move] (@dt datetime, @start_date datetime, @end_date datetime, @move_type int, @move_num int, @move_num_type int, @perc_flags int)
RETURNS bit
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

	IF @dt = @end_date 
		RETURN 1

	IF @move_type = @pmtEndPeriod AND DAY(@dt + 1) = 1 AND
		MONTH(@dt) = MONTH(@end_date) AND YEAR(@dt) = YEAR(@end_date)	RETURN 1

	IF @dt > @end_date RETURN 0
	IF @dt = @start_date
	BEGIN
		IF @perc_flags & @pfDontIncludeStartDate <> 0 
			RETURN 0
		ELSE
			RETURN 1
	END

	IF @move_type = @pmtEachPeriod  -- every xxx yy
	BEGIN
		IF @move_num_type = @pmtByDay -- every xxx day
		BEGIN
			IF @move_num = 1 RETURN 1
			IF DATEDIFF(d, @start_date, @dt) % @move_num = 0
				RETURN 1
		END
		ELSE
		IF @move_num_type IN (@pmtByMonth, @pmtByMonth30) --   pmtByMonth = 2;  pmtByMonth30 = 3, every xxx month
		BEGIN
			SET @mm = 1
			SET @d = @start_date
			WHILE @d < @end_date
			BEGIN
				SET @d = DATEADD(month, @mm * @move_num, @start_date)
				IF @d = @dt
					RETURN 1
				SET @mm = @mm + 1
			END
		END
	END
	ELSE
	IF @move_type = 2 -- pmtEndPeriod   = 2, at end of xxx yy
	BEGIN
		IF @move_num_type = @pmtByEnd -- at end of end_date
		  RETURN CASE WHEN @dt = @end_date THEN 1 ELSE 0 END
		ELSE
		IF @move_num_type = @pmtByDay -- at end of xxx day
		  RETURN 0 -- Invalid schema
		ELSE
		IF @move_num_type = @pmtByMonth -- at end of every xxx month
		BEGIN
			SET @mm = 1
			SET @dd = CONVERT(datetime, CONVERT(char(4),YEAR(@start_date)) + '0101')
			SET @d  = @dd - 1
			WHILE @d < @end_date
			BEGIN
				SET @d = DATEADD(month, @mm * @move_num, @dd) - 1
				IF @d = @dt
					RETURN 1
				SET @mm = @mm + 1
			END
		END
	END
	RETURN 0
END
GO
