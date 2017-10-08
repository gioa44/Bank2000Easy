SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[itrs_show_docs]
	@user_id int, 
	@start_date smalldatetime, 
	@end_date smalldatetime,
	@type tinyint = 0,
	@where_sql nvarchar(max) = NULL,
	@join_sql nvarchar(max) = NULL,
	@count int = -1,
	@only_empty bit = 0
AS

SET NOCOUNT ON;

DECLARE
	@where_sql0 nvarchar(max),
	@topn nvarchar(20)

SET @where_sql0 = REPLACE(RTRIM(LTRIM(ISNULL(@where_sql, ''))),CHAR(0),'')
SET @topn = CASE WHEN @count >= 0 THEN N' TOP ' + CONVERT(nvarchar(16), @count) ELSE N'' END + N' '

SET @join_sql = ISNULL(@join_sql, '')
IF @join_sql <> ''
	SET @join_sql = CHAR(13) + @join_sql

DECLARE	@sql nvarchar(max)

SET @sql = 
N'SELECT ' +  @topn + 
N'CASE WHEN ITRS_CODE$ IS NOT NULL THEN ITRS_CODE$ ELSE dbo.itrs_def_code (REC_TYPE, IS_JURIDICAL, IS_RESIDENT2, AMOUNT_USD, DOC_TYPE) END AS ITRS_CODE, 
O.*
FROM dbo.itrs_show_docs_internal (@start_date, @end_date, @type, null) O' + CHAR(13) +
@join_sql +
CASE WHEN @where_sql0 <> '' THEN ' WHERE ' ELSE '' END + @where_sql0 + CHAR(13) 

IF @count > 0 
	SET @sql = @sql + CHAR(13) + N'ORDER BY O.REC_ID DESC'

IF @only_empty = 1
	SET @sql = N'SELECT * FROM (' + @sql + ') A WHERE ITRS_CODE IS NULL'

--PRINT @sql
EXEC sp_executesql @sql, N'@type tinyint, @start_date smalldatetime, @end_date smalldatetime, @user_id int', @type, @start_date, @end_date, @user_id
GO
