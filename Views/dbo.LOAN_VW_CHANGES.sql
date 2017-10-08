SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_CHANGES]
AS
SELECT A.LOAN_ID, A.TIME_OF_CHANGE, U.USER_NAME + '@' + DP.ALIAS AS USER_NAME, U.USER_FULL_NAME,
CASE WHEN DATALENGTH(A.DESCRIP) <= 255 THEN SUBSTRING(A.DESCRIP,1,255) ELSE '"ÉáÉËÄÈ ÃÀÓÀáÄËÄÁÀ ÅÒÝËÀÃ"' END AS DESCRIP, A.REC_ID, A.DESCRIP AS LONG_DESCRIP
FROM dbo.LOAN_CHANGES A (NOLOCK)
	INNER JOIN dbo.USERS U (NOLOCK) ON A.USER_ID = U.USER_ID
	INNER JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = U.DEPT_NO

GO
