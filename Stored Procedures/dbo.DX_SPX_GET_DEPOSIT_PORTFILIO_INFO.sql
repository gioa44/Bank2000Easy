SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DX_SPX_GET_DEPOSIT_PORTFILIO_INFO]
  @did int, 
  @dt smalldatetime,
  @start_dt smalldatetime,
  @info_flag int,
  @equ bit=0
AS
SET NOCOUNT ON
  DECLARE
    @rc int
  SELECT * INTO #T FROM dbo.DX_VW_DEPOSIT_GEN WHERE DID=@did
  IF @@ROWCOUNT <> 1 GOTO ret

  IF @start_dt IS NULL
    SELECT @start_dt = START_DATE FROM #T

  DECLARE
    @account TACCOUNT,
    @iso TISO
  
  SELECT @account=ACCOUNT, @iso=ISO FROM #T

  DECLARE
    @ri_items int,
    @ri_amount TAMOUNT

  SELECT @ri_items = 1, @ri_amount = 1

  EXEC @rc=dbo.GET_RATE_INFO @iso, @dt, @ri_amount OUTPUT, @ri_items OUTPUT
  IF @rc <> 0 OR @@ERROR <> 0 GOTO ret

  DECLARE
    @rest TAMOUNT,
    @rest_equ TAMOUNT,
    @act_pas tinyint,
    @descrip_geo varchar(100),
    @descrip_lat varchar(100),
    @last_op_date smalldatetime,
    @with_info bit,
    @shadow_level smallint

  DECLARE
    @depo_saldo TAMOUNT,
    @depo_saldo_equ TAMOUNT,
    @close_days int,
    @open_days int,
    @last_prolong_dt smalldatetime,
    @open_days_prolong int,
    @all_calc_amount money,
    @all_calc_amount_equ money,
    @period_calc_amount money,
    @period_calc_amount_equ money,
    @not_realized_calc_amount money,
    @not_realized_calc_amount_equ money,
    @last_calced_date smalldatetime,
    @not_calced_calc_amount money,
    @not_calced_calc_amount_equ money,
    @all_realized_amount money,
    @all_realized_amount_equ money,
    @period_realized_amount money,
    @period_realized_amount_equ money,
    @last_realized_date smalldatetime





  IF @info_flag & 0x00000004 != 0
  BEGIN
    SELECT @last_prolong_dt=MAX(DT) 
    FROM
      dbo.DX_DEPOSIT_OPS
    WHERE DID=@did AND OP_TYPE=30 AND COMMIT_STATE=0xFF 
  END

  IF @info_flag & 0x00000008 != 0
  BEGIN
    SELECT @open_days_prolong=DATEDIFF(day, ISNULL(MAX(DT), @dt), @dt)    
    FROM
      dbo.DX_DEPOSIT_OPS
    WHERE DID=@did AND OP_TYPE=30 AND COMMIT_STATE=0xFF 
  END

  IF @info_flag & 0x00000010 != 0
  BEGIN
    EXEC @rc=dbo.GET_ACC_SALDO @account=@account, @iso=@iso, @dt=@dt, @rest=@depo_saldo OUTPUT, @rest_equ=@depo_saldo_equ OUTPUT, @act_pas=@act_pas, @descrip_geo=@descrip_geo, @descrip_lat=@descrip_lat, @last_op_date=@last_op_date, @with_info=0, @shadow_level=0 
    IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
  END

  IF @info_flag & 0x00000020 != 0
  BEGIN
    SET @all_calc_amount=.0
    SELECT @all_calc_amount=ISNULL(SUM(AMOUNT), 0)
    FROM dbo.DOCS
    WHERE ABS(ACCOUNT_EXTRA)=@account AND ISO=@iso AND DOC_TYPE=30 AND DOC_DATE_IN_DOC<=@dt
    SELECT @all_calc_amount=@all_calc_amount+ISNULL(SUM(AMOUNT), 0)
    FROM dbo.DOCS_ARC
    WHERE ABS(ACCOUNT_EXTRA)=@account AND ISO=@iso AND DOC_TYPE=30 AND DOC_DATE_IN_DOC<=@dt
    IF @equ=1
    BEGIN
      SET @all_calc_amount_equ = @all_calc_amount * @ri_amount / @ri_items
      EXEC @rc=dbo.ROUND_BY_ISO @all_calc_amount_equ, 'GEL', @all_calc_amount_equ OUTPUT
      IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
    END
  END

  IF @info_flag & 0x00000040 != 0
  BEGIN
    SELECT @period_calc_amount=ISNULL(SUM(AMOUNT), 0)
    FROM dbo.DOCS
    WHERE ABS(ACCOUNT_EXTRA)=@account AND ISO=@iso AND DOC_TYPE=30 AND DOC_DATE_IN_DOC<=@dt AND DOC_DATE_IN_DOC>=@start_dt 
    SELECT @period_calc_amount=@period_calc_amount+ISNULL(SUM(AMOUNT), 0)
    FROM dbo.DOCS_ARC
    WHERE ABS(ACCOUNT_EXTRA)=@account AND ISO=@iso AND DOC_TYPE=30 AND DOC_DATE_IN_DOC<=@dt AND DOC_DATE_IN_DOC>=@start_dt
    IF @equ=1
    BEGIN
      SET @period_calc_amount_equ = @period_calc_amount * @ri_amount / @ri_items
      EXEC @rc=dbo.ROUND_BY_ISO @period_calc_amount_equ, 'GEL', @period_calc_amount_equ OUTPUT
      IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
    END
  END

  IF @info_flag & 0x00000080 != 0
  BEGIN
    SELECT @not_realized_calc_amount=ISNULL(ALREADY_CALCED_AMOUNT, 0) FROM dbo.ACCOUNTS_CRED_PERC WHERE ACCOUNT=@account AND ISO=@iso
    IF @equ=1
    BEGIN
      SET @not_realized_calc_amount_equ = @not_realized_calc_amount * @ri_amount / @ri_items
      EXEC @rc=dbo.ROUND_BY_ISO @not_realized_calc_amount_equ, 'GEL', @not_realized_calc_amount_equ OUTPUT
      IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
    END
  END


  IF @info_flag & 0x00000100 != 0
  BEGIN
      SELECT @last_calced_date=MAX(DOC_DATE_IN_DOC)
      FROM dbo.DOCS
      WHERE ISO=@iso AND (DOC_TYPE=30 OR DOC_TYPE=31) AND ABS(ACCOUNT_EXTRA)=@account

    IF @last_calced_date IS NULL
      SELECT @last_calced_date=MAX(DOC_DATE_IN_DOC)
      FROM dbo.DOCS_ARC
      WHERE ISO=@iso AND (DOC_TYPE=30 OR DOC_TYPE=31) AND ABS(ACCOUNT_EXTRA)=@account
  END

  IF @info_flag & 0x00000200 != 0
  BEGIN
    DECLARE
      @start_date smalldatetime,
      @end_date smalldatetime,
      @perc_flags int,
      @formula varchar(512),
      @month_eq_30 bit,
      @max_dt smalldatetime,
      @calced_amount TAMOUNT,
      @days_in_year smallint,
      @end_dt smalldatetime

    SELECT @start_date=START_DATE, @end_date=END_DATE, @formula=FORMULA, @days_in_year=DAYS_IN_YEAR, @perc_flags=PERC_FLAGS
    FROM #T
 
    SELECT @calced_amount=ISNULL(ALREADY_CALCED_AMOUNT, 0) FROM dbo.ACCOUNTS_CRED_PERC WHERE ACCOUNT=@account AND ISO=@iso
  
    --get max date
    SELECT @max_dt=MAX(DOC_DATE_IN_DOC) 
    FROM dbo.DOCS WHERE ISO=@iso AND DOC_DATE_IN_DOC>=@start_date AND (DOC_TYPE=30 OR DOC_TYPE=31) AND ABS(ACCOUNT_EXTRA)=@account
    IF @max_dt IS NULL
      SELECT @max_dt=ISNULL(MAX(DOC_DATE_IN_DOC), @start_date) 
      FROM dbo.DOCS_ARC WHERE ISO=@iso AND DOC_DATE_IN_DOC>=@start_date AND (DOC_TYPE=30 OR DOC_TYPE=31) AND ABS(ACCOUNT_EXTRA)=@account
    SET @max_dt =
      CASE 
        WHEN @max_dt<>@start_date and @max_dt<>@end_date THEN DATEADD(day, 1, @max_dt)
        WHEN @max_dt=@start_date and @perc_flags & 1 <> 0 THEN DATEADD(day, 1, @max_dt)
        ELSE @max_dt
      END
    --End max date

    SET @end_dt =
      CASE 
        WHEN @dt=@end_date and @perc_flags & 2 <> 0 THEN DATEADD(day, -1, @dt)
        ELSE @dt
      END

    IF @max_dt < @end_dt
    BEGIN
      EXEC dbo.GET_DEPO_OVER_PERCENT_AMOUNT @account, @iso, @max_dt, @end_dt, @formula, 0, @not_calced_calc_amount OUTPUT
      IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
      SET @not_calced_calc_amount =(@not_calced_calc_amount / @days_in_year / 100) -- - @calced_amount
      EXEC dbo.ROUND_BY_ISO @not_calced_calc_amount, @iso, @not_calced_calc_amount OUTPUT
      IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
      IF @equ=1
      BEGIN
        SET @not_calced_calc_amount_equ = @not_calced_calc_amount * @ri_amount / @ri_items
        EXEC @rc=dbo.ROUND_BY_ISO @not_calced_calc_amount_equ, 'GEL', @not_calced_calc_amount_equ OUTPUT
        IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
      END
    END
  END

  IF @info_flag & 0x00000400 != 0
  BEGIN
    DECLARE
      @already_payed_amount TAMOUNT
    SELECT @already_payed_amount=ISNULL(ALREADY_PAYED_AMOUNT, 0) FROM dbo.ACCOUNTS_CRED_PERC WHERE ACCOUNT=@account AND ISO=@iso
  
    SELECT @all_realized_amount=ISNULL(SUM(AMOUNT), 0)
    FROM dbo.DOCS
    WHERE ABS(ACCOUNT_EXTRA)=@account AND ISO=@iso AND DOC_TYPE=31 AND DOC_DATE_IN_DOC<=@dt 
    SELECT @all_realized_amount=@all_realized_amount+ISNULL(SUM(AMOUNT), 0)
    FROM dbo.DOCS_ARC
    WHERE ABS(ACCOUNT_EXTRA)=@account AND ISO=@iso AND DOC_TYPE=31 AND DOC_DATE_IN_DOC<=@dt 
    SET @all_realized_amount = @all_realized_amount + @already_payed_amount
    IF @equ=1
    BEGIN
      SET @all_realized_amount_equ = @all_realized_amount * @ri_amount / @ri_items
      EXEC @rc=dbo.ROUND_BY_ISO @all_realized_amount_equ, 'GEL', @all_realized_amount_equ OUTPUT
      IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
    END
  END

  IF @info_flag & 0x00000800 != 0
  BEGIN
    SELECT @period_realized_amount=ISNULL(SUM(AMOUNT), 0)
    FROM dbo.DOCS
    WHERE ABS(ACCOUNT_EXTRA)=@account AND ISO=@iso AND DOC_TYPE=31 AND DOC_DATE_IN_DOC<=@dt AND DOC_DATE_IN_DOC>=@start_dt 
    SELECT @period_realized_amount=@period_realized_amount+ISNULL(SUM(AMOUNT), 0)
    FROM dbo.DOCS_ARC
    WHERE ABS(ACCOUNT_EXTRA)=@account AND ISO=@iso AND DOC_TYPE=31 AND DOC_DATE_IN_DOC<=@dt AND DOC_DATE_IN_DOC>=@start_dt
    IF @equ=1
    BEGIN
      SET @period_realized_amount_equ = @period_realized_amount * @ri_amount / @ri_items
      EXEC @rc=dbo.ROUND_BY_ISO @period_realized_amount_equ, 'GEL', @period_realized_amount_equ OUTPUT
      IF @rc <> 0 OR @@ERROR <> 0 GOTO ret
    END
  END

  IF @info_flag & 0x00001000 != 0
  BEGIN
      SELECT @last_realized_date=MAX(DOC_DATE_IN_DOC)
      FROM dbo.DOCS
      WHERE ISO=@iso AND DOC_TYPE=31 AND ABS(ACCOUNT_EXTRA)=@account

    IF @last_realized_date IS NULL
      SELECT @last_realized_date=MAX(DOC_DATE_IN_DOC)
      FROM dbo.DOCS_ARC
      WHERE ISO=@iso AND DOC_TYPE=31 AND ABS(ACCOUNT_EXTRA)=@account
  END

  SELECT 
    @close_days = CASE WHEN @info_flag & 0x00000001 != 0 THEN DATEDIFF(day, @dt, END_DATE) ELSE NULL END,
    @open_days  = CASE WHEN @info_flag & 0x00000002 != 0 THEN DATEDIFF(day, START_DATE, @dt) ELSE NULL END
  FROM #T

  SELECT  
    @close_days AS CLOSE_DAYS, @open_days AS OPEN_DAYS, @last_prolong_dt AS LAST_PROLONG_DATE, @open_days_prolong AS OPEN_DAYS_PROLONG, -@depo_saldo AS DEPO_SALDO, -@depo_saldo_equ AS DEPO_SALDO_EQU,
    @all_calc_amount AS ALL_CALC_AMOUNT, @all_calc_amount_equ AS ALL_CALC_AMOUNT_EQU,
    @period_calc_amount AS PERIOD_CALC_AMOUNT, @period_calc_amount_equ AS PERIOD_CALC_AMOUNT_EQU, @not_realized_calc_amount AS NOT_REALIZED_CALC_AMOUNT, @not_realized_calc_amount_equ AS NOT_REALIZED_CALC_AMOUNT_EQU,
    @last_calced_date AS LAST_CLACED_DATE, @not_calced_calc_amount AS NOT_CALCED_CALC_AMOUNT, @not_calced_calc_amount_equ AS NOT_CALCED_CALC_AMOUNT_EQU,
    @all_realized_amount AS ALL_REALIZED_AMOUNT, @all_realized_amount_equ AS ALL_REALIZED_AMOUNT_EQU,
    @period_realized_amount AS PERIOD_REALIZED_AMOUNT, @period_realized_amount_equ AS PERIOD_REALIZED_AMOUNT_EQU,
    @last_realized_date AS LAST_REALIZED_DATE

ret:
  DROP TABLE #T
  RETURN(0)
GO
