SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_PAYMENT_DETAILS]
AS
SELECT
		OP_ID,
		LOAN_ID,
		ISNULL(OP_DETAILS.value('(row/@OVERDUE_PERCENT_PENALTY)[1]', 'money'), $0.00) AS OVERDUE_PERCENT_PENALTY,
		ISNULL(OP_DETAILS.value('(row/@OVERDUE_PRINCIPAL_PENALTY)[1]', 'money'), $0.00) AS OVERDUE_PRINCIPAL_PENALTY,
		ISNULL(OP_DETAILS.value('(row/@OVERDUE_PERCENT)[1]', 'money'), $0.00) AS OVERDUE_PERCENT,
		ISNULL(OP_DETAILS.value('(row/@LATE_PERCENT)[1]', 'money'), $0.00) AS LATE_PERCENT,
		ISNULL(OP_DETAILS.value('(row/@OVERDUE_PRINCIPAL)[1]', 'money'), $0.00) AS OVERDUE_PRINCIPAL,
		ISNULL(OP_DETAILS.value('(row/@LATE_PRINCIPAL)[1]', 'money'), $0.00) AS LATE_PRINCIPAL,
		ISNULL(OP_DETAILS.value('(row/@OVERDUE_PRINCIPAL_INTEREST)[1]', 'money'), $0.00) AS OVERDUE_PRINCIPAL_INTEREST,
		ISNULL(OP_DETAILS.value('(row/@INTEREST)[1]', 'money'), $0.00) AS INTEREST,
		ISNULL(OP_DETAILS.value('(row/@NU_INTEREST)[1]', 'money'), $0.00) AS NU_INTEREST,
		ISNULL(OP_DETAILS.value('(row/@PREPAYMENT)[1]', 'money'), $0.00) AS PREPAYMENT,
		ISNULL(OP_DETAILS.value('(row/@PREPAYMENT_PENALTY)[1]', 'money'), $0.00) AS PREPAYMENT_PENALTY,
		ISNULL(OP_DETAILS.value('(row/@PRINCIPAL)[1]', 'money'), $0.00) AS PRINCIPAL,
		ISNULL(OP_DETAILS.value('(row/@RATE_DIFF)[1]', 'money'), $0.00) AS RATE_DIFF,
		ISNULL(OP_DETAILS.value('(row/@INSURANCE)[1]', 'money'), $0.00) AS INSURANCE,
		ISNULL(OP_DETAILS.value('(row/@OVERDUE_INSURANCE)[1]', 'money'), $0.00) AS OVERDUE_INSURANCE,
		ISNULL(OP_DETAILS.value('(row/@SERVICE_FEE)[1]', 'money'), $0.00) AS SERVICE_FEE,
		ISNULL(OP_DETAILS.value('(row/@OVERDUE_SERVICE_FEE)[1]', 'money'), $0.00) AS OVERDUE_SERVICE_FEE,
		ISNULL(OP_DETAILS.value('(row/@DEFERED_INTEREST)[1]', 'money'), $0.00) AS DEFERED_INTEREST,
		ISNULL(OP_DETAILS.value('(row/@DEFERED_OVERDUE_INTEREST)[1]', 'money'), $0.00) AS DEFERED_OVERDUE_INTEREST,
		ISNULL(OP_DETAILS.value('(row/@DEFERED_PENALTY)[1]', 'money'), $0.00) AS DEFERED_PENALTY,
		ISNULL(OP_DETAILS.value('(row/@DEFERED_FINE)[1]', 'money'), $0.00) AS DEFERED_FINE,
		ISNULL(OP_DETAILS.value('(row/@STATE)[1]', 'tinyint'), 0) AS [STATE]
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_payment()
GO
