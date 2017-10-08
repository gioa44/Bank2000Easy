SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_GUARANTEE_OP_CLOSE]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(//@CLOSE_REASON)[1]', 'int') AS CLOSE_REASON,
		OP_DATA.value('(//@ACC_ID)[1]', 'int') AS ACC_ID,
		OP_DATA.value('(//@ACC_ISO)[1]', 'TISO') AS ACC_ISO,
		OP_DATA.value('(//@DOC_REC_ID)[1]', 'int') AS DOC_REC_ID,
		OP_DATA.value('(//@DOC_DATE)[1]', 'smalldatetime') AS DOC_DATE,
		OP_DATA.value('(row/@CLOSE_COLLAT)[1]', 'bit') AS CLOSE_COLLAT,
		OP_DATA.value('(row/@COLLATERAL_LIST)[1]', 'varchar(1000)') AS COLLATERAL_LIST
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_guar_close()
GO
