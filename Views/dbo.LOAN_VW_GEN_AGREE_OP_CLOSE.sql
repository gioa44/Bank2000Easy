SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_GEN_AGREE_OP_CLOSE]
AS
SELECT
		OP_ID,
		CREDIT_LINE_ID,
		OP_DATA.value('(row/@STATE)[1]', 'tinyint') AS [STATE],
		OP_DATA.value('(row/@CLOSE_COLLAT)[1]', 'bit') AS CLOSE_COLLAT,
		OP_DATA.value('(row/@COLLATERAL_LIST)[1]', 'varchar(1000)') AS COLLATERAL_LIST
	FROM dbo.LOAN_GEN_AGREE_OPS
	WHERE OP_TYPE = dbo.loan_const_gen_agree_op_close()
GO
