SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PROCESS_ACCRUAL]
	@perc_type tinyint,
	@acc_id int,
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@force_calc bit = 0,
	@force_realization bit = 0,
	@simulate bit = 0,
	@recalc_option tinyint = 0,	-- 0x00 - Auto
								-- 0x01 - Calc as usual (last accrual)
								-- 0x02 - Recalc from last realize date
								-- 0x04 - Recalc from beginning
	@formula varchar(512) = NULL,
	@accrue_amount money = NULL,
	@restart_calc bit = 0,
	@show_result bit = 1,
	@restore_acc_id int = NULL,
	@depo_depo_id int = NULL,
	@depo_op_type smallint = NULL,
	@depo_op_id int = NULL,
	@interest_amount money = NULL OUTPUT,
	@rec_id int = NULL OUTPUT,
	@depo_op_doc_rec_id int = NULL OUTPUT
AS

SET NOCOUNT ON;



DECLARE
	@r int,
	@depo_new bit

IF EXISTS(
	SELECT *
	FROM dbo.DEPTS
	WHERE CODE9 IN (
		220101757 --ÒÄÓÐÖÁËÉÊÀ
		,220101601 --VTB ãÏÒãÉÀ
		,220101722 --ÐÒÏÂÒÄÓ ÁÀÍÊÉ
		,220101912 -- ÀÆÄÒÁÀÉãÀÍÉÓ ÓÀÄÒÈÀÛÏÒÉÓÏ ÁÀÍÊÉ
	))

	SET @depo_new = 1
ELSE
	SET @depo_new = 0


IF @depo_new = 1
	EXEC dbo.PROCESS_ACCRUAL_DEPO_NEW
		@perc_type = @perc_type,
		@acc_id = @acc_id,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @doc_date,
		@calc_date = @calc_date,
		@force_calc = @force_calc,
		@force_realization = @force_realization,
		@simulate = @simulate,
		@recalc_option = @recalc_option,
		@formula = @formula,
		@accrue_amount = @accrue_amount,
		@restart_calc = @restart_calc,
		@show_result = @show_result,
		@restore_acc_id = @restore_acc_id,
		@depo_depo_id = @depo_depo_id,
		@depo_op_type = @depo_op_type,
		@depo_op_id = @depo_op_id,
		@interest_amount = @interest_amount OUTPUT,
		@rec_id = @rec_id OUTPUT,
		@depo_op_doc_rec_id = @depo_op_doc_rec_id OUTPUT
ELSE
	EXEC dbo.PROCESS_ACCRUAL_DEPO_OLD
		@perc_type = @perc_type,
		@acc_id = @acc_id,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @doc_date,
		@calc_date = @calc_date,
		@force_calc = @force_calc,
		@force_realization = @force_realization,
		@simulate = @simulate,
		@recalc_option = @recalc_option,
		@formula = @formula,
		@accrue_amount = @accrue_amount,
		@restart_calc = @restart_calc,
		@show_result = @show_result,
		@restore_acc_id = @restore_acc_id,
		@depo_depo_id = @depo_depo_id,
		@depo_op_type = @depo_op_type,
		@depo_op_id = @depo_op_id,
		@interest_amount = @interest_amount OUTPUT,
		@rec_id = @rec_id OUTPUT,
		@depo_op_doc_rec_id = @depo_op_doc_rec_id OUTPUT

IF @@ERROR <> 0 OR @r <> 0
BEGIN
	RAISERROR ('ÛÄÝÃÏÌÀ ÃÀÒÉÝáÅÉÓ ÛÄÓÒÖËÄÁÉÓ ÃÒÏÓ', 16, 1);
	RETURN @r;
END

RETURN 0;
GO
