SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[show_aml_new_clients] 
	@client_no int,
	@dt1 smalldatetime,
	@dt2 smalldatetime
AS

SELECT O.*
FROM dbo.DOCS_ALL O (NOLOCK)
	LEFT JOIN dbo.ACCOUNTS AC (NOLOCK) ON AC.ACC_ID = O.CREDIT_ID
	LEFT JOIN dbo.ACCOUNTS AD (NOLOCK) ON AD.ACC_ID = O.DEBIT_ID
	LEFT JOIN dbo.CLIENTS C (NOLOCK) ON C.CLIENT_NO = AC.CLIENT_NO OR C.CLIENT_NO = AD.CLIENT_NO
WHERE C.CLIENT_NO = @client_no AND O.DOC_DATE BETWEEN @dt1 AND @dt2
ORDER BY O.REC_ID
GO