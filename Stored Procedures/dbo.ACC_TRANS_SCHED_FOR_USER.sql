SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ACC_TRANS_SCHED_FOR_USER]
  @user_id int,
  @all_recs bit = 0,
  @dt smalldatetime
AS

SET NOCOUNT ON

DECLARE @sql_str nvarchar(2000)

IF @all_recs = 1
BEGIN
  SET @sql_str = 
  'SELECT P.ACC_ID,P.REC_ID FROM dbo.ACCOUNTS_TRANS_SCHED P(NOLOCK) INNER JOIN dbo.ACCOUNTS A(NOLOCK) ON A.ACC_ID=P.ACC_ID
   WHERE P.DT=@dt'
END

ELSE

BEGIN
  DECLARE @where_sql varchar(1000)
  SELECT @where_sql = WHERE_SQL_ACC FROM USER_SQL WHERE [USER_ID] = @user_id
  SET @where_sql = ISNULL(@where_sql,'')

  SET @sql_str = 
  'SELECT P.ACC_ID,P.REC_ID FROM dbo.ACCOUNTS_TRANS_SCHED P(NOLOCK) INNER JOIN dbo.ACCOUNTS A(NOLOCK) ON 
    (A.ACC_ID IN (SELECT ACC_ID FROM dbo.ACCOUNTS_USR WHERE [USER_ID]=@user_id OR [USER_ID] IN (SELECT USER_ID_2 FROM dbo.USER_RELATIONS WHERE [USER_ID]=@user_id AND FLAGS & 2 <> 0)))
   WHERE P.DT=@dt'
  IF @where_sql <> '' 
    SET @sql_str = @sql_str + N' OR ('+ @where_sql + N')'
END

EXEC sp_executesql @sql_str,N'@user_id int,@dt smalldatetime',@user_id,@dt
GO
