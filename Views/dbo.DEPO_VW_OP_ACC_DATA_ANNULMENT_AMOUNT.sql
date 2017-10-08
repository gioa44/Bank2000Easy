SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_ACC_DATA_ANNULMENT_AMOUNT]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_ACC_DATA.value('(row/@ACC_ARC_REC_ID)[1]', 'int') AS ACC_ARC_REC_ID,
		OP_ACC_DATA.value('(row/@SKIP_REALIZE)[1]', 'bit') AS SKIP_REALIZE,
		OP_ACC_DATA.value('(row/@ACCOUNT_REC_STATE)[1]', 'tinyint') AS ACCOUNT_REC_STATE,
		OP_ACC_DATA.value('(row/@ACCOUNT_DATE_CLOSE)[1]', 'smalldatetime') AS ACCOUNT_DATE_CLOSE
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_annulment_amount()
GO
