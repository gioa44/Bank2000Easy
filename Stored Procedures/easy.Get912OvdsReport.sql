SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [easy].[Get912OvdsReport]
AS
DECLARE
	@end2012 smalldatetime,
	@today smalldatetime
SET @end2012 = '20121231'
SET @today = FLOOR(CONVERT(money, GETDATE()));

WITH accs AS
(
	SELECT 
		dbo.acc_get_balance(LA.ACC_ID, @end2012, 0, 0, 0) AS Dec2012Balance, --@ShadowLevel-s azri ar aqvs daxuruli dgea
		dbo.acc_get_balance(LA.ACC_ID, @today, 0, 0, 0) AS TodayBalance, --@ShadowLevel=0 citeli sabutebi da zevit
		--easy.GetBefore2012OverduePerc(LA.LOAN_ID) AS Before2012OvdPerc,
		LA.LOAN_ID, A.* 
	FROM dbo.LOAN_ACCOUNTS LA
		INNER JOIN dbo.ACCOUNTS A ON LA.ACC_ID = A.ACC_ID
	WHERE LA.ACCOUNT_TYPE = 2060
) 
SELECT 
	accs.Dec2012Balance, accs.TodayBalance, 
	accs.TodayBalance - accs.Dec2012Balance AS Diff, 	
	CASE WHEN accs.TodayBalance > accs.Dec2012Balance THEN accs.Dec2012Balance ELSE accs.TodayBalance END AS BalanceToReturn, -- Take Minimum of two
	--accs.Before2012OvdPerc, es ar gvinda radgan 2011-shi gatishuli iko garebalansze gadatana da 2011-is 30OvdPerc-ebi 912 moxvda 2012-shi, isev chartvis shemdeg
	accs.ISO,
	accs.LOAN_ID, L.AGREEMENT_NO, LD.OVERDUE_DATE, 
	CASE WHEN LD.LOAN_ID IS NULL THEN 'not exists' ELSE 'exists' END AS [Exists In LoanDetails]
FROM accs
	INNER JOIN dbo.LOANS L (NOLOCK) ON accs.LOAN_ID = L.LOAN_ID
	LEFT JOIN dbo.LOAN_DETAILS LD (NOLOCK) ON accs.LOAN_ID = LD.LOAN_ID	
WHERE accs.Dec2012Balance <> 0.00
ORDER BY LD.OVERDUE_DATE
GO
