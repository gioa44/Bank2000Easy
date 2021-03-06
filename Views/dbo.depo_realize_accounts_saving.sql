SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[depo_realize_accounts_saving]
AS
	SELECT A.*
	FROM dbo.ACCOUNTS A
	WHERE (A.REC_STATE NOT IN (2,128)) AND (A.ACC_TYPE IN (2, 32, 100, 200)) AND
		((A.ACC_TYPE <> 2) OR ((A.ACC_TYPE = 2) AND ((A.BAL_ACC_ALT BETWEEN 1003.00 AND 1003.99) OR (A.BAL_ACC_ALT BETWEEN 1013.00 AND 1013.99)))) AND
		((A.ACC_TYPE <> 32) OR ((A.ACC_TYPE = 32) AND (A.ACC_SUBTYPE IN (1070)))) AND
		((A.ACC_TYPE <> 100) OR ((A.ACC_TYPE = 100) AND (A.CLIENT_NO IS NOT NULL))) AND
		((A.ACC_TYPE <> 200) OR ((A.ACC_TYPE = 200) AND (A.CLIENT_NO IS NOT NULL)))
GO
