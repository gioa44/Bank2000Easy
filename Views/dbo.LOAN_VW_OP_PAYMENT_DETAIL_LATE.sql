SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_OP_PAYMENT_DETAIL_LATE]
AS
SELECT
		l.OP_ID,
		l.LOAN_ID,
		T.c.value('./@LATE_DATE', 'smalldatetime') AS LATE_DATE,
		T.c.value('./@LATE_OP_ID', 'int') AS LATE_OP_ID,
		T.c.value('./@LATE_PRINCIPAL', 'money') AS LATE_PRINCIPAL,
		T.c.value('./@LATE_PERCENT', 'money') AS LATE_PERCENT
	FROM dbo.LOAN_OPS l
		CROSS APPLY l.OP_EXT_XML_1.nodes('/root/row') AS  T(c)
	WHERE OP_TYPE IN (dbo.loan_const_op_payment(), dbo.loan_const_op_writeoff())
GO
