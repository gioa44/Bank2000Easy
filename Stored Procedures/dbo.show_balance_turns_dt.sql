SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[show_balance_turns_dt]
	@start_date smalldatetime,
	@end_date smalldatetime,
	@iso TISO = '***',
	@equ bit = 1,
	@branch_str varchar(255) = '0',
	@shadow_level smallint = -1,
	@oob tinyint = 0,
	@group_by varchar(255) = 'A.BAL_ACC',
	@table_name varchar(100) = '#balance',
	@shadow_balance_table_name varchar(100) = '#shadow_balance',
	@user_id int = null
AS

SET NOCOUNT ON

DECLARE
	@sql nvarchar(4000),
	@iso_where_str nvarchar(30),
	@oob_where_str nvarchar(30)

SET @branch_str = ISNULL(@branch_str, '')

IF @iso = '***' /* Svodni */
	SET @iso_where_str = N''
ELSE 
IF @iso = '%%%' /* Valuta */
	SET @iso_where_str = N' AND A.ISO<>''GEL'''
ELSE 
	SET @iso_where_str = N' AND A.ISO=''' + @iso + N''''

IF @oob = 1
	SET @oob_where_str = N' AND A.BAL_ACC>=1000'
ELSE 
IF @oob = 2 
	SET @oob_where_str = N' AND A.BAL_ACC<1000'
ELSE
	SET @oob_where_str = N''

DECLARE @open_dt smalldatetime
SET @open_dt = dbo.bank_open_date()

IF @shadow_level >= 0 AND @end_date < @open_dt 
	SET @shadow_level = -1

SET @sql = 
	N'DECLARE @branches TABLE ([ID] int PRIMARY KEY CLUSTERED)' + char(13) +
	N'INSERT INTO @branches SELECT D.DEPT_NO FROM dbo.DEPTS D INNER JOIN dbo.fn_split_list_int (@branch_list, '','') L ON D.DEPT_NO = L.[ID];' + char(13)

IF @user_id IS NOT NULL
	SET @sql = @sql +
		N'DECLARE @bal_accs TABLE ([BAL_ACC] decimal(6,2) PRIMARY KEY CLUSTERED)' + char(13) +
		N'INSERT INTO @bal_accs EXEC dbo.bal_acc_show_bal_accounts @user_id=@user_id, @field_list=''BAL_ACC'';' + char(13)

SET @sql = @sql +
	N'WITH A AS (SELECT * FROM dbo.BALANCES' + CASE WHEN @equ = 0 THEN N'' ELSE N'_EQU' END + N' A(NOLOCK)' +
	CASE WHEN @shadow_level < 0 THEN '' ELSE ' UNION ALL SELECT * FROM ' + @shadow_balance_table_name END + ')' + char(13) +
	N'INSERT INTO ' + @table_name + char(13)

IF @user_id IS NOT NULL
	SET @sql = @sql + N'  SELECT A.* FROM (' + char(13)

SET @sql = @sql + 
	N'SELECT SUM(A.DBO) AS DBO,SUM(A.CRO) AS CRO,' + @group_by + char(13) +
	N'FROM A' + char(13) +
	N' INNER JOIN @branches B ON B.[ID] = A.BRANCH_ID' + char(13)

SET @sql = @sql + 
	N'WHERE A.DT BETWEEN @start_date AND @end_date' + @oob_where_str + @iso_where_str + char(13) +
	N'GROUP BY ' + @group_by

IF @user_id IS NOT NULL
	SET @sql = @sql + N') A INNER JOIN @bal_accs ba ON ba.BAL_ACC=A.BAL_ACC' + char(13)

print @sql
EXEC sp_executesql @sql, N'@start_date smalldatetime,@end_date smalldatetime,@branch_list varchar(255),@user_id int',@start_date, @end_date, @branch_str, @user_id
GO
