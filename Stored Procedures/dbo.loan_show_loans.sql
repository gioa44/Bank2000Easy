SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[loan_show_loans]
	@user_id int,
	@right_name varchar(100) = 'ÍÀáÅÀ',
	@field_list nvarchar(max) = NULL,
	@view_name sysname = 'dbo.LOAN_VW_LOANS',
	@where_sql nvarchar(max) = NULL,
	@join_sql nvarchar(max) = NULL,
	@count int = -1,
	@distinct bit = 0,

	-- do not use these parameters anymore, they are here temporary for backward compatibility only
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL
AS

SET NOCOUNT ON

DECLARE
	@where_sql0 nvarchar(max),
	@topn nvarchar(20)

SET @where_sql0 = REPLACE(RTRIM(LTRIM(ISNULL(@where_sql, '') + ISNULL(@where_sql1, '') + ISNULL(@where_sql2, '') + ISNULL(@where_sql3, ''))),CHAR(0),'')
SET @topn = CASE WHEN @count >= 0 THEN N' TOP ' + CONVERT(nvarchar(16), @count) ELSE N'' END + N' '

SET @join_sql = ISNULL(@join_sql, '')
IF @join_sql <> ''
	SET @join_sql = CHAR(13) + @join_sql

IF ISNULL(@field_list, '') = '' OR (@field_list = '*')
	SET @field_list = 'L.*'

IF ISNULL(@view_name, '') = ''
	SET @view_name = 'dbo.LOANS'

DECLARE
	@dept_no int,
	@branch_id int,
	@sql_str0 nvarchar(100),
	@sql_str nvarchar(4000),
	@sql nvarchar(4000)

SET @sql_str0 = N'SELECT L.LOAN_ID FROM L '
SET @sql = ''

SET @dept_no = dbo.user_dept_no(@user_id)
SET @branch_id = dbo.user_branch_id(@user_id)

DECLARE
	@set_id int,
	@set_join_sql nvarchar(max),
	@is_exception bit

DECLARE cc CURSOR LOCAL FAST_FORWARD
FOR
SELECT SET_ID, JOIN_SQL, WHERE_SQL, IS_EXCEPTION
FROM dbo.loan_user_sets_sql(@user_id, @right_name)
ORDER BY IS_EXCEPTION, SET_ID

OPEN cc
FETCH NEXT FROM cc INTO @set_id, @set_join_sql, @where_sql, @is_exception

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @where_sql = ISNULL(@where_sql, '')

	SET @sql_str = @sql_str0 + ISNULL(@set_join_sql, '')
	IF ISNULL(@where_sql, '') <> ''
		SET @sql_str = @sql_str + ' WHERE ' + @where_sql
	IF @sql <> ''
		SET @sql = @sql + CHAR(13) + CASE WHEN @is_exception = 0 THEN 'UNION' ELSE 'EXCEPT' END + CHAR(13)
	SET @sql = @sql + @sql_str
	
	FETCH NEXT FROM cc INTO @set_id, @set_join_sql, @where_sql, @is_exception
END

CLOSE cc
DEALLOCATE cc

IF @sql = ''
	SET @sql = N'SELECT TOP 0 ' + @field_list + N' FROM ' + @view_name + ' L (NOLOCK)'
ELSE
IF @field_list <> 'LOAN_ID' AND @field_list <> 'L.LOAN_ID'
BEGIN
	SET @sql = N'SELECT ' +  @topn + @field_list + N' FROM (' + CHAR(13) +
		@sql + N') LLL' + CHAR(13) +
		N'  INNER JOIN ' + @view_name + N' L (NOLOCK) ON L.LOAN_ID = LLL.LOAN_ID'
END

SET @sql = N'WITH L AS (SELECT ' + CASE WHEN @distinct = 1 THEN 'DISTINCT ' ELSE '' END + 
	'L.* FROM dbo.LOANS L(NOLOCK)' + @join_sql +
	CASE WHEN @where_sql0 <> '' THEN ' WHERE ' ELSE '' END + @where_sql0 + N')'+ CHAR(13) + @sql 

--PRINT @sql
EXEC sp_executesql @sql, N'@branch_id int, @dept_no int, @user_id int', @branch_id, @dept_no, @user_id
GO
