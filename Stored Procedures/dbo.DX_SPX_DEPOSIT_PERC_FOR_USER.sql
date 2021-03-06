SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DX_SPX_DEPOSIT_PERC_FOR_USER]
  @user_id int,
  @all_recs bit = 0,
  @dt smalldatetime
AS

SET NOCOUNT ON

DECLARE @sql_str nvarchar(2000)

IF @all_recs = 1
BEGIN
  SET @sql_str = 
  'SELECT P.* FROM ACCOUNTS_CRED_PERC P INNER JOIN ACCOUNTS A(NOLOCK) ON A.ACCOUNT=P.ACCOUNT AND A.ISO=P.ISO
   WHERE P.START_DATE<=@dt AND ((P.END_DATE IS NULL OR P.END_DATE>=@dt) OR (P.END_DATE<@dt AND DAY(@dt+1) = 1 AND MONTH(P.END_DATE) = MONTH(@dt) AND YEAR(P.END_DATE) = YEAR(@dt)))'
END

ELSE

BEGIN
  DECLARE @where_sql varchar(255)
  SELECT @where_sql = WHERE_SQL_ACC FROM USER_SQL WHERE USER_ID = @user_id
  SET @where_sql = ISNULL(@where_sql,'')

  SET @sql_str = 
  'SELECT P.* FROM ACCOUNTS_CRED_PERC P(NOLOCK) INNER JOIN ACCOUNTS A(NOLOCK) ON A.ACCOUNT=P.ACCOUNT AND A.ISO=P.ISO AND
    (A.ACCOUNT IN (SELECT ACCOUNT FROM ACCOUNTS_USR WHERE USER_ID=@user_id OR USER_ID IN (SELECT USER_ID_2 FROM USER_RELATIONS WHERE USER_ID=@user_id AND FLAGS & 2 <> 0)))
   WHERE (P.START_DATE<=@dt AND ((P.END_DATE IS NULL OR P.END_DATE>=@dt) OR (P.END_DATE<@dt AND DAY(@dt+1) = 1 AND MONTH(P.END_DATE) = MONTH(@dt) AND YEAR(P.END_DATE) = YEAR(@dt)))'
  IF @where_sql <> '' 
       SET @sql_str = @sql_str + N' OR ('+ @where_sql + N'))'
  ELSE SET @sql_str = @sql_str + N')'
END

EXEC sp_executesql @sql_str,N'@user_id int,@dt smalldatetime',@user_id,@dt
GO
