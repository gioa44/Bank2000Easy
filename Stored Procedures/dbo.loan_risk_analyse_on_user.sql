SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[loan_risk_analyse_on_user]
	@loan_id int,
	@date smalldatetime,
	@principal money,
	@principal_overdue money,
	@calloff_date smalldatetime,
	@principal_calloff money,
	@principal_writeoff money,
	@category_1 money OUTPUT,
	@category_2 money OUTPUT,
	@category_3 money OUTPUT,
	@category_4 money OUTPUT,
	@category_5 money OUTPUT,
	@category_6 money OUTPUT,
	@max_category_level tinyint OUTPUT,
	@user_handled bit OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE
		@r int

	SET @user_handled = 1

	EXEC @r = dbo.loan_risk_analyse_basel2
		@loan_id = @loan_id,
		@date = @date,
		@principal = @principal, 
		@overdue_principal = @principal_overdue,
		@calloff_principal = @principal_calloff,
		@writeoff_principal = @principal_writeoff,
		@category_1 = @category_1 OUTPUT,
		@category_2 = @category_2 OUTPUT,
		@category_3 = @category_3 OUTPUT,
		@category_4 = @category_4 OUTPUT,
		@category_5 = @category_5 OUTPUT,
		@category_6 = @category_6 OUTPUT,
		@max_category_level = @max_category_level OUTPUT

	RETURN @r
END

GO
