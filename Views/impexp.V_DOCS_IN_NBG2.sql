SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [impexp].[V_DOCS_IN_NBG2] AS
SELECT D.*, 
	A.DESCRIP AS ACCOUNT_NAME,
	A.ACC_TYPE, AT.DESCRIP + ' ' + ISNULL(AST.DESCRIP,'') AS ACC_DESCRIP,
	C.DESCRIP AS CLIENT_NAME,
	A.CLIENT_NO, C.TAX_INSP_CODE, C.PERSONAL_ID,
	DP.ALIAS AS BRANCH_ALIAS,
	PS.STATE AS PORTION_STATE
FROM impexp.DOCS_IN_NBG D
	LEFT JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = D.ACC_ID
	LEFT JOIN dbo.CLIENTS C (NOLOCK) ON C.CLIENT_NO = A.CLIENT_NO
	LEFT JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = A.DEPT_NO
	LEFT JOIN dbo.ACC_TYPES AT (NOLOCK) ON AT.ACC_TYPE = A.ACC_TYPE
	LEFT JOIN dbo.ACC_SUBTYPES AST (NOLOCK) ON AST.ACC_TYPE = A.ACC_TYPE AND AST.ACC_SUBTYPE = A.ACC_SUBTYPE
	INNER JOIN impexp.PORTIONS_IN_NBG PS ON PS.PORTION_DATE = D.PORTION_DATE AND PS.PORTION = D.PORTION
WHERE D.IS_AUTHORIZED = 1
GO
