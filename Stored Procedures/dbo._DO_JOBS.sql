SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[_DO_JOBS] 
	@flag_mask tinyint = 1,
	@user_id int = 0
AS

SET NOCOUNT ON;

DECLARE @dt smalldatetime

SET @dt = dbo.bank_open_date()

DECLARE 
	@acc_id int,
	@job_id int,
	@param_str varchar(255),
	@sp_name sysname

DECLARE cc CURSOR LOCAL FAST_FORWARD
FOR
SELECT A.ACC_ID, J.REC_ID, ISNULL(A.PARAM_STR,''), J.SP_NAME
FROM dbo.ACCOUNTS_JOBS A (NOLOCK)
	INNER JOIN dbo.JOBS J (NOLOCK) ON A.JOB_ID = J.REC_ID
WHERE (A.JOB_FLAGS & @flag_mask <> 0) AND (A.START_DATE <= @dt) AND (A.END_DATE IS NULL OR A.END_DATE >= @dt) AND (
  (A.FREQ_TYPE=0) OR /* every day */
  (A.FREQ_TYPE=1 AND (DAY(@dt) IN (10,20) OR DAY(@dt+1) = 1)) OR /* every decade */
  (A.FREQ_TYPE=2 AND DAY(@dt+1) = 1) OR /* every month */
  (A.FREQ_TYPE=4 AND MONTH(@dt) IN (3,6,9,12) AND DAY(@dt+1) = 1) OR /* every quorter */
  (A.FREQ_TYPE=5 AND MONTH(@dt) IN (6,12) AND DAY(@dt+1) = 1) OR /* every semester */
  (A.FREQ_TYPE=6 AND DATENAME(weekday,@dt) = 'Sunday') OR /* every week (sunday) */
  (A.FREQ_TYPE=3 AND @dt = A.END_DATE)  /* at the end */
)
FOR READ ONLY

OPEN cc
IF @@ERROR <> 0  GOTO RollBackThisTrans

FETCH NEXT FROM cc INTO @acc_id, @job_id, @param_str, @sp_name
IF @@ERROR <> 0 GOTO RollBackThisTrans

WHILE @@FETCH_STATUS = 0
BEGIN
  DECLARE 
    @sql nvarchar(512),
    @r int

  SET @sql = N'EXEC ' + @sp_name + N' @acc_id,@job_id'
  IF @param_str <> '' 
    SET @sql = @sql + N',' + REPLACE(@param_str,'@user_id', LTRIM(str(@user_id)))
  EXEC @r = sp_executesql @sql, N'@acc_id int,@job_id int', @acc_id,@job_id
  IF @@ERROR <> 0 OR @r <> 0RETURN (1)

  FETCH NEXT FROM cc INTO @acc_id, @job_id, @param_str, @sp_name
  IF @@ERROR <> 0 GOTO RollBackThisTrans
END

IF @@FETCH_STATUS <> -1
BEGIN
  RAISERROR ('FETCH STATUS ERROR',16,1)
  GOTO RollBackThisTrans
END

CLOSE cc
DEALLOCATE cc

RETURN (0)

RollBackThisTrans:

CLOSE cc
DEALLOCATE cc
RETURN (1)
GO
