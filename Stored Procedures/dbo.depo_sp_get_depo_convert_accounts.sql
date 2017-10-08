SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_convert_accounts]
	@depo_id int,
	@op_id int = NULL
AS
SET NOCOUNT ON;

DECLARE @T TABLE(DEPO_ACC_ID int NOT NULL PRIMARY KEY)

INSERT INTO @T
SELECT DISTINCT D.DEPO_ACC_ID
FROM
(SELECT DEPO_ACC_ID
FROM dbo.DEPO_DEPOSITS_HISTORY
WHERE (DEPO_ID = @depo_id) AND (@op_id IS NULL OR OP_ID <= @op_id)
UNION
SELECT DEPO_ACC_ID
FROM dbo.DEPO_DEPOSITS
WHERE (DEPO_ID = @depo_id) AND (@op_id IS NULL)) D

SELECT A.ACC_ID, A.ACCOUNT, A.ISO, ROUND(P.TOTAL_CALC_AMOUNT, 2) AS TOTAL_CALC_AMOUNT, P.LAST_CALC_DATE
FROM dbo.ACCOUNTS_CRED_PERC P (NOLOCK)
	INNER JOIN @T T ON P.ACC_ID = T.DEPO_ACC_ID
	INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = P.ACC_ID

GO
