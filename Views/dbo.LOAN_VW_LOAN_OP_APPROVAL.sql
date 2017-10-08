SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_APPROVAL]
AS
	SELECT
		OP_ID,
		LOAN_ID,
		OP_DATA.value('(row/@STATE)[1]', 'int') AS STATE,	
		OP_DATA.value('(row/@AGREEMENT_NO)[1]', 'varchar(100)') AS AGREEMENT_NO,
		OP_DATA.value('(row/@START_DATE)[1]', 'smalldatetime') AS START_DATE,
		OP_DATA.value('(row/@PERIOD)[1]', 'int') AS PERIOD,
		OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime') AS END_DATE
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE = dbo.loan_const_op_approval()
GO
