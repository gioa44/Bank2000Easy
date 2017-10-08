SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[_GET_BALANCE_AVG]
  @start_balance  bit = 0,
  @start_date smalldatetime,
  @end_date smalldatetime,
  @iso 		TISO = '***',
  @equ 		bit = 1,
  @branch_str  varchar(255) = '',  
  @oob 		tinyint = 0,
  @group_by     varchar(255) = 'A.BAL_ACC',
  @group_field_list_def varchar(100) = ', BAL_ACC decimal(6, 2)',
  @table_name   varchar(100) = '#Tmp'
AS

SET NOCOUNT ON

DECLARE 
 @dt smalldatetime,
 @day_diff int,
 @_table_name sysname,
 @sql nvarchar(4000)		

 SET @dt = @start_date
 SET @day_diff = 0
 SET @_table_name = QUOTENAME('##ba_' + CONVERT(varchar(50),NEWID()))

 SET @sql = N'CREATE TABLE ' + @_table_name + '(D money, C money' + @group_field_list_def + ')'

 EXEC sp_executesql @sql
  
 WHILE (@dt <= @end_date)
 BEGIN 
  EXEC dbo._GET_BALANCE_DT_NEW @start_balance, @dt, @iso, @equ, @branch_str, default, @oob, @group_by, @_table_name
  SET @dt = DATEADD(day, 1, @dt)
  SET @day_diff = @day_diff + 1 
 END

 SET @sql = N'INSERT INTO ' + @table_name + char(13) +
	N'SELECT SUM(D) / @day_diff, SUM(C) / @day_diff, ' + @group_by + char(13) +
    N'FROM ' + @_table_name + ' A' + char(13) +
    N'GROUP BY ' + @group_by

 EXEC sp_executesql @sql, N'@day_diff int', @day_diff 

 SET @sql = N'DROP TABLE ' + @_table_name
 EXEC sp_executesql @sql
GO
