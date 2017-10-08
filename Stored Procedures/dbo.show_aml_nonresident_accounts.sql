SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[show_aml_nonresident_accounts]
	@user_id int,
	@right_name varchar(100) = 'ÍÀáÅÀ',
	@field_list varchar(1000) = NULL,
	@view_name sysname = 'dbo.ACC_VIEW',
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL,
	@count int = -1
AS

DECLARE @sql nvarchar(1000)

SET @sql = N'
SELECT A.* 
FROM dbo.C_ACCOUNTS A (NOLOCK)
	INNER JOIN dbo.CLIENTS C (NOLOCK) ON C.CLIENT_NO = A.CLIENT_NO
WHERE C.IS_RESIDENT = 0'

IF ISNULL(@where_sql1, '') <> ''
	SET @sql = @sql + N' AND ' + @where_sql1

EXEC sp_executesql @sql
GO
