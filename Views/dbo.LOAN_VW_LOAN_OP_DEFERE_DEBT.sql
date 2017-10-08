SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_DEFERE_DEBT]
AS
	SELECT
		OP_ID,
		LOAN_ID,

		ISNULL(OP_DATA.value('(row/@DEFERE_FLAGS)[1]', 'int'), $0.00) AS DEFERE_FLAGS,

		ISNULL(OP_DATA.value('(row/@INTEREST_OLD)[1]', 'money'), $0.00) AS INTEREST_OLD,
		ISNULL(OP_DATA.value('(row/@OVERDUE_INTEREST_OLD)[1]', 'money'), $0.00) AS OVERDUE_INTEREST_OLD,
		ISNULL(OP_DATA.value('(row/@PENALTY_OLD)[1]', 'money'), $0.00) AS PENALTY_OLD,
		ISNULL(OP_DATA.value('(row/@FINE_OLD)[1]', 'money'), $0.00) AS FINE_OLD,
		ISNULL(OP_DATA.value('(row/@DEBT_OLD)[1]', 'money'), $0.00) AS DEBT_OLD,

		ISNULL(OP_DATA.value('(row/@DEF_INTEREST_OLD)[1]', 'money'), $0.00) AS DEF_INTEREST_OLD,
		ISNULL(OP_DATA.value('(row/@DEF_OVERDUE_INTEREST_OLD)[1]', 'money'), $0.00) AS DEF_OVERDUE_INTEREST_OLD,
		ISNULL(OP_DATA.value('(row/@DEF_PENALTY_OLD)[1]', 'money'), $0.00) AS DEF_PENALTY_OLD,
		ISNULL(OP_DATA.value('(row/@DEF_FINE_OLD)[1]', 'money'), $0.00) AS DEF_FINE_OLD,
		ISNULL(OP_DATA.value('(row/@DEF_DEBT_OLD)[1]', 'money'), $0.00) AS DEF_DEBT_OLD,

		ISNULL(OP_DATA.value('(row/@DEF_INTEREST)[1]', 'money'), $0.00) AS DEF_INTEREST,
		ISNULL(OP_DATA.value('(row/@DEF_OVERDUE_INTEREST)[1]', 'money'), $0.00) AS DEF_OVERDUE_INTEREST,
		ISNULL(OP_DATA.value('(row/@DEF_PENALTY)[1]', 'money'), $0.00) AS DEF_PENALTY,
		ISNULL(OP_DATA.value('(row/@DEF_FINE)[1]', 'money'), $0.00) AS DEF_FINE,
		ISNULL(OP_DATA.value('(row/@DEF_DEBT)[1]', 'money'), $0.00) AS DEF_DEBT
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_debt_defere()
GO
