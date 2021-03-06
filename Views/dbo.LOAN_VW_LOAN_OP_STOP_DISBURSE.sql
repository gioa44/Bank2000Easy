SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_STOP_DISBURSE]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@LOAN_AMOUNT)[1]', 'money') AS LOAN_AMOUNT,
		OP_DATA.value('(row/@LOAN_NU_AMOUNT)[1]', 'money') AS LOAN_NU_AMOUNT,
		OP_DATA.value('(row/@NU_INTEREST)[1]', 'money') AS NU_INTEREST
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_stop_disburse()
GO
