SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ops_show_op_rights]
	@doc_id int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@is_ok bit,
	@dept_no int,
	@branch_id int,
	@group_id int,
	@sql_str0 nvarchar(100),
	@sql_str nvarchar(4000)

SET @sql_str0 = N'IF EXISTS(SELECT * FROM dbo.OPS_0000 O(NOLOCK) '

SELECT @dept_no = DEPT_NO, @group_id = GROUP_ID 
FROM dbo.USERS (NOLOCK)
WHERE [USER_ID] = @user_id

SET @branch_id = dbo.dept_branch_id(@dept_no)
	

DECLARE
	@set_id int,
	@join_sql nvarchar(4000),
	@where_sql nvarchar(4000),
	@is_exception bit 

DECLARE @tbl TABLE (RIGHT_NAME varchar(100) PRIMARY KEY)

DECLARE cc CURSOR LOCAL FAST_FORWARD
FOR
SELECT SET_ID, JOIN_SQL, WHERE_SQL, IS_EXCEPTION
FROM dbo.ops_user_sets_sql(@user_id, null)
ORDER BY IS_EXCEPTION, SET_ID

OPEN cc
FETCH NEXT FROM cc INTO @set_id, @join_sql, @where_sql, @is_exception

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql_str = @sql_str0 + ISNULL(@join_sql, '')
	IF ISNULL(@where_sql, '') <> ''
		SET @sql_str = @sql_str + ' WHERE O.REC_ID = @doc_id AND ' + @where_sql
	ELSE
		SET @sql_str = @sql_str + ' WHERE O.REC_ID = @doc_id'
	
	SET @sql_str = @sql_str + ' ) SET @is_ok = 1'
	
	--PRINT @sql_str
	SET @is_ok = 0
	EXEC sp_executesql @sql_str, N'@doc_id int, @branch_id int, @dept_no int, @user_id int, @is_ok bit OUTPUT', @doc_id, @branch_id, @dept_no, @user_id, @is_ok OUTPUT
	
	IF @is_ok <> 0
	BEGIN
		IF @is_exception = 0
			INSERT INTO @tbl
			SELECT ASR.RIGHT_NAME
			FROM dbo.OPS_SET_RIGHTS ASR (NOLOCK)
			WHERE ASR.GROUP_ID = @group_id AND ASR.SET_ID = @set_id AND NOT EXISTS(SELECT * FROM @tbl a WHERE a.RIGHT_NAME = ASR.RIGHT_NAME)
		ELSE
			DELETE A
			FROM @tbl A
				INNER JOIN dbo.OPS_SET_RIGHTS ASR (NOLOCK) ON ASR.RIGHT_NAME = A.RIGHT_NAME
			WHERE ASR.GROUP_ID = @group_id AND ASR.SET_ID = @set_id
	END
	
	FETCH NEXT FROM cc INTO @set_id, @join_sql, @where_sql, @is_exception
END

CLOSE cc
DEALLOCATE cc

SELECT * FROM @tbl
GO
