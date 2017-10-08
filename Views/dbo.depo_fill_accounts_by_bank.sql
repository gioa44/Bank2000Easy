SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[depo_fill_accounts_by_bank]
AS
	SELECT A.*
	FROM dbo.ACCOUNTS A
	WHERE (A.REC_STATE NOT IN (2, 128)) AND
		(A.BAL_ACC_ALT BETWEEN 4501.00 AND 4501.99 OR
		A.BAL_ACC_ALT BETWEEN 4511.00 AND 4511.99)
GO
