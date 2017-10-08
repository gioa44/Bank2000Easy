SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[BCC_CHECK_ACC_LIMITS] 
  @bc_login_id int,
  @acc_id int,
  @amount TAMOUNT,
  @doc_date smalldatetime,
  @lat bit = 0
AS

SET NOCOUNT ON

DECLARE
  @limit_type tinyint,
  @limit_period tinyint,
  @limit_value TAMOUNT,
  @sum TAMOUNT,
  @dt1 smalldatetime,
  @dt2 smalldatetime

-- Check acc limits

DECLARE L_CURSOR CURSOR LOCAL
FOR

SELECT L.LIMIT_TYPE, L.LIMIT_PERIOD, L.LIMIT_VALUE
FROM dbo.BC_LOGIN_ACC_LIMITS L (NOLOCK)
	INNER JOIN dbo.BC_LOGIN_ACC A (NOLOCK) ON A.REC_ID = L.REC_ID
WHERE A.ACC_ID = @acc_id
FOR READ ONLY

OPEN L_CURSOR
FETCH NEXT FROM L_CURSOR INTO @limit_type, @limit_period, @limit_value

WHILE @@FETCH_STATUS = 0
BEGIN
  DECLARE @limit_err_str varchar(100)

  IF @limit_type = 2
  BEGIN
    SET @amount = 1
    IF @lat = 0 
         SET @limit_err_str = '<ERR>ÀÍÂÀÒÉÛÉÓ ËÉÌÉÔÉÓ ÃÀÒÙÅÄÅÀ (ÂÀÃÀÒÉÝáÅÉÓ ÌÀØÓÉÌÀËÖÒÉ ÒÀÏÃÄÍÏÁÀ) - [' + ltrim(str(@limit_period)) + ':' + ltrim(str(@limit_value)) +  ']</ERR>'
    ELSE SET @limit_err_str = '<ERR>Excess of account limit (maximum number of transfers) - [' + ltrim(str(@limit_period)) + ':' + ltrim(str(@limit_value)) +  ']</ERR>'
  END
  ELSE
  BEGIN
    IF @lat = 0 
         SET @limit_err_str = '<ERR>ÀÍÂÀÒÉÛÉÓ ËÉÌÉÔÉÓ ÃÀÒÙÅÄÅÀ (ÂÀÃÀÒÉÝáÅÉÓ ÌÀØÓÉÌÀËÖÒÉ ÈÀÍáÀ) - [' + ltrim(str(@limit_period)) + ':' + ltrim(str(@limit_value)) +  ']</ERR>'
    ELSE SET @limit_err_str = '<ERR>Excess of account limit (maximum amount of transfer) - [' + ltrim(str(@limit_period)) + ':' + ltrim(str(@limit_value)) +  ']</ERR>'
  END

  IF @limit_period = 0 -- one time
  BEGIN
    IF @amount > @limit_value
    BEGIN
      RAISERROR(@limit_err_str,16,1)
      RETURN (1)
    END
  END
  ELSE
  IF @limit_period = 1 -- dayly
  BEGIN
    SELECT @sum = CASE WHEN @limit_type <> 2 THEN SUM(D.AMOUNT) ELSE COUNT(*) END
    FROM dbo.OPS_0000 D (NOLOCK)
    WHERE D.BNK_CLI_ID = @bc_login_id AND D.DOC_DATE = @doc_date AND D.DEBIT_ID = @acc_id

    IF ISNULL(@sum,$0.00) + @amount > @limit_value
    BEGIN
      RAISERROR(@limit_err_str,16,1)
      RETURN (2)
    END
  END
  ELSE
  IF @limit_period = 2 -- weekly
  BEGIN
    SET @dt1 = DATEADD(week,DATEPART(week,@doc_date)-1,
                 DATEADD(year,DATEPART(year,@doc_date)-2000,'01/01/2000'))
    SET @dt2 = @dt1 + 7

    SELECT @sum = CASE WHEN @limit_type <> 2 THEN SUM(D.AMOUNT) ELSE COUNT(*) END
    FROM dbo.OPS_FULL D (NOLOCK)
    WHERE D.BNK_CLI_ID = @bc_login_id AND D.DOC_DATE BETWEEN @dt1 AND @dt2 AND D.DEBIT_ID = @acc_id

    IF ISNULL(@sum,$0.00) + @amount > @limit_value
    BEGIN
      RAISERROR(@limit_err_str,16,1)
      RETURN (3)
    END
  END
  ELSE
  IF @limit_period = 3 -- monthly
  BEGIN
    SET @dt1 = DATEADD(month,DATEPART(month,@doc_date)-1,
                 DATEADD(year,DATEPART(year,@doc_date)-2000,'01/01/2000'))
    SET @dt2 = DATEADD(month,1,@dt1)

    SELECT @sum = CASE WHEN @limit_type <> 2 THEN SUM(D.AMOUNT) ELSE COUNT(*) END
    FROM dbo.OPS_FULL D (NOLOCK)
    WHERE D.BNK_CLI_ID = @bc_login_id AND D.DOC_DATE BETWEEN @dt1 AND @dt2 AND D.DEBIT_ID = @acc_id

    IF ISNULL(@sum,$0.00) + @amount > @limit_value
    BEGIN
      RAISERROR(@limit_err_str,16,1)
      RETURN (4)
    END
  END
  ELSE
  IF @limit_period = 4 -- trimestral
  BEGIN
    SET @dt1 = DATEADD(month,3*DATEPART(month,@doc_date),
                 DATEADD(year,DATEPART(year,@doc_date)-2000,'01/01/2000'))
    SET @dt2 = DATEADD(month,3,@dt1)

    SELECT @sum = CASE WHEN @limit_type <> 2 THEN SUM(D.AMOUNT) ELSE COUNT(*) END
    FROM dbo.OPS_FULL D (NOLOCK)
    WHERE D.BNK_CLI_ID = @bc_login_id AND D.DOC_DATE BETWEEN @dt1 AND @dt2 AND D.DEBIT_ID = @acc_id

    IF ISNULL(@sum,$0.00) + @amount > @limit_value
    BEGIN
      RAISERROR(@limit_err_str,16,1)
      RETURN (5)
    END
  END
  ELSE
  IF @limit_period = 5 -- semestral
  BEGIN
    SET @dt1 = DATEADD(month,6*DATEPART(month,@doc_date),
                 DATEADD(year,DATEPART(year,@doc_date)-2000,'01/01/2000'))
    SET @dt2 = DATEADD(month,6,@dt1)

    SELECT @sum = CASE WHEN @limit_type <> 2 THEN SUM(D.AMOUNT) ELSE COUNT(*) END
    FROM dbo.OPS_FULL D (NOLOCK)
    WHERE D.BNK_CLI_ID = @bc_login_id AND D.DOC_DATE BETWEEN @dt1 AND @dt2 AND D.DEBIT_ID = @acc_id

    IF ISNULL(@sum,$0.00) + @amount > @limit_value
    BEGIN
      RAISERROR(@limit_err_str,16,1)
      RETURN (6)
    END
  END
  ELSE
  IF @limit_period = 6 -- yearly
  BEGIN
    SET @dt1 = DATEADD(year,DATEPART(year,@doc_date)-2000,'01/01/2000')
    SET @dt2 = DATEADD(year,1,@dt1)

    SELECT @sum = CASE WHEN @limit_type <> 2 THEN SUM(D.AMOUNT) ELSE COUNT(*) END
    FROM dbo.OPS_FULL D (NOLOCK)
    WHERE D.BNK_CLI_ID = @bc_login_id AND D.DOC_DATE BETWEEN @dt1 AND @dt2 AND D.DEBIT_ID = @acc_id

    IF ISNULL(@sum,$0.00) + @amount > @limit_value
    BEGIN
      RAISERROR(@limit_err_str,16,1)
      RETURN (7)
    END
  END

  FETCH NEXT FROM L_CURSOR INTO @limit_type, @limit_period, @limit_value
END
CLOSE L_CURSOR
DEALLOCATE L_CURSOR
RETURN (0)
GO
