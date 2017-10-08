SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_RESTRUCTURE_RISKS]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		ISNULL(OP_DATA.value('(row/@CATEGORY_1)[1]', 'money'), $0.00) AS CATEGORY_1,
		ISNULL(OP_DATA.value('(row/@CATEGORY_2)[1]', 'money'), $0.00) AS CATEGORY_2,
		ISNULL(OP_DATA.value('(row/@CATEGORY_3)[1]', 'money'), $0.00) AS CATEGORY_3,
		ISNULL(OP_DATA.value('(row/@CATEGORY_4)[1]', 'money'), $0.00) AS CATEGORY_4,
		ISNULL(OP_DATA.value('(row/@CATEGORY_5)[1]', 'money'), $0.00) AS CATEGORY_5,

		ISNULL(OP_DATA.value('(row/@NEW_CATEGORY_1)[1]', 'money'), $0.00) AS NEW_CATEGORY_1,
		ISNULL(OP_DATA.value('(row/@NEW_CATEGORY_2)[1]', 'money'), $0.00) AS NEW_CATEGORY_2,
		ISNULL(OP_DATA.value('(row/@NEW_CATEGORY_3)[1]', 'money'), $0.00) AS NEW_CATEGORY_3,
		ISNULL(OP_DATA.value('(row/@NEW_CATEGORY_4)[1]', 'money'), $0.00) AS NEW_CATEGORY_4,
		ISNULL(OP_DATA.value('(row/@NEW_CATEGORY_5)[1]', 'money'), $0.00) AS NEW_CATEGORY_5,

		ISNULL(OP_DATA.value('(row/@MOVE_CATEGORY_1)[1]', 'int'), $0.00) AS MOVE_CATEGORY_1,
		ISNULL(OP_DATA.value('(row/@MOVE_CATEGORY_2)[1]', 'int'), $0.00) AS MOVE_CATEGORY_2,
		ISNULL(OP_DATA.value('(row/@MOVE_CATEGORY_3)[1]', 'int'), $0.00) AS MOVE_CATEGORY_3,
		ISNULL(OP_DATA.value('(row/@MOVE_CATEGORY_4)[1]', 'int'), $0.00) AS MOVE_CATEGORY_4,
		ISNULL(OP_DATA.value('(row/@MOVE_CATEGORY_5)[1]', 'int'), $0.00) AS MOVE_CATEGORY_5,
	
		ISNULL(OP_DATA.value('(row/@NON_AUTO_CALC)[1]', 'bit'), 0) AS NON_AUTO_CALC
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_restructure_risks()
GO
