SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_OFFICER_CHANGE]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@OLD_RESPONSIBLE_USER_ID)[1]', 'int') AS OLD_RESPONSIBLE_USER_ID,
		OP_DATA.value('(row/@NEW_RESPONSIBLE_USER_ID)[1]', 'int') AS NEW_RESPONSIBLE_USER_ID
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_officer_change()
GO
