SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[loan_rep_problem_loans2] (
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

SET @first_date = convert(smalldatetime,floor(convert(real, @first_date)))
SET @last_date = convert(smalldatetime,floor(convert(real, @last_date)))
SET @sql = N'
SELECT ' + @field_list + N', dbo.LOAN_FN_GET_CLIENT_RATING_HISTORY(L.CLIENT_NO, @last_date) AS RAITING
FROM ' + @view_name + N' L
	INNER JOIN #tbl R ON R.LOAN_ID = L.LOAN_ID
WHERE EXISTS(  
				SELECT CN2.CLIENT_NO FROM dbo.CLIENT_NOTES CN2 WHERE  
				CN2.CLIENT_NO = L.CLIENT_NO AND NOTE_TYPE = 3  AND 
				( 
					(
						convert(smalldatetime,floor(convert(real, CN2.DATE))) <= @first_date AND 
						( convert(smalldatetime,floor(convert(real, CN2.DATE2))) >= @first_date OR CN2.DATE2 IS NULL ) 
					) OR

					(convert(smalldatetime,floor(convert(real, CN2.DATE) ) ) BETWEEN @first_date AND @last_date) 
				) 

			)'

EXEC sp_executesql @sql, N'@first_date smalldatetime, @last_date smalldatetime', @first_date, @last_date
DROP TABLE #tbl

GO
