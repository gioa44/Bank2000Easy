SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_CHANGE_OFFICER]
AS
	SELECT
		OP_ID,
		DEPO_ID,		
		OP_DATA.value('(row/@OLD_RESPONSIBLE_USER_ID)[1]', 'int') AS OLD_RESPONSIBLE_USER_ID,
		OP_DATA.value('(row/@NEW_RESPONSIBLE_USER_ID)[1]', 'int') AS NEW_RESPONSIBLE_USER_ID
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_change_officer()
GO
