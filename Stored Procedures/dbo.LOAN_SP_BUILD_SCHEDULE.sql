SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_BUILD_SCHEDULE]
	@loan_id				int,
	@loan_amount			money,				
	@intrate				money,
	@step_lenght			money,
	@start_date				smalldatetime,
	@close_date				smalldatetime,
	@payment_interval_type  int,
	@payment_day			tinyint,
	@grace_steps			smallint,
	@grace_type				tinyint,
	@basis					smallint,
	@schedule_type			tinyint,
	@round_value			money,
	@installment			bit,
	@nu_principal			money,
	@notused_intrate		money,
	@pmt					money OUTPUT

	
AS
SET NOCOUNT ON

DECLARE @T TABLE(
	PAYMENT_NO		int NOT NULL,
	LOAN_ID			int NOT NULL,
	SCHEDULE_DATE	smalldatetime NOT NULL,
	AMOUNT			money NOT NULL,
	PRINCIPAL		money NOT NULL,
	INTEREST        money NOT NULL,
	NU_INTEREST     money NOT NULL,
	BALANCE			money NOT NULL)--,
	--PRIMARY KEY (LOAN_ID, SCHEDULE_DATE))
	

DECLARE
	@system_first_date tinyint
SET @system_first_date = @@DATEFIRST
DECLARE
	@number_of_payments		smallint,
	@payment_interval		money,
	@interval				smallint,
	@period					smallint

SET @number_of_payments	= 0

SELECT @payment_interval=INTERVAL FROM dbo.LOAN_PAYMENT_INTERVALS (NOLOCK) WHERE TYPE_ID=@payment_interval_type
IF @payment_interval < 1
BEGIN
	SET @interval = CONVERT(int, FLOOR(@payment_interval * 100))
	SET @period = DATEDIFF(dd, @start_date, @close_date)
	SET @number_of_payments = @period / @interval
    IF (@period % @interval) >= (@interval / 2)
      SET @number_of_payments = @number_of_payments + 1
END
ELSE
BEGIN
    SET @interval = CONVERT(int, FLOOR(@payment_interval))
	SET @number_of_payments = DATEDIFF(mm, @start_date, @close_date) / @interval
	IF DATEDIFF(dd, DATEADD(mm, DATEDIFF(mm, @start_date, @close_date), @start_date), @close_date) >= 15 
      SET @number_of_payments = @number_of_payments + 1
END

DECLARE
	@first_payment_day	smalldatetime,
	@day_diff			tinyint

IF @step_lenght < $1.00
BEGIN
	SET @first_payment_day = DATEADD(dd, CONVERT(int, FLOOR(@step_lenght * 100)), @start_date)
	SET DATEFIRST 7
	IF @payment_day <> DATEPART(dw, @first_payment_day)
	BEGIN
		IF @payment_day = 0
			SET @day_diff = 0
		ELSE
	    BEGIN
			IF @payment_day < DATEPART(dw, @first_payment_day)
				SET @day_diff = DATEPART(dw, @first_payment_day) - @payment_day
			ELSE
				SET @day_diff = 7 - (@payment_day - DATEPART(dw, @first_payment_day))
		END
	END
	SET @first_payment_day = DATEADD(dd, -@day_diff, @first_payment_day)
END
ELSE
BEGIN
	SET @first_payment_day = DATEADD(mm, CONVERT(int, FLOOR(@step_lenght)), @start_date)
/*	IF @step_lenght = 255
		SET @first_payment_day = DATEADD(dd, -DAY(DATEADD(mm, 1, @first_payment_day)), DATEADD(mm, 1, @first_payment_day))
	BEGIN

	END

SELECT DATEADD(mm, 1, '20070130')

SELECT DAY(DATEADD(dd, -DAY(DATEADD(mm, 1, '20070131')), DATEADD(mm, 1, '20070131')))
  
PaymDay := EOM(FirstPaymDate, params.PaymentDay);

  IF DAY(@start_date) <> PaymDay then
  BEGIN
	FirstPaymDay := ExtractDay(FirstPaymDate);
  if FirstPaymDay < PaymDay then
  begin
    BackDate := IncMonth(FirstPaymDate, -1);
    PaymDay := EOM(BackDate, params.PaymentDay);
    BackDate := ChangeDay(BackDate, PaymDay);

    Difference := DaysBetween(BackDate + 1, FirstPaymDate);
    if Difference < GraceDays then
      Result := BackDate
    else
    begin
      PaymDay := EOM(FirstPaymDate, params.PaymentDay);
      Result := ChangeDay(FirstPaymDate, PaymDay);
    end
  end
  else
  begin
    DaysBack := FirstPaymDay - PaymDay;
    if DaysBack < GraceDays then
      Result := ChangeDay(FirstPaymDate, PaymDay)
    else
    begin
      ForwardDate := IncMonth(FirstPaymDate, 1);
      ForwardDate := ChangeDay(ForwardDate, PaymDay);
      Result := ForwardDate;
    end;
  end;*/
END

  

DECLARE
	@I int

SET @I = 1
WHILE @I <= @number_of_payments
BEGIN
	INSERT INTO @T(PAYMENT_NO,LOAN_ID,SCHEDULE_DATE,AMOUNT,PRINCIPAL,INTEREST,NU_INTEREST,BALANCE)
	VALUES(@I,@loan_id,'20070101',$0.00,$0.00,$0.00,$0.00,$0.00)
	set @I = @I + 1
END

SELECT * FROM @T
RETURN 0
GO
