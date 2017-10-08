SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[itrs_show_accounts_nonres_with_info] (@start_date smalldatetime, @end_date smalldatetime)
RETURNS TABLE 
AS
RETURN 
	SELECT A.ACC_ID, CONVERT(varchar(15),A.ACCOUNT) + '/' + A.ISO + ' (' + CONVERT(varchar(10), ACC.BRANCH_ID) + ')' AS CorrAccount, A.ISO AS Currency, 
		'M' AS AccountType,
		'' AS PartnerBic, '' AS Partner, C.COUNTRY AS PartnerCountry,
		CASE WHEN ACC.ACT_PAS <> 2 THEN -1 ELSE 1 END * dbo.acc_get_balance (A.ACC_ID, @start_date, 1, 0, 0) AS BalanceOpen, 
		CASE WHEN ACC.ACT_PAS <> 2 THEN -1 ELSE 1 END * dbo.acc_get_balance (A.ACC_ID, @end_date, 0, 0, 0) AS BalanceClose,
		ACC.ACT_PAS
	FROM dbo.itrs_show_accounts_nonres () A
		INNER JOIN dbo.ACCOUNTS ACC (NOLOCK) ON ACC.ACC_ID = A.ACC_ID
		INNER JOIN dbo.CLIENTS C (NOLOCK) ON C.CLIENT_NO = ACC.CLIENT_NO
	WHERE ISNULL(ACC.DATE_CLOSE, @end_date) >= @start_date AND ACC.REC_STATE NOT IN (2, 64, 128)
GO
