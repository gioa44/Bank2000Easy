SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_CONVERT]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_DATA.value('(row/@ARCHIVE_DEPOSIT)[1]', 'bit') AS ARCHIVE_DEPOSIT,
		OP_DATA.value('(row/@DEPO_REALIZE_ACC_ID)[1]', 'int') AS DEPO_REALIZE_ACC_ID,
		OP_DATA.value('(row/@INTEREST_REALIZE_ACC_ID)[1]', 'int') AS INTEREST_REALIZE_ACC_ID,
		OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime') AS END_DATE,
		OP_DATA.value('(row/@DATE_TYPE)[1]', 'tinyint') AS DATE_TYPE,
		OP_DATA.value('(row/@PERIOD)[1]', 'int') AS PERIOD,
		OP_DATA.value('(row/@INTRATE)[1]', 'money') AS INTRATE,
		OP_DATA.value('(row/@INTEREST_REALIZE_TYPE)[1]', 'int') AS INTEREST_REALIZE_TYPE
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_convert()
GO
