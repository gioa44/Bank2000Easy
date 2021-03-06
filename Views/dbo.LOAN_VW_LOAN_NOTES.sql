SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_LOAN_NOTES]
AS
SELECT N.LOAN_ID, N.REC_ID, N.DATE_TIME, N.OWNER, RTRIM(U.USER_NAME) + '@' + D.ALIAS AS USER_NAME, N.OP_TYPE, O.OP_ID, T.DESCRIP AS OP_DESCRIP, T.DESCRIP_LAT AS OP_DESCRIP_LAT, N.NOTE
FROM dbo.LOAN_NOTES N (NOLOCK)
	INNER JOIN dbo.USERS U (NOLOCK) ON U.USER_ID = N.OWNER
	INNER JOIN dbo.DEPTS D (NOLOCK) ON D.DEPT_NO = U.DEPT_NO
	LEFT OUTER JOIN dbo.LOAN_OP_TYPES T (NOLOCK) ON N.OP_TYPE = T.TYPE_ID
	LEFT OUTER JOIN dbo.LOAN_OPS O (NOLOCK) ON O.NOTE_REC_ID = N.REC_ID
GO
