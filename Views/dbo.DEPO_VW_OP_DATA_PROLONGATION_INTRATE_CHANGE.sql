SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_PROLONGATION_INTRATE_CHANGE]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_DATA.value('(row/@ARCHIVE_DEPOSIT)[1]', 'bit') AS ARCHIVE_DEPOSIT,		
		OP_DATA.value('(row/@PREV_END_DATE)[1]', 'smalldatetime') AS PREV_END_DATE,
		OP_DATA.value('(row/@NEW_END_DATE)[1]', 'smalldatetime') AS NEW_END_DATE,
		OP_DATA.value('(row/@PREV_INTRATE)[1]', 'money') AS PREV_INTRATE,
		OP_DATA.value('(row/@NEW_INTRATE)[1]', 'money') AS NEW_INTRATE,
		OP_DATA.value('(row/@CHANGE_INTRATE)[1]', 'bit') AS CHANGE_INTRATE,
		OP_DATA.value('(row/@RECALCULATE_SCHEDULE)[1]', 'bit') AS RECALCULATE_SCHEDULE
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = 122 /*dbo.depo_fn_const_op_prolongation_intrate_change()*/

GO
