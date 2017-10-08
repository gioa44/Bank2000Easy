SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[depo_sp_get_executed_ops]
	@user_id int, 
	@start_date smalldatetime, 
	@end_date smalldatetime = NULL, 
	@eng_version bit = 0, 
	@op_types varchar(255) = NULL,
	@where_sql nvarchar(max) = NULL,
	@join_sql nvarchar(max) = NULL
AS


SET NOCOUNT ON

DECLARE
	@where_sql0 nvarchar(max),
	@right_name varchar(100),
	@view_name sysname

SET @right_name = 'ÍÀáÅÀ'


DECLARE
	@dept_no int,
	@branch_id int,
	@sql_str0 nvarchar(100),
	@sql_str nvarchar(4000),
	@sql nvarchar(4000)


SET @where_sql0 = REPLACE(RTRIM(LTRIM(ISNULL(@where_sql, ''))),CHAR(0),'')
IF @where_sql0 <> ''
	SET @where_sql0 = '(' + @where_sql0 + ')'
	
SET @join_sql = ISNULL(@join_sql, '')
IF @join_sql <> ''
	SET @join_sql = CHAR(13) + @join_sql


SET @sql_str0 = N'SELECT L.DEPO_ID FROM dbo.DEPO_DEPOSITS L (NOLOCK) '
SET @sql = ''

SET @dept_no = dbo.user_dept_no(@user_id)
SET @branch_id = dbo.user_branch_id(@user_id)

DECLARE
	@set_id int,
	@set_join_sql nvarchar(max)

DECLARE cc CURSOR LOCAL FAST_FORWARD
FOR
SELECT SET_ID, JOIN_SQL, WHERE_SQL 
FROM dbo.depo_user_sets_sql2(@user_id, @right_name)

OPEN cc
FETCH NEXT FROM cc INTO @set_id, @set_join_sql, @where_sql

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @where_sql = ISNULL(@where_sql, '')
	IF @where_sql <> ''
		SET @where_sql = '(' + @where_sql + ')'

	SET @where_sql = @where_sql + CASE WHEN @where_sql <> '' AND @where_sql0 <> '' THEN ' AND ' ELSE '' END + @where_sql0

	SET @sql_str = @sql_str0 + ISNULL(@set_join_sql, '') + @join_sql

	IF ISNULL(@where_sql, '') <> ''
		SET @sql_str = @sql_str + ' WHERE ' + @where_sql
	IF @sql <> ''
		SET @sql = @sql + CHAR(13) + 'UNION' + CHAR(13)

	SET @sql = @sql + @sql_str
	
	FETCH NEXT FROM cc INTO @set_id, @set_join_sql, @where_sql
END

CLOSE cc
DEALLOCATE cc

IF @sql = ''
	SET @sql = N'SELECT TOP 0 L.* FROM dbo.depo_fn_get_executed_ops(@start_date, @end_date, @eng_version, @op_types) L'
ELSE
BEGIN
	SET @sql = N'SELECT L.* FROM (' + CHAR(13) +
		@sql + N') LLL' + CHAR(13) +
		N'  INNER JOIN dbo.depo_fn_get_executed_ops(@start_date, @end_date, @eng_version, @op_types) L ON L.DEPO_ID = LLL.DEPO_ID'
END

--PRINT @sql
EXEC sp_executesql @sql, N'@start_date smalldatetime, @end_date smalldatetime, @eng_version bit, @op_types varchar(255)',
		 @start_date, @end_date, @eng_version, @op_types
GO
