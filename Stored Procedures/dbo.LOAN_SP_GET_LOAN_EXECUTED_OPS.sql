SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOAN_EXECUTED_OPS]
	@user_id int, 
	@start_date smalldatetime, 
	@end_date smalldatetime = NULL, 
	@eng_version bit = 0, 
	@op_types varchar(255) = NULL,
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL
AS


SET NOCOUNT ON

CREATE TABLE #tbl (LOAN_ID INT PRIMARY KEY)

INSERT INTO #tbl
EXEC dbo.loan_show_loans
	@user_id = @user_id,
	@right_name = 'ÍÀáÅÀ',
	@field_list = 'L.LOAN_ID',
	@view_name = 'dbo.LOANS',
	@where_sql1 = @where_sql1,
	@where_sql2 = @where_sql2,
	@where_sql3 = @where_sql3,
	@join_sql = @join_sql

DECLARE @sql nvarchar(4000)

SET @sql = N'
SELECT L.* FROM #tbl R
	INNER JOIN dbo.LOAN_FN_GET_LOAN_EXECUTED_OPS(@start_date, @end_date, @eng_version, @op_types) L ON L.LOAN_ID = R.LOAN_ID'


--PRINT @sql
EXEC sp_executesql @sql, N'@start_date smalldatetime, @end_date smalldatetime, @eng_version bit, @op_types varchar(255)',
		 @start_date, @end_date, @eng_version, @op_types
		 
DROP TABLE #tbl		 
		 
GO
