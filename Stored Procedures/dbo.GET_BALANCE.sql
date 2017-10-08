SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_BALANCE]
  @start_date 	smalldatetime,
  @end_date 	smalldatetime,
  @iso 		TISO = '***',
  @equ 		bit = 1,
  @branch_str   varchar(255) = '',
  @shadow_level smallint = -1,
  @is_lat 	bit = 0,
  @oob 		tinyint = 0,
  @tmptblname	sysname = ''
AS

SET NOCOUNT ON

DECLARE
  @sql_str nvarchar(4000),
  @lat_str nvarchar(4)

IF @is_lat <> 0 SET @lat_str = N'_LAT' ELSE SET @lat_str = N''

CREATE TABLE #TmpN (BAL_ACC decimal(6,2) PRIMARY KEY, D money, C money)

EXEC dbo._GET_BALANCE_DT @start_balance = 1, @dt = @start_date, @iso = @iso, @equ = @equ, 
  @branch_str = @branch_str, @shadow_level = @shadow_level, @oob = @oob, @group_by = 'A.BAL_ACC', @table_name = '#TmpN'

CREATE TABLE #TmpK (BAL_ACC decimal(6,2) PRIMARY KEY, D money, C money)

EXEC dbo._GET_BALANCE_DT @start_balance = 0, @dt = @end_date, @iso = @iso, @equ = @equ, 
  @branch_str = @branch_str, @shadow_level = @shadow_level, @oob = @oob, @group_by = 'A.BAL_ACC', @table_name = '#TmpK'

CREATE TABLE #TmpO (BAL_ACC decimal(6,2), D money, C money)

EXEC dbo._GET_TURNS_DT @start_date = @start_date, @end_date = @end_date, @iso = @iso, @equ = @equ, 
  @branch_str = @branch_str, @shadow_level = @shadow_level, @oob = @oob, @group_by = 'A.BAL_ACC', @table_name = '#TmpO'

SELECT ISNULL(a.BAL_ACC,k.BAL_ACC) AS BAL_ACC,a.DBN,a.CRN,a.DBO,a.CRO,k.D AS DBK, k.C AS CRK
INTO #Tmp
FROM (SELECT ISNULL(n.BAL_ACC,o.BAL_ACC) AS BAL_ACC,n.D AS DBN, n.C AS CRN, o.D AS DBO, o.C AS CRO      FROM #TmpN n FULL OUTER JOIN #TmpO o ON n.BAL_ACC = o.BAL_ACC) a
FULL OUTER JOIN #TmpK k ON a.BAL_ACC = k.BAL_ACC

DROP TABLE #TmpO
DROP TABLE #TmpK
DROP TABLE #TmpN

SET @sql_str = 
  N'SELECT b.*,p.ACT_PAS,p.DESCRIP'+@lat_str+ N' AS DESCRIP' + char(13)

IF @tmptblname <> '' 
  SET @sql_str = @sql_str + N' INTO ' + @tmptblname + char(13)
  
SET @sql_str = @sql_str + 
  N'FROM #Tmp b INNER JOIN dbo.PLANLIST_ALT p(NOLOCK) ON b.BAL_ACC=p.BAL_ACC' + char(13) +
  N'ORDER BY 1'

EXEC sp_executesql @sql_str

DROP TABLE #Tmp
GO
