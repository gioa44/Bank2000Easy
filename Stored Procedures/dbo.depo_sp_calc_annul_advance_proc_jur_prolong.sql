SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_calc_annul_advance_proc_jur_prolong]
	@depo_id int,
	@user_id int,
	@dept_no int,
	@annul_date smalldatetime,
	@start_point tinyint OUTPUT,
	@annul_intrate money OUTPUT,
	@annul_amount money OUTPUT
AS
SET NOCOUNT ON;

SET @annul_amount = $0.00

DECLARE
	@prolongation_count int,
	@depo_acc_id int

SELECT @prolongation_count = ISNULL(PROLONGATION_COUNT, 0), @depo_acc_id = DEPO_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: DEPOSIT DATA NOT FOUND', 16, 1); RETURN 1; END	

IF @prolongation_count > 0
BEGIN
	SELECT @annul_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00)
	FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
	WHERE ACC_ID = @depo_acc_id
	
	SET @annul_amount = ROUND(@annul_amount, 2) 	 
END


RETURN 0
GO
