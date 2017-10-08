SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[_GET_BALANCE_DT_BRANCH]
	@bal_acc TBAL_ACC,
	@start_balance bit = 0,
	@dt smalldatetime,
	@iso TISO = '***',
	@equ bit = 1,
	@branch_str varchar(255) = ''
AS

SET NOCOUNT ON

DECLARE
  @sql_str nvarchar(4000),

  @iso_where_str nvarchar(20)

IF @start_balance = 1
  SET @dt = @dt - 1

SET @branch_str = ISNULL(@branch_str, '')

IF @iso = '***' /* Svodni */
  SET @iso_where_str = N''
ELSE IF @iso = '%%%' /* Valuta */
  SET @iso_where_str = N'(A.ISO<>''GEL'') AND '
ELSE SET @iso_where_str = N'(A.ISO='''+@iso+N''') AND '

CREATE TABLE #TmpB (BRANCH_ID int PRIMARY KEY, D money, C money)

SET @sql_str = 
  N'INSERT INTO #TmpB' + char(13) +
  N'SELECT A.BRANCH_ID,SUM(A.DBS),SUM(A.CRS)' + char(13) +
  N'FROM dbo.BALANCES' + CASE WHEN @equ <> 0 THEN N'_EQU' ELSE N'' END + N' A(NOLOCK)' + char(13) +
  N'  INNER JOIN dbo.PLANLIST_ALT P(NOLOCK)ON P.BAL_ACC=A.BAL_ACC' + char(13) +
  N'  INNER JOIN dbo.fn_split_list_int (@branch_list, '','') L ON L.[ID]=A.BRANCH_ID' + char(13) +
  N'WHERE A.BAL_ACC=@bal_acc AND ' + @iso_where_str + N' A.DT=@dt' + char(13) +
  N'GROUP BY A.BRANCH_ID'

EXEC sp_executesql @sql_str, N'@dt smalldatetime,@bal_acc decimal(6,2),@branch_list varchar(255)',@dt,@bal_acc,@branch_str

SELECT * FROM #TmpB
ORDER BY BRANCH_ID

DROP TABLE #TmpB
GO
