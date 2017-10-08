SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_GUARANTEE_OP_INC]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(//@AMOUNT_ORG)[1]', 'money') AS AMOUNT_ORG,
		OP_DATA.value('(//@AMOUNT_ADD)[1]', 'money') AS AMOUNT_ADD,
		OP_DATA.value('(//@AMOUNT_NEW)[1]', 'money') AS AMOUNT_NEW,
		ISNULL(OP_DATA.value('(//@LEAVE_FIRST_PAYM_DATE)[1]', 'bit'), 0) AS LEAVE_FIRST_PAYM_DATE
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE IN (dbo.loan_const_op_guar_inc(), dbo.loan_const_op_guar_dec())
GO
