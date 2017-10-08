SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[L_CLIENTS] AS
SELECT C.* , DP.ALIAS AS BRANCH_ALIAS, DP.ALIAS + ': ' + DP.DESCRIP AS BRANCH_NAME
FROM dbo.CLIENTS C (NOLOCK)
	LEFT JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = C.DEPT_NO
GO
