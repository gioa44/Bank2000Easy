SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_LATE]
AS
SELECT
	OP_ID,
	LOAN_ID,
	ISNULL(OP_DATA.value('(row/@LATE_PERCENT)[1]', 'money'), $0.00) AS LATE_PERCENT,
	ISNULL(OP_DATA.value('(row/@LATE_PRINCIPAL)[1]', 'money'), $0.00) AS LATE_PRINCIPAL
FROM dbo.LOAN_OPS
WHERE OP_TYPE=dbo.loan_const_op_late()
GO
