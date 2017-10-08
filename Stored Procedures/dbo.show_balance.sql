SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[show_balance] (
	@tree bit = 0,
	@group_field_list varchar(1000) = 'BAL_ACC',
	@oob smallint = 1,
	@equ bit = 1,
	@turns bit = 0,
	@start_date smalldatetime = '01/01/2000',
	@end_date smalldatetime = '01/01/2000',
	@iso TISO = '***',
	@branch_str varchar(8000) = '',
	@shadow_level smallint = -1,
	@clean bit = 0,
	@sub_bal_acc bit = 0,
	@is_lat bit = 0,
	@user_id int = null
) 
AS 

SET NOCOUNT ON

SET @branch_str = ISNULL(@branch_str, '')
SET @iso = ISNULL(@iso, '***')

IF ISNULL(@group_field_list, '') = ''
  SET @group_field_list = 'BAL_ACC'

IF @shadow_level >= 0 AND @end_date < dbo.bank_open_date()
 SET @shadow_level = -1

DECLARE @lat_str nvarchar(4)

IF @is_lat <> 0 SET @lat_str = N'_LAT' ELSE SET @lat_str = N''

DECLARE @tbp_param TABLE([ID] varchar(30))

INSERT INTO @tbp_param([ID])
SELECT [ID] 
FROM dbo.fn_split_list_str(@group_field_list, ',')

SELECT @tree = CASE WHEN @tree = 1 AND (NOT EXISTS(SELECT * FROM @tbp_param WHERE [ID] = 'BAL_ACC')) THEN 0 ELSE @tree END

DECLARE
  @tbl_start_table_name sysname,
  @tbl_end_table_name sysname,
  @tbl_turns_table_name sysname,

  @tbl_start_table_name_ sysname,
  @tbl_end_table_name_ sysname,
  @tbl_turns_table_name_ sysname,

  @group_field_list_def  varchar(1000),
  @group_count int,
  @group_fields varchar(2000),
  @field sysname,
  @field_type sysname,
  @rec_info_str varchar(2000)

SET @tbl_start_table_name = '##bs' + REPLACE(CONVERT(varchar(50),NEWID()),'-','')
SET @tbl_end_table_name = '##be' + REPLACE(CONVERT(varchar(50),NEWID()),'-','')
SET @tbl_turns_table_name = '##bt' + REPLACE(CONVERT(varchar(50),NEWID()),'-','')

SET @tbl_start_table_name_ = @tbl_start_table_name + '_'
SET @tbl_end_table_name_ = @tbl_end_table_name + '_'
SET @tbl_turns_table_name_ = @tbl_turns_table_name + '_'

SET @group_field_list_def = ''
SET @group_fields = NULL
SET @rec_info_str = ''
SET @group_count = 0

DECLARE cr CURSOR FOR
SELECT [ID] FROM @tbp_param 

OPEN cr
FETCH NEXT FROM cr INTO @field

WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT @field_type = s.DATA_TYPE + 
    CASE WHEN s.DATA_TYPE in ('char', 'varchar') THEN '(' + CONVERT(varchar(10), s.CHARACTER_MAXIMUM_LENGTH) + ')' ELSE '' END +
    CASE WHEN s.DATA_TYPE in ('decimal', 'numeric') THEN  '(' + CONVERT(varchar(10), s.NUMERIC_PRECISION) + ',' + CONVERT(varchar(10), s.NUMERIC_SCALE) + ')'  ELSE '' END +
    CASE WHEN s.DATA_TYPE in ('float', 'real') THEN  '(' + CONVERT(varchar(10), s.NUMERIC_PRECISION) + ')'  ELSE '' END + ' NOT NULL'
  FROM INFORMATION_SCHEMA.[COLUMNS] s
  WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'BALANCES' AND COLUMN_NAME = @field

  SET @group_field_list_def = @group_field_list_def + ', ' + @field + ' ' + @field_type

  IF @group_fields IS NULL
    SET @group_fields = 'A.' + @field
  ELSE
    SET @group_fields = @group_fields + ',' + 'A.' + @field

  IF @rec_info_str <> '' 
    SET @rec_info_str = @rec_info_str + '+'
  SET @rec_info_str = @rec_info_str + 'GROUPING(A.' + @field + ')' 

  SET @group_count = @group_count + 1

  FETCH NEXT FROM cr INTO @field
END
CLOSE cr
DEALLOCATE cr

