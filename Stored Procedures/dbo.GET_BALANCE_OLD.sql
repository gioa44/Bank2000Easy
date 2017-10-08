SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_BALANCE_OLD]
  @is_alt	bit = 0,
  @end_date	smalldatetime,
  @iso TISO = '***',
  @equ bit = 1,
  @shadow_level smallint = -1,
  @is_lat bit = 0,
  @oob tinyint = 0,
  @tmptblname sysname = ''
AS

SET NOCOUNT ON


DECLARE
  @sql nvarchar(4000),
  @iso_where_str nvarchar(20),
  @oob_where_str nvarchar(20)


IF @iso = '***' /* Svodni */
  SET @iso_where_str = N''
ELSE
IF @iso = '%%%' /* Valuta */
  SET @iso_where_str = N' AND A.ISO<>''GEL'''
ELSE
  SET @iso_where_str = N' AND A.ISO=''' + @iso + N''''

IF @oob = 1      SET @oob_where_str = N'A.BAL_ACC_ALT>=1000'
ELSE IF @oob = 2 SET @oob_where_str = N'A.BAL_ACC_ALT<1000'
ELSE             SET @oob_where_str = N''

SET @sql = N'
	SELECT A.BAL_ACC' + CASE WHEN @is_alt <> 0 THEN '_ALT' ELSE '_OLD' END + N' AS BAL_ACC,SUM(BALANCE_DEBIT) AS DBK,SUM(BALANCE_CREDIT) AS CRK
	INTO #Tmp
	FROM dbo.ACCOUNTS A (NOLOCK) INNER JOIN dbo.acc_show_all_balances2(@end_date, 0, @equ, @shadow_level) B ON B.ACC_ID=A.ACC_ID
	WHERE ' + @oob_where_str + @iso_where_str + N'
	GROUP BY A.BAL_ACC' + CASE WHEN @is_alt <> 0 THEN '_ALT' ELSE '_OLD' END

SET @sql = @sql +N'

	SELECT b.*, p.ACT_PAS, p.DESCRIP' + CASE WHEN @is_lat <> 0 THEN '_LAT' ELSE '' END + N' AS DESCRIP'

IF @tmptblname <> '' 
  SET @sql = @sql + N' INTO ' + @tmptblname
  
SET @sql = @sql + N'
	FROM #Tmp b,PLANLIST' + CASE WHEN @is_alt <> 0 THEN '_ALT' ELSE '' END + N' p WHERE b.BAL_ACC=p.BAL_ACC
	DROP TABLE #Tmp'
--print @sql
exec sp_executesql @sql, N'@end_date smalldatetime,@shadow_level int,@equ bit',@end_date,@shadow_level,@equ
GO
