SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_auto_prolongation_params_on_user]
	@depo_id int,
	@end_date smalldatetime,
	@intrate money,
	@new_end_date smalldatetime OUTPUT,
	@new_intrate money OUTPUT
AS
SET NOCOUNT ON;

SET @new_intrate = $3.00
SET @new_end_date = DATEADD(MONTH, 3, @end_date)

IF dbo.date_is_holiday(@new_end_date) = 1
BEGIN
	DECLARE
		@holiday_type int
		
	EXEC dbo.GET_SETTING_INT
		@param_name = 'OPT_D_HOLIDAY_TYPE',
		@int_val = @holiday_type
		
	IF @holiday_type = 1 --შემდეგი სამუშაო დღე
		SET @new_end_date = dbo.date_next_workday(@new_end_date)
	ELSE
	IF @holiday_type = 2 --წინა სამუშაო დღე
		SET @new_end_date = dbo.date_prev_workday(@new_end_date)
END
RETURN 0

GO
