SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[loan_rep_scheduled_repayments] (
	@user_id int,
	@right_name varchar(100) = 'ÍÀáÅÀ',
	@field_list varchar(1000) = NULL,
	@view_name sysname = 'dbo.LOAN_VW_LOAN_REPS',
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL,
	@first_date smalldatetime,
	@last_date smalldatetime,
	@distinct bit = 0)
AS
SET NOCOUNT ON;

CREATE TABLE #tbl (LOAN_ID INT PRIMARY KEY)

INSERT INTO #tbl
EXEC [dbo].[loan_show_loans]
	@user_id = @user_id,
	@right_name = @right_name,
	@field_list = 'L.LOAN_ID',
	@view_name = 'dbo.LOANS',
	@where_sql1 = @where_sql1,
	@where_sql2 = @where_sql2,
	@where_sql3 = @where_sql3,
	@join_sql = @join_sql,
	@distinct = @distinct

DECLARE @sql nvarchar(4000)

IF @field_list IS NULL OR @field_list = '*'
	SET @field_list = 'L.*'

SET @sql = N'
SELECT ' + @field_list + N', 
	CASE WHEN L.DISBURSE_TYPE=4 THEN CASE WHEN LS.ORIGINAL_BALANCE<LD.PRINCIPAL THEN (LD.PRINCIPAL - LS.ORIGINAL_BALANCE) ELSE $0.00 END + LD.INTEREST ELSE ISNULL(LS.AMOUNT, $0.00) END AS SCHEDULED_AMOUNT,
	CASE WHEN L.DISBURSE_TYPE=4 AND LS.ORIGINAL_BALANCE<LD.PRINCIPAL THEN LD.PRINCIPAL - LS.ORIGINAL_BALANCE ELSE ISNULL(LS.PRINCIPAL, $0.00) END AS PRINCIPAL,
	CASE WHEN L.DISBURSE_TYPE=4 THEN Null ELSE ISNULL(LS.BALANCE, $0.00) END AS SCHEDULE_BALANCE,
	CASE WHEN L.DISBURSE_TYPE=4 THEN LD.INTEREST ELSE ISNULL(LS.INTEREST, $0.00) END AS INTEREST,
	LS.SCHEDULE_DATE, 
	dbo.LOAN_FN_GET_CLIENT_RATING_HISTORY(L.CLIENT_NO, @last_date) AS RAITING
FROM ' + @view_name + N' L
	INNER JOIN #tbl R ON R.LOAN_ID = L.LOAN_ID
	INNER JOIN dbo.LOAN_SCHEDULE LS ON LS.LOAN_ID = R.LOAN_ID
	LEFT JOIN dbo.LOAN_DETAILS LD ON LD.LOAN_ID = R.LOAN_ID
WHERE (LS.SCHEDULE_DATE BETWEEN @first_date AND @last_date) AND 
( ((L.DISBURSE_TYPE<>4) AND (LS.ORIGINAL_AMOUNT IS NOT NULL) AND (LS.AMOUNT>$0.00)) OR (L.DISBURSE_TYPE=4 AND (LS.ORIGINAL_BALANCE<LD.PRINCIPAL OR (LS.PAY_INTEREST = 1))))
ORDER BY LS.SCHEDULE_DATE'

EXEC sp_executesql @sql, N'@first_date smalldatetime, @last_date smalldatetime', @first_date, @last_date

DROP TABLE #tbl

GO
