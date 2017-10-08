SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_depo_analyze_schema_proc]
	@depo_id int,
	@user_id int,
	@dept_no int,
	@analyze_date smalldatetime,
	@deposit_default bit OUTPUT,
	@remark varchar(255) OUTPUT
AS
SET NOCOUNT ON;

IF @deposit_default = 1
	RETURN 0

DECLARE
	@r int
	
DECLARE
	@start_date smalldatetime,
	@accumulative bit,
	@accumulate_min money,
	@accumulate_max money,
	@depo_acc_id int
	
SELECT @start_date = [START_DATE], @accumulative = ACCUMULATIVE, @accumulate_min = ACCUMULATE_MIN, @accumulate_max = ACCUMULATE_MAX, @depo_acc_id = DEPO_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

IF @accumulative <> 1
	RETURN 0

SET @start_date = DATEADD(DAY, -(DAY(@start_date) - 1), @start_date)
SET @start_date = DATEADD(MONTH, 1, @start_date)
	
DECLARE @DOCS TABLE (DATE smalldatetime NOT NULL PRIMARY KEY)
DECLARE @DATES TABLE (DATE smalldatetime NOT NULL PRIMARY KEY)
	
INSERT INTO @DOCS(DATE)
SELECT DATEADD(DAY, -(DAY(O.DOC_DATE) - 1), O.DOC_DATE)
FROM dbo.OPS_FULL O (NOLOCK)
	INNER JOIN dbo.OPS_HELPER H (NOLOCK) ON O.REC_ID = H.REC_ID
WHERE H.ACC_ID = @depo_acc_id AND H.DT BETWEEN @start_date AND @analyze_date AND O.CREDIT_ID = H.ACC_ID AND (@accumulate_min IS NULL OR O.AMOUNT >= @accumulate_min) AND (@accumulate_max IS NULL OR O.AMOUNT <= @accumulate_max)
GROUP BY DATEADD(DAY, -(DAY(O.DOC_DATE) - 1), O.DOC_DATE)

WHILE @start_date <= @analyze_date
BEGIN
	INSERT @DATES(DATE) VALUES (@start_date)
	SET @start_date = DATEADD(MONTH, 1, @start_date)
END

DELETE D
FROM @DATES D
	INNER JOIN @DOCS docs ON D.DATE = docs.DATE
	
IF (SELECT COUNT(*) FROM @DATES) > 2
BEGIN
	SET @deposit_default = 1
	SET @remark = 'ÃÀÒÙÅÄÖËÉÀ ÐÉÒÏÁÀ 2-ÆÄ ÌÄÔãÄÒ ÀÒ ÌÏÌáÃÀÒÀ ÃÄÐÏÆÉÔÆÄ ÃÀÂÒÏÅÄÁÀ'
END


RETURN 0
GO
