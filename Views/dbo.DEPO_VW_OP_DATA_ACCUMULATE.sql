SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_ACCUMULATE]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_DATA.value('(row/@CLIENT_TYPE)[1]', 'tinyint') AS CLIENT_TYPE,
		OP_DATA.value('(row/@DEPO_FILL_ACC_ID)[1]', 'int') AS DEPO_FILL_ACC_ID,
		OP_DATA.value('(row/@DATE_TYPE)[1]', 'tinyint') AS DATE_TYPE,
		OP_DATA.value('(row/@DEPO_INTRATE)[1]', 'money') AS DEPO_INTRATE,
		OP_DATA.value('(row/@REAL_INTRATE)[1]', 'decimal(32,12)') AS REAL_INTRATE,
		OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime') AS END_DATE,
		OP_DATA.value('(row/@PERIOD)[1]', 'int') AS PERIOD,
		OP_DATA.value('(row/@INTRATE)[1]', 'money') AS INTRATE,
		OP_DATA.value('(row/@DEPO_AMOUNT)[1]', 'money') AS DEPO_AMOUNT,
		OP_DATA.value('(row/@CHANGE_FORMULA)[1]', 'bit') AS CHANGE_FORMULA,
		OP_DATA.value('(row/@PREV_FORMULA)[1]', 'varchar(255)') AS PREV_FORMULA

	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_accumulate()
GO
