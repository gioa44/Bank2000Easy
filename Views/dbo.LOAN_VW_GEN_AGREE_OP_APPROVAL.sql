SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_GEN_AGREE_OP_APPROVAL]
AS
SELECT
		OP_ID,
		CREDIT_LINE_ID,
		OP_DATA.value('(row/@STATE)[1]', 'tinyint') AS STATE,
		OP_DATA.value('(row/@START_DATE)[1]', 'smalldatetime') AS START_DATE,
		OP_DATA.value('(row/@PERIOD)[1]', 'int') AS PERIOD,
		OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime') AS END_DATE
	FROM dbo.LOAN_GEN_AGREE_OPS
	WHERE OP_TYPE = dbo.loan_const_gen_agree_op_approval()
GO
