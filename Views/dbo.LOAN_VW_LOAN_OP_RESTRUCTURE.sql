SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_RESTRUCTURE]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		ISNULL(OP_DATA.value('(row/@INTRATE)[1]', 'money'), $0.00) AS INTRATE,
		ISNULL(OP_DATA.value('(row/@PENALTY_INTRATE)[1]', 'money'), $0.00) AS PENALTY_INTRATE,
		ISNULL(OP_DATA.value('(row/@NOTUSED_INTRATE)[1]', 'money'), $0.00) AS NOTUSED_INTRATE,
		ISNULL(OP_DATA.value('(row/@PREPAYMENT_INTRATE)[1]', 'money'), $0.00) AS PREPAYMENT_INTRATE,
		ISNULL(OP_DATA.value('(row/@PAYMENT_DAY)[1]', 'int'), 0) AS PAYMENT_DAY,
		ISNULL(OP_DATA.value('(row/@PAYMENT_INTERVAL_TYPE)[1]', 'int'), 0) AS PAYMENT_INTERVAL_TYPE,
		ISNULL(OP_DATA.value('(row/@SCHEDULE_TYPE)[1]', 'int'), 0) AS SCHEDULE_TYPE,
		ISNULL(OP_DATA.value('(row/@GRACE_TYPE)[1]', 'bit'), 0) AS GRACE_TYPE,
		ISNULL(OP_DATA.value('(row/@GRACE_STEPS)[1]', 'int'), 0) AS GRACE_STEPS,

		ISNULL(OP_DATA.value('(row/@OLD_INTRATE)[1]', 'money'), $0.00) AS OLD_INTRATE,
		ISNULL(OP_DATA.value('(row/@OLD_PENALTY_INTRATE)[1]', 'money'), $0.00) AS OLD_PENALTY_INTRATE,
		ISNULL(OP_DATA.value('(row/@OLD_NOTUSED_INTRATE)[1]', 'money'), $0.00) AS OLD_NOTUSED_INTRATE,
		ISNULL(OP_DATA.value('(row/@OLD_PREPAYMENT_INTRATE)[1]', 'money'), $0.00) AS OLD_PREPAYMENT_INTRATE,
		ISNULL(OP_DATA.value('(row/@OLD_PAYMENT_DAY)[1]', 'int'), 0) AS OLD_PAYMENT_DAY,
		ISNULL(OP_DATA.value('(row/@OLD_PAYMENT_INTERVAL_TYPE)[1]', 'int'), 0) AS OLD_PAYMENT_INTERVAL_TYPE,
		ISNULL(OP_DATA.value('(row/@OLD_SCHEDULE_TYPE)[1]', 'int'), 0) AS OLD_SCHEDULE_TYPE,
		ISNULL(OP_DATA.value('(row/@OLD_GRACE_TYPE)[1]', 'bit'), 0) AS OLD_GRACE_TYPE,
		ISNULL(OP_DATA.value('(row/@OLD_GRACE_STEPS)[1]', 'int'), 0) AS OLD_GRACE_STEPS,

		ISNULL(OP_DATA.value('(row/@BALANCE)[1]', 'money'), $0.00) AS BALANCE,
		ISNULL(OP_DATA.value('(row/@PERIOD)[1]', 'int'), 0) AS PERIOD,
		ISNULL(OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime'), 0) AS END_DATE,
		ISNULL(OP_DATA.value('(row/@LEAVE_FIRST_PAYM_DATE)[1]', 'bit'), 0) AS LEAVE_FIRST_PAYM_DATE,

		ISNULL(OP_DATA.value('(row/@GRACE_FINISH_DATE)[1]', 'smalldatetime'), 0) AS GRACE_FINISH_DATE,
		ISNULL(OP_DATA.value('(row/@PMT)[1]', 'money'), 0) AS PMT
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE IN (dbo.loan_const_op_restructure(), dbo.loan_const_op_loan_correct(), dbo.loan_const_op_loan_correct2())

GO
