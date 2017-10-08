SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[L_DEPOS]
AS
SELECT V.*, DP.ALIAS AS BRANCH_ALIAS, DP.ALIAS + ': ' + DP.DESCRIP AS BRANCH_NAME, U.USER_FULL_NAME,
	C.DESCRIP AS CDESCRIP, C.DESCRIP_LAT AS CDESCRIP_LAT, 
	C.PERSONAL_ID, C.TAX_INSP_CODE, C.IS_RESIDENT, C.IS_JURIDICAL, C.IS_INSIDER, C.IS_BUDJET, C.CLIENT_TYPE,
	DT.DESCRIP AS TDESCRIP, DT.DESCRIP_LAT AS TDESCRIP_LAT,
	V.START_DATE AS ACTIVE_DATE
FROM dbo.V_DEPOS AS V 
	INNER JOIN dbo.DEPO_TYPES DT (NOLOCK) ON V.DEPO_TYPE_ID = DT.DEPO_TYPE_ID
	INNER JOIN dbo.USERS U (NOLOCK) ON V.OFFICER_ID = U.USER_ID
	INNER JOIN dbo.CLIENTS C (NOLOCK) ON V.CLIENT_NO = C.CLIENT_NO
	LEFT JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = V.DEPT_NO
GO
