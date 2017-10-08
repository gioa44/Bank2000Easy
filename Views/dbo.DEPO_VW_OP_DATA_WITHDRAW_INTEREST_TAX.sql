SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_WITHDRAW_INTEREST_TAX]
AS
	SELECT
		OP_ID,
		DEPO_ID,		
		OP_DATA.value('(row/@DEPO_REALIZE_ACC_ID)[1]', 'int') AS DEPO_REALIZE_ACC_ID,
		OP_DATA.value('(row/@DEPO_AMOUNT)[1]', 'money') AS DEPO_AMOUNT
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_withdraw_interest_tax()
GO
