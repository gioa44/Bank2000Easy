SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_GUARANTEE_OP_PAYMENT]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(//@PENALTY)[1]', 'money') AS PENALTY,
		OP_DATA.value('(//@PENALTY_ORG)[1]', 'money') AS PENALTY_ORG,
		OP_DATA.value('(//@OVERDUE_PERCENT)[1]', 'money') AS OVERDUE_PERCENT,
		OP_DATA.value('(//@OVERDUE_PERCENT_ORG)[1]', 'money') AS OVERDUE_PERCENT_ORG,
		OP_DATA.value('(//@INTEREST)[1]', 'money') AS INTEREST,
		OP_DATA.value('(//@INTEREST_ORG)[1]', 'money') AS INTEREST_ORG,
		OP_DATA.value('(//@STATE)[1]', 'int') AS [STATE]
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_guar_payment()
GO
