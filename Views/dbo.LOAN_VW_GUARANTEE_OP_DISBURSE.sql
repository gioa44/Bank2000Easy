SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_GUARANTEE_OP_DISBURSE]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@GUARANTEE_AMOUNT)[1]', 'money') AS GUARANTEE_AMOUNT,
		OP_DATA.value('(row/@RISK_TYPE)[1]', 'int') AS RISK_TYPE,
		OP_DATA.value('(row/@LPI_INTERVAL)[1]', 'money') AS LPI_INTERVAL,
		OP_DATA.value('(row/@PAYMENT_DAY)[1]', 'int') AS PAYMENT_DAY,
		OP_DATA.value('(row/@NEW_PAYMENT_DAY)[1]', 'int') AS NEW_PAYMENT_DAY,
		OP_DATA.value('(row/@START_DATE)[1]', 'smalldatetime') AS START_DATE,
		OP_DATA.value('(row/@PERIOD)[1]', 'int') AS PERIOD,
		OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime') AS END_DATE,
		OP_DATA.value('(row/@NEW_START_DATE)[1]', 'smalldatetime') AS NEW_START_DATE,
		OP_DATA.value('(row/@NEW_PERIOD)[1]', 'int') AS NEW_PERIOD,
		OP_DATA.value('(row/@NEW_END_DATE)[1]', 'smalldatetime') AS NEW_END_DATE,
		OP_DATA.value('(row/@LEVEL_ID)[1]', 'int') AS LEVEL_ID,
		OP_DATA.value('(row/@REMAINING_FEE)[1]', 'money') AS REMAINING_FEE
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_guar_disburse()
GO