IF @rec_info_str <> ''
BEGIN
  IF @tree = 0
    SET @rec_info_str = 
    'CASE ' + @rec_info_str + ' WHEN 0 THEN NULL WHEN ' + CONVERT(varchar(4), @group_count) + ' THEN ''TOTALBOLD'' ELSE ''SUBTOTAL_'' + convert(varchar(2),' + @rec_info_str + ') END AS REC_INFO'
  ELSE
    SET @rec_info_str = 
    'CASE WHEN convert(int,' + @rec_info_str + ') = 0 THEN NULL ELSE' + char(13) + 
    'CASE WHEN GROUPING(D.BAL_ACC) <> 0 AND GROUPING(C.BAL_ACC) <> 0 AND GROUPING(B.BAL_ACC) <> 0 AND CHARINDEX(''0'', convert(varchar(100),' + @rec_info_str + ')) = 0 THEN ''TOTALBOLD'' ELSE' + char(13) +
    'CASE WHEN GROUPING(D.BAL_ACC) = 0 AND GROUPING(C.BAL_ACC) = 0 AND GROUPING(B.BAL_ACC) = 0 AND CHARINDEX(''0'', convert(varchar(100),' + @rec_info_str + ')) <> 0 THEN ''SUBTOTAL_'' + convert(varchar(100),' + @rec_info_str + ') ELSE' + char(13) +
    'CASE WHEN GROUPING(B.BAL_ACC) = 0 THEN ''SUBTOTAL'' ELSE ' + char(13) +
    'CASE WHEN GROUPING(C.BAL_ACC) = 0 THEN ''TOTAL'' ELSE ' + char(13) +
    'CASE WHEN GROUPING(D.BAL_ACC) = 0 THEN ''BLACK'' END END END END END END AS REC_INFO'
END

DECLARE
  @sql nvarchar(4000)

SET @sql = N''

SET @sql = @sql  + 'CREATE TABLE ' + @tbl_start_table_name + '(D money, C money' + @group_field_list_def + ')' + char(13)
SET @sql = @sql  + 'CREATE TABLE ' + @tbl_end_table_name + '(D money, C money' + @group_field_list_def + ')' + char(13)
SET @sql = @sql  + 'CREATE TABLE ' + @tbl_turns_table_name + '(D money, C money' + @group_field_list_def + ')' + char(13) + char(13)

SET @sql = @sql  + 'CREATE TABLE ' + @tbl_start_table_name_ + '(D money, C money' + @group_field_list_def + ')' + char(13)
SET @sql = @sql  + 'CREATE TABLE ' + @tbl_end_table_name_ + '(D money, C money' + @group_field_list_def + ')' + char(13)
SET @sql = @sql  + 'CREATE TABLE ' + @tbl_turns_table_name_ + '(D money, C money' + @group_field_list_def + ')' + char(13) + char(13)


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

	EXEC dbo.SYS_BUILD_SHADOW_BALANCE @end_date, @iso, @equ, @branch_str, @shadow_level, @oob
END

