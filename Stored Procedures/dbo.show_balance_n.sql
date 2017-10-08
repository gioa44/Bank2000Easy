SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--
-- Shows balance for different chart of accounts. Real time calculation is done, so it's quite slow
--
-- @chart_no = 0 - Real chart of account
-- @chart_no = 1 - Old (#1) chart of account
-- @chart_no = 2 - #2 chart of account
-- @chart_no = 3 - #3 chart of account
--
CREATE PROCEDURE [dbo].[show_balance_n]
	@chart_no int = 0,
	@end_date smalldatetime,
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
	@iso_where_str nvarchar(30),
	@oob_where_str nvarchar(50),
	@bal_field_suffix nvarchar(10),
	@bal_table_suffix nvarchar(10)

IF @iso = '***' /* Svodni */
  SET @iso_where_str = N''
ELSE
IF @iso = '%%%' /* Valuta */
  SET @iso_where_str = N' AND A.ISO<>''GEL'''
ELSE
  SET @iso_where_str = N' AND A.ISO=''' + @iso + N''''

IF @oob = 1      SET @oob_where_str = N' AND A.BAL_ACC_ALT>=1000'
ELSE IF @oob = 2 SET @oob_where_str = N' AND A.BAL_ACC_ALT<1000'
ELSE             SET @oob_where_str = N''

IF @chart_no = 0
BEGIN
	SET @bal_field_suffix = '_ALT'
	SET @bal_table_suffix = '_ALT'
END
ELSE
IF @chart_no = 1
BEGIN
	SET @bal_field_suffix = '_OLD'
	SET @bal_table_suffix = ''
END
ELSE
IF @chart_no = 2
BEGIN
	SET @bal_field_suffix = '2'
	SET @bal_table_suffix = '2'
END
ELSE
IF @chart_no = 3
BEGIN
	SET @bal_field_suffix = '3'
	SET @bal_table_suffix = '3'
END


SET @sql = N'
DECLARE @bal TABLE (BAL_ACC TBAL_ACC, DBK money, CRK money)
DECLARE @bal2 TABLE (BAL_ACC TBAL_ACC, DBK money, CRK money)

INSERT INTO @bal2
SELECT A.BAL_ACC' + @bal_field_suffix + ' AS BAL_ACC, SUM(BALANCE_DEBIT) AS DBK, SUM(BALANCE_CREDIT) AS CRK
FROM dbo.ACCOUNTS A (NOLOCK)
	INNER JOIN dbo.acc_show_all_balances2(@end_date, 0, @equ, @shadow_level) B ON B.ACC_ID=A.ACC_ID
WHERE A.BAL_ACC' + @bal_field_suffix + ' IS NOT NULL ' + @oob_where_str + @iso_where_str + N'
GROUP BY A.BAL_ACC' + @bal_field_suffix + '

INSERT INTO @bal2
SELECT A.BAL_ACC_DEBIT, SUM(A.AMOUNT' + CASE WHEN @equ = 1 THEN '_EQU' ELSE '' END + '), 0
FROM dbo.BAL_OPS A
WHERE A.CHART_NO=' + CONVERT(char(1),@chart_no) + ' AND A.DOC_DATE<=@end_date ' + @iso_where_str + N'
GROUP BY A.BAL_ACC_DEBIT

INSERT INTO @bal2
SELECT A.BAL_ACC_CREDIT, 0, SUM(A.AMOUNT' + CASE WHEN @equ = 1 THEN '_EQU' ELSE '' END + ')
FROM dbo.BAL_OPS A
WHERE A.CHART_NO=' + CONVERT(char(1),@chart_no) + ' AND A.DOC_DATE<=@end_date ' + @iso_where_str + N'
GROUP BY A.BAL_ACC_CREDIT

INSERT INTO @bal
SELECT BAL_ACC, SUM(DBK), SUM(CRK)
FROM @bal2
GROUP BY BAL_ACC

SELECT B.*, P.ACT_PAS, P.DESCRIP' + CASE WHEN @is_lat <> 0 THEN '_LAT' ELSE '' END + N' AS DESCRIP'

IF @tmptblname <> '' 
  SET @sql = @sql + N' INTO ' + @tmptblname
  
SET @sql = @sql + N'
FROM @bal B
	INNER JOIN dbo.PLANLIST' + @bal_table_suffix + ' P (NOLOCK) ON P.BAL_ACC = B.BAL_ACC
ORDER BY B.BAL_ACC'

--PRINT @sql
EXEC sp_executesql @sql, N'@end_date smalldatetime,@shadow_level int,@equ bit',@end_date,@shadow_level,@equ
GO
