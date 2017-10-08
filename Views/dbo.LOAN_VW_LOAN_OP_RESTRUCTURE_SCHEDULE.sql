SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_RESTRUCTURE_SCHEDULE]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		ISNULL(OP_DATA.value('(row/@SCHEDULE_RECALC_TYPE)[1]', 'tinyint'), $0.00) AS SCHEDULE_RECALC_TYPE,
		ISNULL(OP_DATA.value('(row/@BALANCE)[1]', 'money'), $0.00) AS BALANCE,
		ISNULL(OP_DATA.value('(row/@PERIOD)[1]', 'int'), 0) AS PERIOD,
		ISNULL(OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime'), 0) AS END_DATE,
		ISNULL(OP_DATA.value('(row/@INTEREST)[1]', 'money'), $0.00) AS INTEREST,
		ISNULL(OP_DATA.value('(row/@NU_INTEREST)[1]', 'money'), $0.00) AS NU_INTEREST,
		ISNULL(OP_DATA.value('(row/@SCHEDULE_AMOUNT)[1]', 'money'), $0.00) AS SCHEDULE_AMOUNT,
		ISNULL(OP_DATA.value('(row/@PMT)[1]', 'money'), $0.00) AS PMT,
		ISNULL(OP_DATA.value('(row/@LEAVE_FIRST_PAYM_DATE)[1]', 'bit'), 0) AS LEAVE_FIRST_PAYM_DATE
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_restructure_schedule()
GO
