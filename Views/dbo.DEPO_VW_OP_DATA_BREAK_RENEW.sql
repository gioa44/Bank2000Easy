SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_BREAK_RENEW]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_DATA.value('(row/@PREV_PROLONGABLE)[1]', 'bit') AS PREV_PROLONGABLE,
		OP_DATA.value('(row/@PREV_RENEWABLE)[1]', 'bit') AS PREV_RENEWABLE,
		OP_DATA.value('(row/@PROLONGABLE)[1]', 'bit') AS PROLONGABLE,
		OP_DATA.value('(row/@RENEWABLE)[1]', 'bit') AS RENEWABLE
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_break_renew()
GO
