SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[show_balance_gel_val]
	@end_date smalldatetime,
	@branch_str varchar(255) = '',
	@shadow_level smallint = -1,
	@is_lat bit = 0,
	@oob tinyint = 0,
	@tmptblname sysname = '',
	@user_id int = null
AS

SET NOCOUNT ON

DECLARE 
	@sql_str nvarchar(4000),
	@lat_str nvarchar(4)

IF @is_lat <> 0 SET @lat_str = N'_LAT' ELSE SET @lat_str = N''

IF @shadow_level >= 0
BEGIN
	CREATE TABLE #shadow_balance 
	(
		DT smalldatetime NOT NULL,
		BRANCH_ID int NOT NULL,
		DEPT_NO int NOT NULL,
		BAL_ACC decimal(6,2) NOT NULL,
		ISO char(3) collate database_default NOT NULL,
		DBO money NOT NULL,
		CRO money NOT NULL,
		DBS money NOT NULL,
		CRS money NOT NULL,
		PRIMARY KEY (DT, BRANCH_ID, DEPT_NO, BAL_ACC, ISO)
	)

	EXEC dbo.SYS_BUILD_SHADOW_BALANCE @end_date, '***', 1, @branch_str, @shadow_level, @oob
END


CREATE TABLE #TmpGel (D money, C money, BAL_ACC decimal(6,2) PRIMARY KEY)

EXEC dbo.show_balance_balances_dt @user_id = @user_id, @start_balance = 0, @dt = @end_date, @iso = 'GEL', @equ = 1, 
  @branch_str = @branch_str, @shadow_level = @shadow_level, @oob = @oob, @group_by = 'A.BAL_ACC', @table_name = '#TmpGel'

CREATE TABLE #TmpVal (D money, C money, BAL_ACC decimal(6,2) PRIMARY KEY)

EXEC dbo.show_balance_balances_dt @user_id = @user_id, @start_balance = 0, @dt = @end_date, @iso = '%%%', @equ = 1, 
  @branch_str = @branch_str, @shadow_level = @shadow_level, @oob = @oob, @group_by = 'A.BAL_ACC', @table_name = '#TmpVal'

SELECT A.BAL_ACC,SUM(A.D) AS DBK, SUM(A.D_EQU) AS DBK_EQU,SUM(A.C) AS CRK, SUM(A.C_EQU) AS CRK_EQU
INTO #Tmp
FROM (
  SELECT BAL_ACC, D, C, $0 AS D_EQU, $0 AS C_EQU 
  FROM #TmpGel 
  
  UNION ALL 
 
  SELECT BAL_ACC, $0, $0, D AS D_EQU, C AS C_EQU 
  FROM #TmpVal) A
GROUP BY BAL_ACC

DROP TABLE #TmpGel
DROP TABLE #TmpVal


SET @sql_str = 
  N'SELECT b.*, p.ACT_PAS, p.DESCRIP' + @lat_str + N' AS DESCRIP' + char(13)

IF @tmptblname <> '' 
  SET @sql_str = @sql_str + N' INTO ' + @tmptblname
  
SET @sql_str = @sql_str + 
  N'FROM #Tmp b INNER JOIN dbo.PLANLIST_ALT p(NOLOCK) ON b.BAL_ACC=p.BAL_ACC' + char(13) +
  N'ORDER BY 1'

EXEC sp_executesql @sql_str

DROP TABLE #Tmp
GO
