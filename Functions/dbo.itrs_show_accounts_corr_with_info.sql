SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[itrs_show_accounts_corr_with_info] (@start_date smalldatetime, @end_date smalldatetime)
RETURNS TABLE 
AS
RETURN 
	SELECT A.ACC_ID, CONVERT(varchar(15),A.ACCOUNT) + '/' + A.ISO + ' (' + CONVERT(varchar(10), ACC.BRANCH_ID) + ')' AS CorrAccount, A.ISO AS Currency, 
		CASE WHEN ACC.ACT_PAS = 2 THEN 'N' ELSE 'L' END AS AccountType,
		B.BIC AS PartnerBic, B.DESCRIP AS Partner, SUBSTRING(B.BIC, 5, 2) AS PartnerCountry,
		CASE WHEN ACC.ACT_PAS <> 2 THEN -1 ELSE 1 END * dbo.acc_get_balance (A.ACC_ID, @start_date, 1, 0, 0) AS BalanceOpen, 
		CASE WHEN ACC.ACT_PAS <> 2 THEN -1 ELSE 1 END * dbo.acc_get_balance (A.ACC_ID, @end_date, 0, 0, 0) AS BalanceClose,
		ACC.ACT_PAS
	FROM dbo.itrs_show_accounts_corr () A
		INNER JOIN dbo.CORRESPONDENT_BANKS B (NOLOCK) ON A.ACCOUNT = B.NOSTRO_ACCOUNT AND A.ISO = B.ISO
		INNER JOIN dbo.ACCOUNTS ACC (NOLOCK) ON ACC.ACC_ID = A.ACC_ID
GO
