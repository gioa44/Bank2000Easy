SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_DISBURSE_TRANSH]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@LEVEL_ID)[1]', 'int') AS LEVEL_ID,
		OP_DATA.value('(row/@LOAN_AMOUNT)[1]', 'money') AS LOAN_AMOUNT,
		OP_DATA.value('(row/@LOAN_NU_PRINCIPAL)[1]', 'money') AS LOAN_NU_PRINCIPAL,
		OP_DATA.value('(row/@DISBURSE_TYPE)[1]', 'int') AS DISBURSE_TYPE,
		OP_DATA.value('(row/@RISK_TYPE)[1]', 'int') AS RISK_TYPE,
		OP_DATA.value('(row/@INTEREST_CORRECTION)[1]', 'money') AS INTEREST_CORRECTION,
		OP_DATA.value('(row/@NU_INTEREST_CORRECTION)[1]', 'money') AS NU_INTEREST_CORRECTION,
		OP_DATA.value('(row/@PMT)[1]', 'money') AS PMT,
		ISNULL(OP_DATA.value('(row/@LEAVE_FIRST_PAYM_DATE)[1]', 'bit'), 0) AS LEAVE_FIRST_PAYM_DATE
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_disburse_transh()
GO
