SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[_GET_TURNS_DT_BRANCH]
	@bal_acc TBAL_ACC,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@iso TISO = '***',
	@equ bit = 1,
	@branch_str varchar(255) = ''
AS

SET NOCOUNT ON

DECLARE
  @sql_str nvarchar(4000),
  @equ_str nvarchar(4),
  @iso_where_str nvarchar(20)

SET @branch_str = ISNULL(@branch_str, '')

IF @equ <> 0 SET @equ_str = N'_EQU' ELSE SET @equ_str = N''

IF @iso = '***' /* Svodni */
  SET @iso_where_str = N''
ELSE IF @iso = '%%%' /* Valuta */
  SET @iso_where_str = N'(A.ISO<>''GEL'') AND '
ELSE SET @iso_where_str = N'(A.ISO='''+@iso+N''') AND '

CREATE TABLE #TmpT (BRANCH_ID int PRIMARY KEY, D money, C money)

SET @sql_str = 
  N'INSERT INTO #TmpT' + char(13) +
  N'SELECT A.BRANCH_ID,SUM(A.DBO),SUM(A.CRO)' + char(13) +
  N'FROM dbo.BALANCES' + CASE WHEN @equ <> 0 THEN N'_EQU' ELSE N'' END + N' A(NOLOCK)' + char(13) +
  N'  INNER JOIN dbo.PLANLIST_ALT P(NOLOCK)ON P.BAL_ACC=A.BAL_ACC' + char(13) +
  N'  INNER JOIN dbo.fn_split_list_int (@branch_list, '','') L ON L.[ID]=A.BRANCH_ID' + char(13) +
  N'WHERE A.BAL_ACC=@bal_acc AND ' + @iso_where_str + N' A.DT BETWEEN @start_date AND @end_date' + char(13) +

  N'GROUP BY A.BRANCH_ID'

EXEC sp_executesql @sql_str, N'@start_date smalldatetime,@end_date smalldatetime,@bal_acc decimal(6,2),@branch_list varchar(255)',@start_date,@end_date,@bal_acc,@branch_str

SELECT * 
FROM #TmpT
ORDER BY BRANCH_ID

DROP TABLE #TmpT
GO
