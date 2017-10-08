SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_OP_PAYMENT_DETAIL_OVERDUE]
AS
SELECT
		l.OP_ID,
		l.LOAN_ID,
		T.c.value('./@OVERDUE_DATE', 'smalldatetime') AS OVERDUE_DATE,
		T.c.value('./@OVERDUE_OP_ID', 'int') AS OVERDUE_OP_ID,
		T.c.value('./@OVERDUE_PRINCIPAL', 'money') AS OVERDUE_PRINCIPAL,
		T.c.value('./@OVERDUE_PERCENT', 'money') AS OVERDUE_PERCENT
	FROM dbo.LOAN_OPS l
		CROSS APPLY l.OP_EXT_XML_2.nodes('/root/row') AS  T(c)
	WHERE OP_TYPE IN (dbo.loan_const_op_payment(), dbo.loan_const_op_writeoff(), dbo.loan_const_op_overdue_revert(), dbo.loan_const_op_guar_payment())
GO
