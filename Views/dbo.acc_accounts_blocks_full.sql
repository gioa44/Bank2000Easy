SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[acc_accounts_blocks_full] AS

SELECT C.CLIENT_NO, C.DESCRIP, A.ACCOUNT, AB.*
FROM dbo.acc_accounts_blocks AB (NOLOCK)
	INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = AB.ACC_ID
	LEFT JOIN dbo.CLIENTS C (NOLOCK) ON C.CLIENT_NO = A.CLIENT_NO
GO
