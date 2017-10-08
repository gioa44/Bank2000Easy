SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ops_arc_is_good]
	@doc_id int,
	@user_id int,
	@right_name varchar(100) = 'ÍÀáÅÀ',
	@view_name sysname = 'dbo.OPS_ARC',
	@where_sql varchar(max) = null,
	@is_good bit OUTPUT,
	@doc_date smalldatetime = null
AS

SET NOCOUNT ON

SET @is_good = 0

IF ISNULL(@view_name, '') = ''
	SET @view_name = 'dbo.OPS_ARC'

DECLARE
	@is_ok bit,
	@dept_no int,
	@branch_id int,
	@sql_str0 nvarchar(100),
	@sql_str nvarchar(max)

SET @sql_str0 = N'IF EXISTS(SELECT * FROM ' + @view_name + ' O(NOLOCK) '

SET @dept_no = dbo.user_dept_no(@user_id)
SET @branch_id = dbo.user_branch_id(@user_id)

DECLARE
	@join_sql nvarchar(max),
	@set_where_sql nvarchar(max),
	@is_exception bit

DECLARE cc CURSOR LOCAL FAST_FORWARD
FOR
SELECT JOIN_SQL, WHERE_SQL, IS_EXCEPTION 
FROM dbo.ops_arc_user_sets_sql(@user_id, @right_name)
WHERE (@right_name IS NOT NULL) OR (IS_EXCEPTION = 0)
ORDER BY IS_EXCEPTION DESC, SET_ID

OPEN cc
FETCH NEXT FROM cc INTO @join_sql, @set_where_sql, @is_exception

WHILE @@FETCH_STATUS = 0
BEGIN
PRINT 1
	SET @sql_str = @sql_str0 + ISNULL(@join_sql, '')
	IF ISNULL(@set_where_sql, '') <> ''
		SET @sql_str = @sql_str + ' WHERE O.REC_ID = @doc_id AND ' + CASE WHEN @doc_date IS NULL THEN '' ELSE 'O.DOC_DATE = @doc_date AND ' END + @set_where_sql
	ELSE
		SET @sql_str = @sql_str + ' WHERE O.REC_ID = @doc_id' + CASE WHEN @doc_date IS NULL THEN '' ELSE ' AND O.DOC_DATE = @doc_date' END

	IF ISNULL(@where_sql, '') <> ''
		SET @sql_str = @sql_str + ' AND (' + @where_sql + ')'

	SET @sql_str = @sql_str + ' ) SET @is_ok = 1'

	--PRINT @sql_str
	SET @is_ok = 0
	EXEC sp_executesql @sql_str, N'@doc_id int, @doc_date smalldatetime, @branch_id int, @dept_no int, @user_id int, @is_ok bit OUTPUT', @doc_id, @doc_date, @branch_id, @dept_no, @user_id, @is_ok OUTPUT

	IF @is_ok <> 0
	BEGIN
		IF @is_exception = 0
			SET @is_good = 1
		BREAK
	END

	FETCH NEXT FROM cc INTO @join_sql, @set_where_sql, @is_exception
END

CLOSE cc
DEALLOCATE cc

RETURN 0
GO
