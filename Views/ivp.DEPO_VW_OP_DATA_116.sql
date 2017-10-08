SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [ivp].[DEPO_VW_OP_DATA_116]
WITH SCHEMABINDING
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_DATA
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = 116 /*dbo.depo_fn_const_op_function_advance()*/
GO
CREATE UNIQUE CLUSTERED INDEX [IPV_IDX_DEPO_VW_OP_DATA_116] ON [ivp].[DEPO_VW_OP_DATA_116] ([OP_ID]) ON [PRIMARY]
GO
