SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_PROLONG]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@START_DATE)[1]', 'smalldatetime') AS START_DATE,
		OP_DATA.value('(row/@PERIOD)[1]', 'int') AS PERIOD,
		OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime') AS END_DATE,
		OP_DATA.value('(row/@NEW_PERIOD)[1]', 'int') AS NEW_PERIOD,
		OP_DATA.value('(row/@NEW_END_DATE)[1]', 'smalldatetime') AS NEW_END_DATE,
		OP_DATA.value('(row/@PROLONGED_PERIOD)[1]', 'int') AS PROLONGED_PERIOD,
		OP_DATA.value('(row/@PMT)[1]', 'money') AS PMT,
		ISNULL(OP_DATA.value('(row/@LEAVE_FIRST_PAYM_DATE)[1]', 'bit'), 0) AS LEAVE_FIRST_PAYM_DATE
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_prolongation()
GO
