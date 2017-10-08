SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GET_OP_DATA]
	@op_id int,
	@op_type int
AS
	IF (@op_type = dbo.loan_const_op_approval())		--ÓÄÓáÉÓ ÃÀÌÔÊÉÝÄÁÀ
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_APPROVAL WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.loan_const_op_disburse())		--ÓÄÓáÉÓ ÂÀÝÄÌÀ
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_DISBURSE WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.loan_const_op_disburse_transh())	--ÓÄÓáÉÓ ÂÀÝÄÌÀ
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_DISBURSE_TRANSH WHERE OP_ID = @op_id
	ELSE
	IF (@op_type = dbo.loan_const_op_stop_disburse())	--ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÀÈÅÉÓÄÁÉÓ ÛÄßÚÅÄÔÀ
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_STOP_DISBURSE WHERE OP_ID = @op_id
	ELSE	
	IF (@op_type = dbo.loan_const_op_dec_disburse())	--ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÀÈÅÉÓÄÁÉÓ ÂÀÆÒÃÀ ÛÄÌÝÉÒÄÁÀ
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_DEC_DISBURSE WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_late()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_LATE WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_overdue()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_OVERDUE WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_payment()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_PAYMENT WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_payment_writedoff()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_PAYMENT_WRITEDOFF WHERE OP_ID = @op_id
	ELSE
	IF @op_type IN (dbo.loan_const_op_restructure(), dbo.loan_const_op_loan_correct(), dbo.loan_const_op_loan_correct2())
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_RESTRUCTURE WHERE OP_ID = @op_id
	ELSE
	IF @op_type IN (dbo.loan_const_op_restructure_collateral(), dbo.loan_const_op_correct_collateral())
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_RESTRUCTURE_COLLATERAL WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_restructure_params()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_RESTRUCTURE_PARAMS WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_prolongation()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_PROLONG WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_penalty_stop()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_PENALTY_STOP WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_officer_change()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_OFFICER_CHANGE WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_penalty_forgive()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_PENALTY_FORGIVE WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_writedoff_forgive()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_WRITEDOFF_FORGIVE WHERE OP_ID = @op_id
	IF @op_type = dbo.loan_const_op_restructure_risks()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_RESTRUCTURE_RISKS WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_individual_risks()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_INDIVIDUAL_RISKS WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_change_dept()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_CHANGE_DEPT WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_close()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_CLOSE WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_writeoff()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_WRITEOFF WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_restructure_schedule()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_RESTRUCTURE_SCHEDULE WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_debt_defere()
		SELECT * FROM dbo.LOAN_VW_LOAN_OP_DEFERE_DEBT WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_guar_disburse()
		SELECT * FROM dbo.LOAN_VW_GUARANTEE_OP_DISBURSE WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.loan_const_op_guar_payment()
		SELECT * FROM dbo.LOAN_VW_GUARANTEE_OP_PAYMENT WHERE OP_ID = @op_id
	ELSE
	IF @op_type IN (dbo.loan_const_op_guar_inc(), dbo.loan_const_op_guar_dec())
		SELECT * FROM dbo.LOAN_VW_GUARANTEE_OP_INC WHERE OP_ID = @op_id	
	ELSE
	IF @op_type = dbo.loan_const_op_guar_close()
		SELECT * FROM dbo.LOAN_VW_GUARANTEE_OP_CLOSE WHERE OP_ID = @op_id
GO
