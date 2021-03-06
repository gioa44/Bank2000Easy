SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[itrs_show_accounts_corr] ()
RETURNS @tbl TABLE (ACC_ID int NOT NULL PRIMARY KEY, ACCOUNT TACCOUNT NOT NULL, ISO TISO NOT NULL)
AS
BEGIN
	DECLARE @head_branch_id int
	SET @head_branch_id = dbo.bank_head_branch_id()

	INSERT INTO @tbl 
	SELECT A.ACC_ID, A.ACCOUNT, A.ISO
	FROM dbo.CORRESPONDENT_BANKS B (NOLOCK) 
		INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.BRANCH_ID = @head_branch_id AND A.ACCOUNT = B.NOSTRO_ACCOUNT AND A.ISO = B.ISO
	WHERE A.ACC_ID IS NOT NULL AND A.ISO <> 'GEL'

	RETURN
END
GO
