SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DX_SPX_GET_DEPOSIT_LIST]
  @officer_id int,
  @where_sql_1 varchar(255) = '', @where_sql_2 varchar(255) = '', @where_sql_3 varchar(255) = '', @where_sql_4 varchar(255) = '', @where_sql_5 varchar(255) = '',
  @where_sql_6 varchar(255) = '', @where_sql_7 varchar(255) = '', @where_sql_8 varchar(255) = '', @where_sql_9 varchar(255) = '', @where_sql_10 varchar(255) = '',
  @where_sql_11 varchar(255) = '', @where_sql_12 varchar(255) = ''
AS

SET NOCOUNT ON
DECLARE  @where_sql nvarchar(3060)
DECLARE @sql_str nvarchar(4000)

SET 
  @where_sql = 
    ISNULL(@where_sql_1, '') + ISNULL(@where_sql_2, '') + ISNULL(@where_sql_3, '') + ISNULL(@where_sql_4, '')  + ISNULL(@where_sql_5, '') + 
    ISNULL(@where_sql_6, '') + ISNULL(@where_sql_7, '') + ISNULL(@where_sql_8, '') + ISNULL(@where_sql_9, '') + ISNULL(@where_sql_10, '') +
    ISNULL(@where_sql_11, '') + ISNULL(@where_sql_12, '')
SET @sql_str = 'SELECT * FROM dbo.DX_VW_DEPOSIT_LIST A (NOLOCK)'

SET @where_sql = ISNULL(@where_sql, '')

IF @officer_id IS NOT NULL
  SET @sql_str = @sql_str + N' WHERE (A.OFFICER_ID=@officer_id OR A.OFFICER_ID IN (SELECT USER_ID_2 FROM USER_RELATIONS WHERE USER_ID=@officer_id AND FLAGS & 4 <> 0))'

IF (@officer_id IS NULL) AND (@where_sql <> '')
  SET @sql_str = @sql_str + N' WHERE (' + @where_sql + N')'
IF (@officer_id IS NOT NULL) AND (@where_sql <> '')
  SET @sql_str = @sql_str + N' AND (' + @where_sql + N')'

SET @sql_str = @sql_str + N' ORDER BY A.DID'
EXEC sp_executesql @sql_str, N'@officer_id int', @officer_id
RETURN (0)


GO