IF @turns = 1
  SET @sql = @sql + 'EXEC dbo.show_balance_balances_dt @user_id = @user_id, @start_balance = 1, @dt = @start_date, @iso = @iso, @equ = @equ,' + 
    '@branch_str = @branch_str, @shadow_level = @shadow_level, @oob = @oob, @group_by = @group_fields, @table_name = ''' + @tbl_start_table_name_ + '''' + char(13)

SET @sql = @sql + 'EXEC dbo.show_balance_balances_dt @user_id = @user_id, @start_balance = 0, @dt = @end_date, @iso = @iso, @equ = @equ,' +
    '@branch_str = @branch_str, @shadow_level = @shadow_level, @oob = @oob, @group_by = @group_fields, @table_name = ''' + @tbl_end_table_name_ + '''' + char(13)

IF @turns = 1
BEGIN
  SET @sql = @sql + 'EXEC dbo.show_balance_turns_dt @user_id = @user_id, @start_date = @start_date, @end_date = @end_date, @iso = @iso, @equ = @equ, ' + 
    '@branch_str = @branch_str, @shadow_level = @shadow_level, @oob = @oob, @group_by = @group_fields, @table_name = ''' + @tbl_turns_table_name_ + '''' + char(13)
END

IF @sub_bal_acc = 1
BEGIN
  SET @sql = @sql + 'INSERT INTO ' + @tbl_start_table_name + char(13)
  SET @sql = @sql + 'SELECT * FROM ' + @tbl_start_table_name_ + char(13)
  SET @sql = @sql + 'INSERT INTO ' + @tbl_end_table_name + char(13)
  SET @sql = @sql + 'SELECT * FROM ' + @tbl_end_table_name_ + char(13)
  SET @sql = @sql + 'INSERT INTO ' + @tbl_turns_table_name + char(13)
  SET @sql = @sql + 'SELECT * FROM ' + @tbl_turns_table_name_ + char(13)
END
ELSE
BEGIN
  SET @sql = @sql + 'UPDATE ' + @tbl_start_table_name_ +' SET BAL_ACC=CAST(BAL_ACC AS smallint)' + char(13)
  SET @sql = @sql + 'UPDATE ' + @tbl_end_table_name_ +' SET BAL_ACC=CAST(BAL_ACC AS smallint)' + char(13)    
  SET @sql = @sql + 'UPDATE ' + @tbl_turns_table_name_ +' SET BAL_ACC=CAST(BAL_ACC AS smallint)' + char(13)  

  SET @sql = @sql + 'INSERT INTO ' + @tbl_start_table_name + ' (D, C,' + @group_field_list + ')' + char(13)
  SET @sql = @sql + 'SELECT SUM(D), SUM(C), ' + @group_field_list + ' FROM ' + @tbl_start_table_name_ + char(13)
  SET @sql = @sql + 'GROUP BY ' + @group_field_list + char(13)

  SET @sql = @sql + 'INSERT INTO ' + @tbl_end_table_name + ' (D, C,' + @group_field_list + ')' + char(13)
  SET @sql = @sql + 'SELECT SUM(D), SUM(C), ' + @group_field_list + ' FROM ' + @tbl_end_table_name_ + char(13)
  SET @sql = @sql + 'GROUP BY ' + @group_field_list + char(13)

  SET @sql = @sql + 'INSERT INTO ' + @tbl_turns_table_name + ' (D, C,' + @group_field_list + ')' + char(13)
  SET @sql = @sql + 'SELECT SUM(D), SUM(C), ' + @group_field_list + ' FROM ' + @tbl_turns_table_name_ + char(13)
  SET @sql = @sql + 'GROUP BY ' + @group_field_list + char(13)
END

--PRINT @sql

IF @clean = 1
BEGIN
  IF @turns = 1
  BEGIN
    SET @sql = @sql + 'UPDATE ' + @tbl_start_table_name + char(13)
    SET @sql = @sql + 'SET D = CASE WHEN D > C THEN D - C ELSE $0.00 END, C = CASE WHEN D < C THEN  -(D - C) ELSE $0.00 END' + char(13)
  END

  SET @sql = @sql + 'UPDATE ' + @tbl_end_table_name + char(13)
  SET @sql = @sql + 'SET D = CASE WHEN D > C THEN D - C ELSE $0.00 END, C = CASE WHEN D < C THEN -(D - C) ELSE $0.00 END' + char(13)
END

--print @sql
EXEC sp_executesql @sql, N'@oob tinyint, @equ bit, @iso char(3), @branch_str varchar(8000), @start_date smalldatetime, @end_date smalldatetime,@shadow_level smallint,@group_fields varchar(2000),@user_id int', 
  @oob, @equ, @iso, @branch_str, @start_date, @end_date, @shadow_level, @group_fields, @user_id 
  
SET @sql = 
	'SELECT ' + @group_fields + ',SUM(A.DBN) AS DBN, SUM(A.CRN) AS CRN, SUM(A.DBO) AS DBO, SUM(A.CRO) AS CRO, SUM(A.DBK) AS DBK, SUM(A.CRK) AS CRK' + char(13) +
	'INTO #tmp' + char(13) +
	'FROM (' + char(13) +
	'SELECT ' + @group_fields + ',$0.00 AS DBN, $0.00 AS CRN, $0.00 AS DBO, $0.00 AS CRO, A.D AS DBK, A.C AS CRK' + char(13) +
	'FROM ' + @tbl_end_table_name + ' A' + char(13) +
	'UNION ALL' + char(13) +
	'SELECT ' + @group_fields + ',D, C, $0.00, $0.00, $0.00, $0.00' + char(13) +
	'FROM ' + @tbl_start_table_name + ' A' + char(13) +
	'UNION ALL' + char(13) +
	'SELECT ' + @group_fields + ',$0.00, $0.00, D, C, $0.00, $0.00' + char(13) +
	'FROM ' + @tbl_turns_table_name + ' A' + char(13) +
	') A' + char(13) +
    'GROUP BY ' + @group_fields + char(13)

IF @tree = 0
  SET @sql = @sql +
	'SELECT ' + @group_fields + ',SUM(A.DBN) AS DBN, SUM(A.CRN) AS CRN, SUM(A.DBO) AS DBO, SUM(A.CRO) AS CRO, SUM(A.DBK) AS DBK, SUM(A.CRK) AS CRK,' + char(13) +
    '  CASE WHEN GROUPING(A.BAL_ACC) = 0 THEN (SELECT ACT_PAS FROM dbo.PLANLIST_ALT C(NOLOCK) WHERE C.BAL_ACC = A.BAL_ACC) ELSE NULL END AS ACT_PAS,' + char(13) +
    '  CASE WHEN GROUPING(A.BAL_ACC) = 0 THEN (SELECT C.DESCRIP' + @lat_str + ' FROM dbo.PLANLIST_ALT C(NOLOCK) WHERE C.BAL_ACC = A.BAL_ACC) ELSE NULL END AS DESCRIP,' + char(13) +
	@rec_info_str + char(13) +
	'FROM #tmp A' + char(13) +
    'GROUP BY ' + @group_fields + ' WITH ROLLUP' + char(13) +
    'ORDER BY ' + @group_fields
ELSE
BEGIN
  DECLARE @oob_sign varchar(1)

  IF @oob <> 2  -- not out of bal
       SET @oob_sign = ''
  ELSE SET @oob_sign = '-'

  SET @sql = @sql +
	'SELECT ' + @group_fields +	',DBN, CRN, DBO, CRO, DBK, CRK, PL.DESCRIP' + @lat_str + ', PL.ACT_PAS' + char(13) +
    'INTO #tmp2' + char(13) +  
    'FROM #tmp A' + char(13) +
    '  INNER JOIN dbo.PLANLIST_ALT PL(NOLOCK) ON PL.BAL_ACC = A.BAL_ACC' + char(13) +

	'SELECT D.BAL_ACC AS SECTION,C.BAL_ACC AS [CLASS],B.BAL_ACC AS [GROUP],' + @group_fields + ',' + char(13) +
	'SUM(A.DBN) AS DBN, SUM(A.CRN) AS CRN, SUM(A.DBO) AS DBO, SUM(A.CRO) AS CRO, SUM(A.DBK) AS DBK, SUM(A.CRK) AS CRK,' + char(13) +
	'CASE WHEN GROUPING(A.BAL_ACC) = 0 THEN (SELECT ACT_PAS FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC=A.BAL_ACC) ELSE NULL END AS ACT_PAS,' + char(13) +
	'CASE WHEN GROUPING(A.BAL_ACC) = 0 THEN (SELECT DESCRIP' + @lat_str + ' FROM dbo.PLANLIST_ALT(NOLOCK) WHERE BAL_ACC=A.BAL_ACC) ELSE' + char(13) +
    'CASE WHEN GROUPING(B.BAL_ACC) = 0 THEN (SELECT DESCRIP' + @lat_str + ' FROM dbo.BAL_TREE(NOLOCK) WHERE BAL_ACC=' + @oob_sign + 'B.BAL_ACC) ELSE' + char(13) +
    '  CASE WHEN GROUPING(C.BAL_ACC) = 0 THEN (SELECT DESCRIP' + @lat_str + ' FROM dbo.BAL_TREE(NOLOCK) WHERE BAL_ACC=C.BAL_ACC) ELSE' + char(13) +
    '    CASE WHEN GROUPING(D.BAL_ACC) = 0 THEN (SELECT DESCRIP' + @lat_str + ' FROM dbo.BAL_TREE(NOLOCK) WHERE BAL_ACC=' + @oob_sign + 'D.BAL_ACC) ELSE NULL END' + char(13) +
    '    END' + char(13) +
    '  END' + char(13) +
    'END AS DESCRIP, ' + @rec_info_str + char(13) +
	'FROM #tmp2 A, dbo.BAL_TREE B(NOLOCK), dbo.BAL_TREE C(NOLOCK), dbo.BAL_TREE D(NOLOCK)' + char(13) +
	'WHERE FLOOR(A.BAL_ACC/10) = B.BAL_ACC AND FLOOR(A.BAL_ACC/100) = C.BAL_ACC AND D.BAL_ACC=C.BAL_ACC_PARENT' + char(13) +
	'GROUP BY D.BAL_ACC,C.BAL_ACC,B.BAL_ACC,' + @group_fields + ' WITH ROLLUP' + char(13) +
	'ORDER BY SECTION,CLASS,[GROUP],' + @group_fields + char(13) +
	'DROP TABLE #tmp2'
END

SET @sql = @sql + '
DROP TABLE #tmp'

--print @sql
EXEC sp_executesql @sql

IF @shadow_level >= 0
	DROP TABLE #shadow_balance 

SET @sql = 'DROP TABLE ' + @tbl_start_table_name + char(13)
SET @sql = @sql + 'DROP TABLE ' + @tbl_end_table_name + char(13)
SET @sql = @sql + 'DROP TABLE ' + @tbl_turns_table_name + char(13)
SET @sql = 'DROP TABLE ' + @tbl_start_table_name_ + char(13)
SET @sql = @sql + 'DROP TABLE ' + @tbl_end_table_name_ + char(13)
SET @sql = @sql + 'DROP TABLE ' + @tbl_turns_table_name_ + char(13)

--print @sql
EXEC sp_executesql @sql
GO
