SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_calc_annul_advance_proc_term_renew_month]
	@depo_id int,
	@user_id int,
	@dept_no int,
	@annul_date smalldatetime,
	@start_point tinyint OUTPUT,
	@annul_intrate money OUTPUT,
	@annul_amount money OUTPUT
AS
SET NOCOUNT ON;

SET @annul_amount = NULL

DECLARE
	@start_date smalldatetime,
	@last_renew_date smalldatetime

SELECT @start_date = [START_DATE], @last_renew_date = LAST_RENEW_DATE
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: DEPOSIT DATA NOT FOUND', 16, 1); RETURN 1; END	

IF @last_renew_date IS NOT NULL
BEGIN
	IF @annul_date <= DATEADD(MONTH, 1, @start_date)
		SET @annul_amount = $0.00
END


RETURN 0
GO
