SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[loan_sp_overdue30_penalty_report]
	@start_date smalldatetime,
	@end_date smalldatetime
AS
SET NOCOUNT ON;

IF NOT EXISTS (SELECT * FROM dbo.LOAN_DETAILS_HISTORY WHERE CALC_DATE = @end_date)
BEGIN
	RAISERROR ('ÓÀÁÏËÏÏ ÈÀÒÉÙÉ ÀÒ ÀÒÉÓ ÃáÀÖÒÖËÉ ÃÙÄ', 16, 1);
	RETURN (0);
END

DECLARE @T TABLE (
	LOAN_ID int NOT NULL PRIMARY KEY,
	OVERDUE_PERCENT_PENALTY money NULL,
	OVERDUE_PRINCIPAL_PENALTY money NULL)
	
INSERT INTO @T (LOAN_ID, OVERDUE_PERCENT_PENALTY, OVERDUE_PRINCIPAL_PENALTY)
SELECT D.LOAN_ID, ISNULL(SUM(D.OVERDUE_PERCENT_PENALTY_DAILY), $0.00), ISNULL(SUM(D.OVERDUE_PRINCIPAL_PENALTY_DAILY), $0.00)
FROM dbo.LOANS L WITH (NOLOCK)
	INNER JOIN dbo.LOAN_DETAILS_HISTORY D WITH (NOLOCK) ON L.LOAN_ID = D.LOAN_ID
	INNER JOIN dbo.LOAN_DETAILS_HISTORY D2 WITH (NOLOCK) ON L.LOAN_ID = D2.LOAN_ID
WHERE (D2.CALC_DATE = @end_date AND D2.OVERDUE_DATE IS NOT NULL AND D2.OVERDUE_DATE <= @end_date) AND (D.CALC_DATE BETWEEN @start_date AND @end_date AND
	(ISNULL(D.OVERDUE_PERCENT_PENALTY_DAILY, $0.00) + ISNULL(D.OVERDUE_PRINCIPAL_PENALTY_DAILY, $0.00) > $0.00))
GROUP BY D.LOAN_ID

UPDATE T
SET T.OVERDUE_PERCENT_PENALTY = ISNULL(D.OVERDUE_PERCENT_PENALTY, $0.00)
FROM @T T
	INNER JOIN dbo.LOAN_DETAILS_HISTORY D WITH (NOLOCK) ON T.LOAN_ID = D.LOAN_ID
WHERE D.CALC_DATE = @end_date AND ISNULL(D.OVERDUE_PERCENT_PENALTY, $0.00) < ISNULL(T.OVERDUE_PERCENT_PENALTY, $0.00)

UPDATE T
SET T.OVERDUE_PRINCIPAL_PENALTY = ISNULL(D.OVERDUE_PRINCIPAL_PENALTY, $0.00)
FROM @T T
	INNER JOIN dbo.LOAN_DETAILS_HISTORY D WITH (NOLOCK) ON T.LOAN_ID = D.LOAN_ID
WHERE D.CALC_DATE = @end_date AND ISNULL(D.OVERDUE_PRINCIPAL_PENALTY, $0.00) < ISNULL(T.OVERDUE_PRINCIPAL_PENALTY, $0.00)

DELETE FROM @T
WHERE ISNULL(OVERDUE_PERCENT_PENALTY, $0.00) + ISNULL(OVERDUE_PRINCIPAL_PENALTY, $0.00) = $0.00

SELECT L.LOAN_ID, L.AGREEMENT_NO, L.CLIENT_NO, L.ISO, L.BAL_ACC, ISNULL(T.OVERDUE_PERCENT_PENALTY, $0.00) + ISNULL(T.OVERDUE_PRINCIPAL_PENALTY, $0.00) AS PENALTY30DAY, A1.ACC_ID, ACC1.ACCOUNT, ACC1.ISO, A2.ACC_ID, ACC2.ACCOUNT, ACC2.ISO
FROM @T T
	INNER JOIN dbo.LOANS L WITH (NOLOCK) ON T.LOAN_ID = L.LOAN_ID
	INNER JOIN dbo.LOAN_DETAILS_HISTORY D WITH (NOLOCK) ON D.LOAN_ID = T.LOAN_ID
	LEFT OUTER JOIN dbo.LOAN_ACCOUNTS A1 WITH (NOLOCK) ON A1.LOAN_ID = T.LOAN_ID AND A1.ACCOUNT_TYPE = 1030
	LEFT OUTER JOIN dbo.ACCOUNTS ACC1 WITH (NOLOCK) ON ACC1.ACC_ID = A1.ACC_ID
	LEFT OUTER JOIN dbo.LOAN_ACCOUNTS A2 WITH (NOLOCK) ON A2.LOAN_ID = T.LOAN_ID AND A2.ACCOUNT_TYPE = 1130
	LEFT OUTER JOIN dbo.ACCOUNTS ACC2 WITH (NOLOCK) ON ACC2.ACC_ID = A2.ACC_ID
WHERE D.CALC_DATE = @end_date


DECLARE @T1 TABLE (
	LOAN_ID int NOT NULL PRIMARY KEY,
	INTEREST money NULL)


INSERT INTO @T1(LOAN_ID, INTEREST)
SELECT DISTINCT D.LOAN_ID,  ISNULL(D.INTEREST, $0.00) + ISNULL(D.OVERDUE_PRINCIPAL_INTEREST, $0.00)
FROM dbo.LOANS L WITH (NOLOCK)
	INNER JOIN dbo.LOAN_DETAILS_HISTORY D WITH (NOLOCK) ON D.LOAN_ID = L.LOAN_ID
	INNER JOIN dbo.LOAN_DETAIL_OVERDUE O WITH (NOLOCK) ON O.LOAN_ID = L.LOAN_ID
WHERE D.CALC_DATE = @end_date AND O.OVERDUE_DATE <= DATEADD(DAY, -31, @end_date) AND ISNULL(O.OVERDUE_PRINCIPAL, $0.00) + ISNULL(O.OVERDUE_PERCENT, $0.00) > $0.00

DELETE FROM @T1
WHERE INTEREST = $0.00


SELECT L.LOAN_ID, L.AGREEMENT_NO, L.CLIENT_NO, L.ISO, L.BAL_ACC, T.INTEREST AS INTEREST_FOR_OUTBALANCE, A1.ACC_ID, ACC1.ACCOUNT, ACC1.ISO, A2.ACC_ID, ACC2.ACCOUNT, ACC2.ISO
FROM @T1 T
	INNER JOIN dbo.LOANS L WITH (NOLOCK) ON T.LOAN_ID = L.LOAN_ID
	INNER JOIN dbo.LOAN_DETAILS_HISTORY D WITH (NOLOCK) ON D.LOAN_ID = T.LOAN_ID
	LEFT OUTER JOIN dbo.LOAN_ACCOUNTS A1 WITH (NOLOCK) ON A1.LOAN_ID = T.LOAN_ID AND A1.ACCOUNT_TYPE = 1030
	LEFT OUTER JOIN dbo.ACCOUNTS ACC1 WITH (NOLOCK) ON ACC1.ACC_ID = A1.ACC_ID
	LEFT OUTER JOIN dbo.LOAN_ACCOUNTS A2 WITH (NOLOCK) ON A2.LOAN_ID = T.LOAN_ID AND A2.ACCOUNT_TYPE = 1130
	LEFT OUTER JOIN dbo.ACCOUNTS ACC2 WITH (NOLOCK) ON ACC2.ACC_ID = A2.ACC_ID
WHERE D.CALC_DATE = @end_date



RETURN 0;
GO
