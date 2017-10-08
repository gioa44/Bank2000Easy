SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GET_BALANCE_TREE_2]
  @end_date 	smalldatetime,
  @iso 		TISO = '***',
  @equ 		bit = 1,
  @branch_str   varchar(255) = '',
  @shadow_level smallint = -1,
  @is_lat 	bit = 0,
  @oob 		tinyint = 0
AS

SET NOCOUNT ON

DECLARE @tmp_tbl_name sysname

SET @tmp_tbl_name = QUOTENAME('##' + CONVERT(varchar(255),NEWID()))

EXEC dbo.GET_BALANCE_2 @end_date,@iso,@equ,@branch_str,@shadow_level,@is_lat,@oob,@tmp_tbl_name

DECLARE @oob_sign varchar(1)

IF @oob <> 2  -- not out of bal
     SET @oob_sign = ''
ELSE SET @oob_sign = '-'

EXEC (
'SELECT d.BAL_ACC AS SECTION,c.BAL_ACC AS [CLASS],b.BAL_ACC AS [GROUP],a.BAL_ACC, 
  SUM(a.DBK) AS DBK, SUM(a.CRK) AS CRK, 
  CASE WHEN GROUPING(a.BAL_ACC) = 0 THEN (SELECT ACT_PAS FROM ' + @tmp_tbl_name + ' WHERE BAL_ACC=a.BAL_ACC) ELSE NULL END AS ACT_PAS,
  CASE WHEN GROUPING(a.BAL_ACC) = 0 THEN (SELECT DESCRIP FROM ' + @tmp_tbl_name + ' WHERE BAL_ACC=a.BAL_ACC) ELSE 
    CASE WHEN GROUPING(b.BAL_ACC) = 0 THEN (SELECT DESCRIP FROM BAL_TREE WHERE BAL_ACC='+@oob_sign+'b.BAL_ACC) ELSE 
      CASE WHEN GROUPING(c.BAL_ACC) = 0 THEN (SELECT DESCRIP FROM BAL_TREE WHERE BAL_ACC=c.BAL_ACC) ELSE 
        CASE WHEN GROUPING(d.BAL_ACC) = 0 THEN (SELECT DESCRIP FROM BAL_TREE WHERE BAL_ACC='+@oob_sign+'d.BAL_ACC) ELSE NULL
        END
      END
    END
  END AS DESCRIP
FROM ' + @tmp_tbl_name + ' a, BAL_TREE b, BAL_TREE c, BAL_TREE d
WHERE FLOOR(a.BAL_ACC/10)='+@oob_sign+'b.BAL_ACC AND FLOOR(a.BAL_ACC/100)='+@oob_sign+'c.BAL_ACC AND d.BAL_ACC=c.BAL_ACC_PARENT
GROUP BY d.BAL_ACC,c.BAL_ACC,b.BAL_ACC,a.BAL_ACC WITH ROLLUP
ORDER BY SECTION,CLASS,[GROUP]')

EXEC('DROP TABLE ' + @tmp_tbl_name)

GO
