SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[LOAN_SP_GET_RISK_ACCRUAL_LIST]
  @where_sql_1 varchar(255) = '', @where_sql_2 varchar(255) = '', @where_sql_3 varchar(255) = '', @where_sql_4 varchar(255) = '', @where_sql_5 varchar(255) = '',
  @where_sql_6 varchar(255) = '', @where_sql_7 varchar(255) = '', @where_sql_8 varchar(255) = '', @where_sql_9 varchar(255) = '', @where_sql_10 varchar(255) = '',
  @where_sql_11 varchar(255) = '', @where_sql_12 varchar(255) = ''
AS

SET NOCOUNT ON
DECLARE  @where_sql nvarchar(3060)
DECLARE @sql_str nvarchar(4000)

SET 
  @where_sql = 
    ISNULL(@where_sql_1, '') + ISNULL(@where_sql_2, '') + ISNULL(@where_sql_3, '') + ISNULL(@where_sql_4, '')  + ISNULL(@where_sql_5, '') + 
    ISNULL(@where_sql_6, '') + ISNULL(@where_sql_7, '') + ISNULL(@where_sql_8, '') + ISNULL(@where_sql_9, '') + ISNULL(@where_sql_10, '') +
    ISNULL(@where_sql_11, '') + ISNULL(@where_sql_12, '')
SET @sql_str = 'SELECT L.STATE, A.* FROM dbo.LOAN_VW_RISK_ACCRUAL_LIST A (NOLOCK) INNER JOIN dbo.LOANS L ON L.LOAN_ID=A.LOAN_ID'

SET @where_sql = ISNULL(@where_sql, '')


IF @where_sql <> ''
	SET @sql_str = @sql_str + N' WHERE (' + @where_sql + N')'
ELSE
	SET @sql_str = @sql_str + N' WHERE (L.STATE NOT IN (dbo.loan_const_state_closed(), dbo.loan_const_state_writedoff()))'

--Start Internal Change	
SET @sql_str = @sql_str + N' AND L.REG_DATE >= ''20101001'' AND L.PRODUCT_ID NOT IN (7,14,16,18,19)'
--End Internal Change	

	
SET @sql_str = @sql_str + N' ORDER BY A.LOAN_ID'
EXEC sp_executesql @sql_str
RETURN (0)

GO
