SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOAN_ACCRUAL_LIST]
	@responsible_user_id int = NULL,
	@eng_version bit = 0,
	@where_sql_1 varchar(255) = NULL, @where_sql_2 varchar(255) = NULL, @where_sql_3 varchar(255) = NULL, @where_sql_4 varchar(255) = NULL, @where_sql_5 varchar(255) = NULL,
	@where_sql_6 varchar(255) = NULL, @where_sql_7 varchar(255) = NULL, @where_sql_8 varchar(255) = NULL, @where_sql_9 varchar(255) = NULL, @where_sql_10 varchar(255) = NULL
AS
SET NOCOUNT ON
DECLARE  @where_sql nvarchar(2550)
DECLARE @sql_str nvarchar(4000)

SET 
  @where_sql = 
    ISNULL(@where_sql_1, '') + ISNULL(@where_sql_2, '') + ISNULL(@where_sql_3, '') + ISNULL(@where_sql_4, '')  + ISNULL(@where_sql_5, '') + 
    ISNULL(@where_sql_6, '') + ISNULL(@where_sql_7, '') + ISNULL(@where_sql_8, '') + ISNULL(@where_sql_9, '') + ISNULL(@where_sql_10, '')
SET @sql_str = N'SELECT A.LOAN_ID,A.AGREEMENT_NO,A.CLIENT_NO,' + NCHAR(13)
SET @sql_str = @sql_str + N'convert(bit,0) CALCED,convert(bit,NULL) ACCRUE_ADMIN_FEE,convert(bit,NULL) ACCRUE_INTEREST,convert(bit,NULL) ACCRUE_PENALTY_INTEREST,convert(bit,NULL) ACCRUE_PENALTY30_INTEREST,' + CHAR(13)
SET @sql_str = @sql_str + N'B.ADMIN_FEE_DATE,B.ADMIN_FEE_BALANCE,convert(money,NULL) ADMIN_FEE_BALANCE_,convert(money,NULL) ADMIN_FEE2ACCRUE,' + CHAR(13)
SET @sql_str = @sql_str + N'B.INTEREST_DATE,B.INTEREST_BALANCE,convert(money,NULL) INTEREST_BALANCE_,convert(money,NULL) INTEREST2ACCRUE,' + NCHAR(13)
SET @sql_str = @sql_str + N'B.PENALTY_DATE,B.PENALTY_BALANCE,convert(money,NULL) PENALTY_BALANCE_,convert(money,NULL) PENALTY_INTEREST2ACCRUE,' + NCHAR(13)
SET @sql_str = @sql_str + N'B.PENALTY30_DATE,B.PENALTY30_BALANCE,convert(money,NULL) PENALTY30_BALANCE_,convert(money, NULL) PENALTY30_INTEREST2ACCRUE,' + NCHAR(13)
SET @sql_str = @sql_str + N'ISNULL(ADMIN_FEE_BALANCE,$0.00)+ISNULL(B.INTEREST_BALANCE,$0.00)+ISNULL(B.PENALTY_BALANCE,$0.00)+ISNULL(B.PENALTY30_BALANCE,$0.00) BALANCE, convert(money,NULL) BALANCE_,' + NCHAR(13)
SET @sql_str = @sql_str + N'convert(varchar(255), NULL) ERROR' + NCHAR(13)
SET @sql_str = @sql_str + N'FROM dbo.LOAN_VW_LOANS A (NOLOCK)' + NCHAR(13)
SET @sql_str = @sql_str + N'LEFT OUTER JOIN dbo.LOAN_ACCOUNT_BALANCE B (NOLOCK) ON A.LOAN_ID=B.LOAN_ID' + NCHAR(13)

SET @where_sql = ISNULL(@where_sql, '')

IF @responsible_user_id IS NOT NULL
  SET @sql_str = @sql_str + N'WHERE (A.RESPONSIBLE_USER_ID=@responsible_user_id OR A.RESPONSIBLE_USER_ID IN (SELECT USER_ID_2 FROM dbo.USER_RELATIONS (NOLOCK) WHERE USER_ID=@responsible_user_id AND FLAGS&8<>0))' + NCHAR(13)

IF (@where_sql <> '')
  SET @sql_str = @sql_str + CASE WHEN @responsible_user_id IS NULL THEN N'WHERE ' ELSE N'AND ' END + N'(' + @where_sql + N')' + NCHAR(13)

SET @sql_str = @sql_str + N'ORDER BY A.LOAN_ID'
EXEC sp_executesql @sql_str, N'@responsible_user_id int', @responsible_user_id
RETURN (0)
GO
