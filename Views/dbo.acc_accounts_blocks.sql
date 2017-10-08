SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[acc_accounts_blocks]
AS
	SELECT ACC_ID, BLOCK_ID, IS_ACTIVE,	AMOUNT, ISO, FEE, BLOCKED_BY_PRODUCT,
		BLOCKED_BY_USER, RTRIM(USR.USER_NAME) + '@' + DP.ALIAS AS BLOCKED_BY_USER_NAME, USR.USER_FULL_NAME AS BLOCKED_BY_USER_FULL_NAME,
		BLOCK_DATE_TIME, AUTO_UNBLOCK_DATE,
		UNBLOCKED_BY_USER, RTRIM(USR2.USER_NAME) + '@' + DP2.ALIAS AS UNBLOCKED_BY_USER_NAME, USR2.USER_FULL_NAME AS UNBLOCKED_BY_USER_FULL_NAME,
		UNBLOCK_DATE_TIME, USER_DATA
	FROM dbo.ACCOUNTS_BLOCKS A
	  INNER JOIN  dbo.USERS USR (NOLOCK) ON A.BLOCKED_BY_USER = USR.USER_ID
	  INNER JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = USR.DEPT_NO
	  LEFT JOIN  dbo.USERS USR2 (NOLOCK) ON A.UNBLOCKED_BY_USER = USR2.USER_ID
	  LEFT JOIN dbo.DEPTS DP2 (NOLOCK) ON DP2.DEPT_NO = USR2.DEPT_NO
GO