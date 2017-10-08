SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_show_cred_accruals] (@acc_id int) 
RETURNS TABLE 
AS

RETURN
	SELECT O.* 
	FROM dbo.DOCS_MEMO O
	WHERE O.DOC_TYPE IN (30, 31) AND ACCOUNT_EXTRA = @acc_id

	UNION ALL

	SELECT O.* 
	FROM dbo.DOCS_ARC_MEMO O
	WHERE O.DOC_TYPE IN (30, 31) AND ACCOUNT_EXTRA = @acc_id
GO