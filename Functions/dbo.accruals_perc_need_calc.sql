SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[accruals_perc_need_calc] (@dt smalldatetime, @start_date smalldatetime, @end_date smalldatetime, @calc_type int, @perc_flags int)
RETURNS bit
AS
BEGIN

	-- Constants
	DECLARE
		@pctEveryDay    int,
		@pctDecade      int,
		@pctMonth       int,
		@pctEnd         int,
		@pctQuorter     int,
		@pctSemester    int,
		@pctWeek        int,
		@pctNone        int,

		@pfDontIncludeStartDate int


	SET	@pctEveryDay    = 0
	SET	@pctDecade      = 1
	SET	@pctMonth       = 2
	SET	@pctEnd         = 3
	SET	@pctQuorter     = 4
	SET	@pctSemester    = 5
	SET	@pctWeek        = 6
	SET	@pctNone        = 99

	SET	@pfDontIncludeStartDate = 1

	---

	DECLARE
		@yy int,
		@mm int,
		@dd int,
		@result bit

	IF @calc_type = @pctNone
		RETURN 0
  
	SET @result = CASE WHEN @dt = @end_date THEN 1 ELSE 0 END

	IF @dt = @start_date AND(@perc_flags & @pfDontIncludeStartDate <> 0)
		RETURN @result

	IF @result <> 0 OR @dt > @end_date
		RETURN @result

	IF @calc_type = @pctEveryDay 
		RETURN 1 -- every day
	ELSE
	IF @calc_type = @pctDecade	-- end of Decade (10, 20 and Last day of month
		RETURN CASE WHEN DAY(@dt+1) IN (1, 11, 21) THEN 1 ELSE 0 END
	ELSE
    IF @calc_type = @pctMonth -- end of month
		RETURN CASE WHEN DAY(@dt + 1) = 1 THEN 1 ELSE 0 END
	ELSE
    IF @calc_type = @pctEnd -- end of period
		RETURN CASE WHEN @dt = @end_date THEN 1 ELSE 0 END
	ELSE
	IF @calc_type = @pctNone
		RETURN 0
	
	RETURN 0
END
GO
