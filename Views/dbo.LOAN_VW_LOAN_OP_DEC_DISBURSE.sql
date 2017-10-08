SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_DEC_DISBURSE]
AS
SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@LOAN_AMOUNT)[1]', 'money') AS LOAN_AMOUNT,
		OP_DATA.value('(row/@LOAN_NU_AMOUNT)[1]', 'money') AS LOAN_NU_AMOUNT,
		OP_DATA.value('(row/@PRINCIPAL)[1]', 'money') AS PRINCIPAL,
		OP_DATA.value('(row/@LOAN_NU_AMOUNT_DELTA)[1]', 'money') AS LOAN_NU_AMOUNT_DELTA,
		OP_DATA.value('(row/@DEC_AMOUNT)[1]', 'money') AS DEC_AMOUNT
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_dec_disburse()
GO
