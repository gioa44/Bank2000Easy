SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_PAYMENT_WRITEDOFF]
AS
SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@WRITEOFF_PRINCIPAL)[1]', 'money') AS WRITEOFF_PRINCIPAL,
		OP_DATA.value('(row/@WRITEOFF_PRINCIPAL_ORG)[1]', 'money') AS WRITEOFF_PRINCIPAL_ORG,
		OP_DATA.value('(row/@WRITEOFF_PRINCIPAL_PENALTY)[1]', 'money') AS WRITEOFF_PRINCIPAL_PENALTY,
		OP_DATA.value('(row/@WRITEOFF_PRINCIPAL_PENALTY_ORG)[1]', 'money') AS WRITEOFF_PRINCIPAL_PENALTY_ORG,
		OP_DATA.value('(row/@WRITEOFF_PERCENT)[1]', 'money') AS WRITEOFF_PERCENT,
		OP_DATA.value('(row/@WRITEOFF_PERCENT_ORG)[1]', 'money') AS WRITEOFF_PERCENT_ORG,
		OP_DATA.value('(row/@WRITEOFF_PERCENT_PENALTY)[1]', 'money') AS WRITEOFF_PERCENT_PENALTY,
		OP_DATA.value('(row/@WRITEOFF_PERCENT_PENALTY_ORG)[1]', 'money') AS WRITEOFF_PERCENT_PENALTY_ORG,
		OP_DATA.value('(row/@WRITEOFF_PENALTY)[1]', 'money') AS WRITEOFF_PENALTY,
		OP_DATA.value('(row/@WRITEOFF_PENALTY_ORG)[1]', 'money') AS WRITEOFF_PENALTY_ORG
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_payment_writedoff()
GO
