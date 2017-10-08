SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* ––ეს უნდა დაემატოს dbo.CLOSE_DAY პროცედურას საბუთების ავტორიზაციის შემოწმების შემდეგ
IF EXISTS (SELECT * FROM dbo.DEPO_OP WHERE OP_DATE <= @dt AND OP_STATE = 0)
BEGIN
  RAISERROR ('ÀÒÉÓ ÃÀÖÓÒÖËÄÁÄËÉ ÏÐÄÒÀÝÉÄÁÉ ÀÍÀÁÒÄÁÆÄ. ÃÙÉÓ ÃÀáÖÒÅÀ ÀÒ ÛÄÉÞËÄÁÀ',16,1)
  ROLLBACK TRAN
  RETURN (104)
END
*/

CREATE FUNCTION [dbo].[date_is_short_day](@date smalldatetime)  
RETURNS bit AS  
BEGIN
	DECLARE
		@is_short_day bit,
		@day_type tinyint
	
	SET @is_short_day = 0


	SELECT @day_type = DAY_TYPE
	FROM dbo.CALENDAR (NOLOCK)
	WHERE DT = @date
	
	SET @date = DATEADD(DAY, 1, @date) -- შემდეგში შემოწმება ხდება კვირა დღეზე (ანუ კვირის წინა დღე არის შაბათი)
 
	IF @day_type IS NULL
		SET @is_short_day = CASE WHEN DATEPART (weekday, @date) = 8 - @@DATEFIRST THEN 1 ELSE 0 END
	ELSE
		SET @is_short_day = CASE WHEN @day_type = 1 THEN 1 ELSE 0 END

	RETURN (@is_short_day)
END
GO
