SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_BLOCK_AMOUNT]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_DATA.value('(row/@DEPO_ACC_ID)[1]', 'int') AS DEPO_ACC_ID,
		OP_DATA.value('(row/@FREE_AMOUNT)[1]', 'money') AS FREE_AMOUNT,
		OP_DATA.value('(row/@BLOCKED_BY_PRODUCT)[1]', 'varchar(20)') AS BLOCKED_BY_PRODUCT,
		OP_DATA.value('(row/@BLOCK_REASON)[1]', 'varchar(255)') AS BLOCK_REASON,
		OP_DATA.value('(row/@BLOCK_ID)[1]', 'int') AS BLOCK_ID
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_block_amount()
GO
