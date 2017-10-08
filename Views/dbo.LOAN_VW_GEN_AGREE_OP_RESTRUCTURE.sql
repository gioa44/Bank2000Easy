SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_GEN_AGREE_OP_RESTRUCTURE]
AS
	SELECT
		OP_ID,
		CREDIT_LINE_ID,
		--OP_DATA.value('(row/@ENSURE_TYPE)[1]', 'int') AS ENSURE_TYPE,
		OP_DATA.value('(row/@ISO)[1]', 'char(3)') AS ISO,
		OP_DATA.value('(row/@OLD_ISO)[1]', 'char(3)') AS OLD_ISO,
		OP_DATA.value('(row/@AMOUNT)[1]', 'money') AS AMOUNT,
		OP_DATA.value('(row/@OLD_AMOUNT)[1]', 'money') AS OLD_AMOUNT,
		OP_DATA.value('(row/@PERIOD)[1]', 'int') AS PERIOD,
		OP_DATA.value('(row/@OLD_PERIOD)[1]', 'int') AS OLD_PERIOD
	FROM dbo.LOAN_GEN_AGREE_OPS
	WHERE OP_TYPE IN (dbo.loan_const_gen_agree_op_restructure(), dbo.loan_const_gen_agree_op_correct())
GO
