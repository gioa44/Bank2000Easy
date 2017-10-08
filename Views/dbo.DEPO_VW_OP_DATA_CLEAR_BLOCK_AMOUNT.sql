SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[DEPO_VW_OP_DATA_CLEAR_BLOCK_AMOUNT]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_DATA.value('(row/@BLOCK_ID)[1]', 'int') AS BLOCK_ID,
		OP_DATA.value('(row/@UNBLOCK_REASON)[1]', 'varchar(255)') AS UNBLOCK_REASON
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_clear_block_amount()
GO