SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[show_aml_clients2]
	@dt1 smalldatetime,
	@dt2 smalldatetime
AS

-- Walk in clients

SELECT B.* FROM (
	SELECT B.PERSONAL_ID
	FROM dbo.OPS_0000 D (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PASSPORTS A (NOLOCK) ON A.DOC_REC_ID = D.REC_ID
		INNER JOIN dbo.OTHER_CLIENT_INFO B (NOLOCK) ON B.PERSONAL_ID = A.PERSONAL_ID OR B.PASSPORT = A.PASSPORT
	WHERE D.DOC_DATE BETWEEN @dt1 AND @dt2 --AND NOT EXISTS(SELECT * FROM dbo.CLIENTS C (NOLOCK) WHERE C.PERSONAL_ID = A.PERSONAL_ID)
	GROUP BY B.PERSONAL_ID
	HAVING SUM(D.AMOUNT_EQU) > 30000
) X
	INNER JOIN dbo.OTHER_CLIENT_INFO B (NOLOCK) ON B.PERSONAL_ID = X.PERSONAL_ID
ORDER BY B.PERSONAL_ID
GO
