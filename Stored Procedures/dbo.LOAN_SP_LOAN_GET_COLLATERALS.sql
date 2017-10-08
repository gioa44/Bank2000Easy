SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_GET_COLLATERALS]
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL,
	@count int = -1
AS

DECLARE
	@where_sql0 nvarchar(4000),
	@topn nvarchar(20)

SET @where_sql0 = RTRIM(LTRIM(ISNULL(@where_sql1, '') + ISNULL(@where_sql2, '') + ISNULL(@where_sql3, '')))
SET @topn = CASE WHEN @count >= 0 THEN N' TOP ' + CONVERT(nvarchar(16), @count) ELSE N'' END + N' '

SET @join_sql = ISNULL(@join_sql, '')
IF @join_sql <> ''
	SET @join_sql = CHAR(13) + @join_sql

DECLARE
	@sql nvarchar(4000)

	SET @sql = N'SELECT ' +  @topn + N' L.* FROM dbo.LOAN_VW_LOAN_COLLATERALS L (NOLOCK)' + @join_sql +
		CASE WHEN @where_sql0 <> '' THEN ' WHERE ' ELSE '' END + @where_sql0

--PRINT @sql
EXEC sp_executesql @sql


RETURN 

GO
