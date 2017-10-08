SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SO_GENERATE_SCHEDULE] (@start_date smalldatetime, @end_date smalldatetime, @period_type int, @days_array varchar(150), @holiday_shifting int)
--@start_date		საწყისი თარიღი
--@end_date			საბოლოო თარიღი
--@period_type		პერიოდის ტიპი:			0x01 ყოველდღიური, 0x02 ყოველკვირეული, 0x04 ყოველთვიური, 0x08 ყოველკვარტლული, 0x10 ყოველსემესტრული, 0x20 ყოველწლიური
--@days_array		დღეების ჩამონათვალი		(bit mask)
--@holiday_shifting დასვენების დღის გადაწევა:		1 წინ, -1 უკან, 0 არსაით, 2 გამოტოვება
AS

DECLARE
	@date smalldatetime,
	@offset int,
	@days varchar(32),
	@step_no int,
	@step_count int,
	@delimiter char,
	@_s_date smalldatetime

SET @delimiter = ';'
SET @step_count = 0

IF @start_date > @end_date
	GOTO return_table

DECLARE @tbl TABLE ([DATE] smalldatetime NOT NULL)
DECLARE @days_tbl TABLE (ID int identity(1,1), VALUE varchar(32) NOT NULL)

SET @days_array = LTRIM(RTRIM(@days_array)) + @delimiter
SET @offset = CHARINDEX(@delimiter, @days_array, 1)

IF REPLACE(@days_array, @delimiter, '') <> ''
BEGIN
	WHILE @offset > 0
	BEGIN
	  SET @days = LTRIM(RTRIM(LEFT(@days_array, @offset - 1)))
	  
	  IF @days <> ''
	  BEGIN
		 INSERT INTO @days_tbl ([VALUE]) 
			SELECT dbo.get_binary_string(CONVERT(int, @days), 0)
		SET @step_count = @step_count + 1
		
		IF (@period_type = 0x02 AND @step_count = 7)
			BREAK
		IF (@period_type = 0x04 AND @step_count = 1)
			BREAK
		IF (@period_type = 0x08 AND @step_count = 3)
			BREAK
		IF (@period_type = 0x10 AND @step_count = 6)
			BREAK
		IF (@period_type = 0x20 AND @step_count = 12)
			BREAK
	  END
	  
	  SET @days_array = RIGHT(@days_array, LEN(@days_array) - @offset)
	  SET @offset = CHARINDEX(@delimiter, @days_array, 1)
	END
END	

IF (@period_type = 0x02)
	SET @_s_date = DATEADD(dd, -DATEPART(dw, @start_date) + 1, @start_date)

IF (@period_type = 0x04 OR @period_type = 0x20)
	SET @_s_date = DATEADD(dd, -DATEPART(dd, @start_date) + 1, @start_date)

IF (@period_type = 0x08)
BEGIN
	SET @_s_date = DATEADD(m, -((DATEPART(m, @start_date) - 1) % 3), @start_date)
	SET @_s_date = DATEADD(dd, -DATEPART(dd, @_s_date) + 1, @_s_date)
END

IF (@period_type = 0x10)
BEGIN
	SET @_s_date = DATEADD(m, -((DATEPART(m, @start_date) - 1) % 7), @start_date)
	SET @_s_date = DATEADD(dd, -DATEPART(dd, @_s_date) + 1, @_s_date)
END

SET @step_no = 0
	
WHILE @_s_date <= @end_date
BEGIN
	SELECT TOP 1 @days = VALUE, @step_no = ID
	FROM @days_tbl
	WHERE ID > @step_no

	IF @@ROWCOUNT > 0	
	BEGIN
		SET @offset = 0

		WHILE LEN(@days) > 0
		BEGIN
		  IF (SUBSTRING(@days, LEN(@days), 1) = '1')
		  BEGIN
			SET @date = DATEADD(dd, @offset, @_s_date)

			IF @date >= @start_date
			BEGIN

				IF dbo.date_is_holiday(@date) = 1 AND @holiday_shifting <> 0
				BEGIN
				  IF @holiday_shifting = 2
					GOTO _continue
				
					SET @date = CASE WHEN @holiday_shifting = 1 THEN dbo.date_next_workday(@date) 
									 WHEN @holiday_shifting = -1 THEN dbo.date_prev_workday(@date) 
									 ELSE @date 
								END
				END

				IF @date > @end_date 
					GOTO return_table

				IF (NOT EXISTS (SELECT * FROM @tbl WHERE [DATE] = @date))
					INSERT INTO @tbl VALUES (@date)
			END
		  END
		  
		_continue:		  
		  SET @offset = @offset + 1
		  SET @days = LEFT(@days, LEN(@days) - 1)
		END
	END

	IF (@step_no = @step_count)
	  SET @step_no = 0
	  
	SET @_s_date = CASE WHEN @period_type = 0x02 THEN DATEADD(ww, 1, @_s_date)
						WHEN @period_type = 0x04 THEN DATEADD(m, 1, @_s_date)
						WHEN @period_type = 0x08 THEN DATEADD(m, 1, @_s_date)
						WHEN @period_type = 0x10 THEN DATEADD(m, 1, @_s_date)
						WHEN @period_type = 0x20 THEN DATEADD(m, 1, @_s_date)
				  END
END

return_table:
SELECT * FROM @tbl
GO
