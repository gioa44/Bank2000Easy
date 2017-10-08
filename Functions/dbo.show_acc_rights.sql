SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[show_acc_rights](@group_id int) 
RETURNS TABLE
AS 
	RETURN

	SELECT AST.SET_ID, ASS.DESCRIP AS SET_NAME, AST.RIGHT_NAME, CONVERT(bit, 1) AS HAS_RIGHT

	FROM dbo.ACC_SET_RIGHTS AST
		INNER JOIN dbo.ACC_SETS ASS ON ASS.SET_ID = AST.SET_ID
	WHERE AST.GROUP_ID = @group_id

	UNION ALL

	SELECT ASS.SET_ID, ASS.DESCRIP AS SET_NAME, ASRN.RIGHT_NAME, CONVERT(bit, 0) AS HAS_RIGHT
	FROM dbo.ACC_SETS ASS 
		CROSS JOIN dbo.ACC_SET_RIGHT_NAMES ASRN
	WHERE NOT EXISTS(SELECT * FROM dbo.ACC_SET_RIGHTS A2 WHERE A2.GROUP_ID = @group_id AND A2.SET_ID = ASS.SET_ID AND A2.RIGHT_NAME = ASRN.RIGHT_NAME)
GO