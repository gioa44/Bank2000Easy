SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_WITHDRAW_SCHEDULE]
AS
	SELECT
		OP_ID,
		DEPO_ID,		
		OP_DATA.value('(row/@DEPO_REALIZE_ACC_ID)[1]', 'int') AS DEPO_REALIZE_ACC_ID,
		OP_DATA.value('(row/@PREV_AMOUNT)[1]', 'money') AS PREV_AMOUNT,
		OP_DATA.value('(row/@DEPO_AMOUNT)[1]', 'money') AS DEPO_AMOUNT,
		OP_DATA.value('(row/@INTEREST)[1]', 'money') AS INTEREST
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_withdraw_schedule()
GO
