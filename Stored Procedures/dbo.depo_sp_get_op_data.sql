SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_get_op_data]
	@op_id int,
	@op_type int
AS
	IF (@op_type = dbo.depo_fn_const_op_active())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_ACTIVE WHERE OP_ID = @op_id
	ELSE	
	IF (@op_type = dbo.depo_fn_const_op_accumulate())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_ACCUMULATE WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_realize_interest())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_REALIZE_INTEREST WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_bonus())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_BONUS WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_withdraw())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_WITHDRAW WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_withdraw_interest_tax())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_WITHDRAW_INTEREST_TAX WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_withdraw_schedule())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_WITHDRAW_SCHEDULE WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_mark2default())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_MARK2DEFAULT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_revision())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_REVISION WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_intrate_change())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CHANGE_INTRATE WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_taxrate_change())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CHANGE_TAXRATE WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_intrate_advance())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CHANGE_INTRATE_ADVANCE WHERE OP_ID = @op_id
	ELSE	
	IF (@op_type = dbo.depo_fn_const_op_function_advance())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CHANGE_FUNCTION_ADVANCE WHERE OP_ID = @op_id
	ELSE	
	IF (@op_type = dbo.depo_fn_const_op_prolongation())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_PROLONGATION WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_prolongation_intrate_change())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_PROLONGATION_INTRATE_CHANGE WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_change_depo_realize_account())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CHANGE_DEPO_REALIZE_ACCOUNT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_change_interest_realize_account())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CHANGE_INTEREST_REALIZE_ACCOUNT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_renew())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_RENEW WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_change_officer())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CHANGE_OFFICER WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_convert())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CONVERT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_block_amount())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_BLOCK_AMOUNT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_clear_block_amount())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CLEAR_BLOCK_AMOUNT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_break_renew())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_BREAK_RENEW WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_resume_renew())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_RESUME_RENEW WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_allow_renew())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_ALLOW_RENEW WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_allow_prolongation())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_ALLOW_PROLONGATION WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_annulment())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_ANNULMENT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_annulment_amount())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_ANNULMENT_AMOUNT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_annulment_positive())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_ANNULMENT_POSITIVE WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_close_default())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CLOSE_DEFAULT WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.depo_fn_const_op_close())
		SELECT * FROM dbo.DEPO_VW_OP_DATA_CLOSE WHERE OP_ID = @op_id
GO
