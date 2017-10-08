SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_PAYMENT]
AS
SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@PENALTY)[1]', 'money') AS PENALTY,
		OP_DATA.value('(row/@PENALTY_ORG)[1]', 'money') AS PENALTY_ORG,
		OP_DATA.value('(row/@OVERDUE_PERCENT)[1]', 'money') AS OVERDUE_PERCENT,
		OP_DATA.value('(row/@OVERDUE_PERCENT_ORG)[1]', 'money') AS OVERDUE_PERCENT_ORG,
		OP_DATA.value('(row/@OVERDUE_PRINCIPAL)[1]', 'money') AS OVERDUE_PRINCIPAL,
		OP_DATA.value('(row/@OVERDUE_PRINCIPAL_ORG)[1]', 'money') AS OVERDUE_PRINCIPAL_ORG,
		OP_DATA.value('(row/@INTEREST)[1]', 'money') AS INTEREST,
		OP_DATA.value('(row/@INTEREST_ORG)[1]', 'money') AS INTEREST_ORG,
		OP_DATA.value('(row/@PRINCIPAL)[1]', 'money') AS PRINCIPAL,
		OP_DATA.value('(row/@PRINCIPAL_ORG)[1]', 'money') AS PRINCIPAL_ORG,
		OP_DATA.value('(row/@PREPAYMENT_PENALTY)[1]', 'money') AS PREPAYMENT_PENALTY,
		OP_DATA.value('(row/@MAX_DEBT)[1]', 'money') AS MAX_DEBT,
		OP_DATA.value('(row/@MIN_DEBT)[1]', 'money') AS MIN_DEBT,
		OP_DATA.value('(row/@NO_CHARGE_DEBT)[1]', 'money') AS NO_CHARGE_DEBT,
		OP_DATA.value('(row/@RATE_DIFF)[1]', 'money') AS RATE_DIFF,
		OP_DATA.value('(row/@INSURANCE)[1]', 'money') AS INSURANCE,
		OP_DATA.value('(row/@INSURANCE_ORG)[1]', 'money') AS INSURANCE_ORG,
		OP_DATA.value('(row/@SERVICE_FEE)[1]', 'money') AS SERVICE_FEE,
		OP_DATA.value('(row/@SERVICE_FEE_ORG)[1]', 'money') AS SERVICE_FEE_ORG,
		OP_DATA.value('(row/@DEFERED_DEBT)[1]', 'money') AS DEFERED_DEBT,
		OP_DATA.value('(row/@DEFERED_DEBT_ORG)[1]', 'money') AS DEFERED_DEBT_ORG,
		OP_DATA.value('(row/@DEFERED_DEBT_NEXT)[1]', 'money') AS DEFERED_DEBT_NEXT,
		OP_DATA.value('(row/@DEFERED_DEBT_NEXT_ORG)[1]', 'money') AS DEFERED_DEBT_NEXT_ORG
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_payment()
GO
