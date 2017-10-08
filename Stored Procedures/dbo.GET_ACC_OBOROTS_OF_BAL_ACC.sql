SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_ACC_OBOROTS_OF_BAL_ACC]
  @bal_acc_min TBAL_ACC,
  @bal_acc_max TBAL_ACC,
  @iso TISO = '***',
  @branch_str varchar(8000) = '',
  @start_date smalldatetime,
  @end_date	smalldatetime,
  @equ bit = 0,
  @shadow_level smallint = -1,
  @user_id int = 0
AS

SET NOCOUNT ON

SET @branch_str = ISNULL(@branch_str, '')

DECLARE
  @sql nvarchar(4000),
  @iso_where_str nvarchar(30)


IF @iso = '***' /* Svodni */
  SET @iso_where_str = N''
ELSE 
IF @iso = '%%%' /* Valuta */
  SET @iso_where_str = N' AND A.ISO<>''GEL'''
ELSE 
  SET @iso_where_str = N' AND A.ISO=''' + @iso + N''''

SET @sql = 
	N'DECLARE @branches TABLE ([ID] int PRIMARY KEY CLUSTERED)' + char(13) +
	N'INSERT INTO @branches SELECT D.DEPT_NO FROM dbo.DEPTS D INNER JOIN dbo.fn_split_list_int (@branch_list, '','') L ON D.DEPT_NO = L.[ID]' + char(13) +

	N'DECLARE @tbl TABLE (ACC_ID int PRIMARY KEY)' + char(13) +
	N'DECLARE @tbl_turns TABLE (ACC_ID int PRIMARY KEY, SALDO_START money, DBO money, CRO money, SALDO_END money)' + char(13) +

	N'INSERT INTO @tbl' + char(13) +
	N'SELECT A.ACC_ID' + char(13) +
	N'FROM dbo.ACCOUNTS A (NOLOCK)' + char(13) +
	N'  INNER JOIN @branches B ON B.[ID] = A.BRANCH_ID' + char(13) +
	N'WHERE A.BAL_ACC_ALT BETWEEN @bal_acc_min AND @bal_acc_max' + @iso_where_str + char(13) +

	N'DECLARE @acc_id int' + char(13) +
	N'DECLARE cc CURSOR LOCAL FAST_FORWARD FOR SELECT ACC_ID FROM @tbl FOR READ ONLY' + char(13) +
	N'OPEN cc' + char(13) +

	N'FETCH NEXT FROM cc INTO @acc_id' + char(13) +

	N'WHILE @@FETCH_STATUS = 0' + char(13) +
	N'BEGIN' + char(13) +
	N'INSERT INTO @tbl_turns' + char(13) +
	N'SELECT @acc_id, *' + char(13) +
	N'FROM dbo.acc_show_turn (@acc_id, @start_date, @end_date, @equ, @shadow_level)' + char(13) +
  
	N'FETCH NEXT FROM cc INTO @acc_id' + char(13) +
	N'END' + char(13) +
		
	N'CLOSE cc' + char(13) +
	N'DEALLOCATE cc' + char(13) +
 
	N'SELECT A.ACC_ID, DP.ALIAS AS BRANCH_ALIAS, A.ACCOUNT, A.ISO, A.DESCRIP, A.ACT_PAS, T.DBO, T.CRO, T.SALDO_END AS SALDO' + char(13) +
	N'FROM @tbl_turns T' + char(13) +
	N'  INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = T.ACC_ID' + char(13) +
	N'  LEFT JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = A.DEPT_NO' + char(13)

EXEC sp_executesql @sql, N'@start_date smalldatetime,@end_date smalldatetime,@equ bit,@shadow_level smallint,@branch_list varchar(255),@bal_acc_min decimal(6,2),@bal_acc_max decimal(6,2)',@start_date,@end_date,@equ,@shadow_level,@branch_str,@bal_acc_min,@bal_acc_max
GO
