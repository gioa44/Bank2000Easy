SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[date_is_holiday] (@date smalldatetime)  
RETURNS bit AS  
BEGIN
	DECLARE
		@is_holiday bit,
		@day_type tinyint
	
	SET @is_holiday = 0


	SELECT @day_type = DAY_TYPE
	FROM dbo.CALENDAR (NOLOCK)
	WHERE DT = @date
 
	IF @day_type IS NULL
		SET @is_holiday =
			CASE
				WHEN DATEPART (weekday, @date) = 8 - @@DATEFIRST THEN 1
--				WHEN DATEPART (weekday, @date) IN (8 - @@DATEFIRST, CASE WHEN (7 - @@DATEFIRST) %7 = 0 THEN 7 ELSE (7 - @@DATEFIRST) %7 END) THEN 1
				ELSE 0
			END
	ELSE
		SET @is_holiday = CASE WHEN @day_type = 2 THEN 1 ELSE 0 END

	RETURN (@is_holiday)
END
GO
