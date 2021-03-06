SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_MARK2DEFAULT_CHANGE_INTRATE_SCHEMA]
AS
	SELECT
		OP_ID,
		DEPO_ID,			 
		OP_DATA.value('(row/@ARCHIVE_DEPOSIT)[1]', 'bit') AS ARCHIVE_DEPOSIT,
		OP_DATA.value('(row/@PREV_DEPO_FORMULA)[1]', 'varchar(255)') AS PREV_DEPO_FORMULA,
		OP_DATA.value('(row/@PREV_ACP_FORMULA)[1]', 'varchar(255)') AS PREV_ACP_FORMULA,

		OP_DATA.value('(row/@PREV_INTRATE)[1]', 'money') AS PREV_INTRATE,
		OP_DATA.value('(row/@PREV_REAL_INTRATE)[1]', 'money') AS PREV_REAL_INTRATE,
		OP_DATA.value('(row/@PREV_INTRATE_SCHEMA)[1]', 'int') AS PREV_INTRATE_SCHEMA,

		OP_DATA.value('(row/@NEW_INTRATE)[1]', 'money') AS NEW_INTRATE,
		OP_DATA.value('(row/@NEW_INTRATE_SCHEMA)[1]', 'int') AS NEW_INTRATE_SCHEMA,
		OP_DATA.value('(row/@INTITIAL_AMOUNT)[1]', 'money') AS INTITIAL_AMOUNT
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = 62 /*dbo.depo_fn_const_op_mark2default_change_intrate_schema()*/
GO
