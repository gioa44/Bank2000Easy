SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_reailze_schedule]
	@depo_amount money,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@date smalldatetime = NULL,
	@intrate money,
	@prod_id int,
	@tax_rate money,
	@result_type tinyint = 0,
	@date_exists bit = NULL OUTPUT
AS

SET NOCOUNT ON;

IF @result_type = 1
	SET @date = ISNULL(@date, @start_date)

DECLARE
    @schema_id smallint,
	@depo_realize_type smallint,
	@basis smallint,
	@interest_realize_type int,
	@realize_count_type int,
	@realize_count int,
	@payment_count int,
	@perc_flags int,
    @first_day	bit,
    @last_day	bit
   

SET @tax_rate = ISNULL(@tax_rate, $0.00)

SELECT @schema_id = REALIZE_SCHEMA, @depo_realize_type = DEPO_REALIZE_SCHEMA, @basis = DAYS_IN_YEAR, @perc_flags = PERC_FLAGS
FROM dbo.DEPO_PRODUCT (NOLOCK)
WHERE PROD_ID = @prod_id 
 

SELECT @realize_count = REALIZE_COUNT, @interest_realize_type = REALIZE_TYPE, @realize_count_type = REALIZE_COUNT_TYPE
FROM dbo.DEPO_PRODUCT_REALIZE_SCHEMA (NOLOCK)
WHERE [SCHEMA_ID] = @schema_id

SET @first_day = (@perc_flags & 1)
SET @last_day = (@perc_flags & 2)

DECLARE
	@reg_payment money

DECLARE
	@daily_interest float,
	@daily_interest_ float,
	@schedule_date   smalldatetime,
	@schedule_prev_date smalldatetime,
	@schedule_next_date smalldatetime,
	@schedule_extra_date smalldatetime,
	@month tinyint
DECLARE @helper TABLE
(
	STEP_ID int identity(1, 1) NOT NULL PRIMARY KEY,
	SCHEDULE_DATE smalldatetime NOT NULL,
	PERIOD_INTEREST float NOT NULL,
	PERIOD_INTEREST_ float NOT NULL 
)

DECLARE @schedule TABLE
(
	SCHEDULE_DATE smalldatetime NOT NULL PRIMARY KEY,
	PAYMENT money NOT NULL,
	PRINCIPAL money NOT NULL,
	INTEREST  money NOT NULL,
	INTEREST_TAX money NOT NULL,
	TAX money NOT NULL,
	BALANCE money NULL
 )

SET @schedule_extra_date = NULL
SET @daily_interest = @intrate / (@basis * 100.00)

IF @depo_realize_type = 5 -- თუ არის "დაბეგრილ სარგებელთან ერთად თანაბარი თანხები"
	SET @daily_interest_ = @intrate / (@basis * 100.00) * (1 - (@tax_rate / 100.00))
ELSE
	SET @daily_interest_ = @daily_interest

SET @schedule_date = @start_date

IF (@depo_realize_type = 1) AND (@interest_realize_type = 2) AND (@realize_count_type = 0)
	GOTO _skip

WHILE @schedule_date < @end_date
BEGIN
	SET @schedule_prev_date = @schedule_date
    IF @schedule_date = @start_date AND DATEPART(DAY, @start_date) <= 15 SET @month = 1
	ELSE SET @month=0

	SET @schedule_date =
		CASE 
			WHEN @interest_realize_type = 1 AND @realize_count_type = 1 THEN DATEADD(day, @realize_count, @schedule_date)
			WHEN @interest_realize_type = 1 AND @realize_count_type = 3 THEN DATEADD(day, @realize_count * 30, @schedule_date)
			WHEN @interest_realize_type = 1 AND @realize_count_type = 2 THEN DATEADD(month, @realize_count, @schedule_date)	
			WHEN @interest_realize_type = 2 THEN DATEADD(month, @realize_count + 1 - @month,(@schedule_date - DATEPART(day , @schedule_date) + 1)) - 1	
        END  	

	SET @schedule_next_date =
		CASE @realize_count_type
			WHEN 1 THEN DATEADD(day, @realize_count, @schedule_date)
			WHEN 3 THEN DATEADD(day, @realize_count * 30, @schedule_date)
			WHEN 2 THEN DATEADD(month, @realize_count, @schedule_date)
         END

	IF  @schedule_next_date <= @end_date
	BEGIN
        IF (@schedule_prev_date = @start_date) AND (@first_day = 0)
			INSERT INTO @helper(SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_)
			SELECT @schedule_date, DATEDIFF(day, @schedule_prev_date, @schedule_date) * @daily_interest  + @daily_interest, DATEDIFF(day, @schedule_prev_date, @schedule_date) * @daily_interest_
		ELSE
			INSERT INTO @helper(SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_)
			SELECT @schedule_date, DATEDIFF(day, @schedule_prev_date, @schedule_date) * @daily_interest, DATEDIFF(day, @schedule_prev_date, @schedule_date) * @daily_interest_ + @daily_interest_
	END
	ELSE
	BEGIN
		IF DATEDIFF(day, @schedule_date, @end_date) < DATEDIFF(day, @end_date, @schedule_next_date)
		BEGIN
			SET	@schedule_extra_date = @schedule_date	
			SET @schedule_date = @end_date
            IF @last_day = 1
				INSERT INTO @helper(SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_)
				SELECT @end_date, DATEDIFF(day, @schedule_prev_date, @end_date) * @daily_interest - @daily_interest, DATEDIFF(day, @schedule_prev_date, @end_date) * @daily_interest_ - @daily_interest_
			ELSE
				INSERT INTO @helper(SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_)
				SELECT @end_date, DATEDIFF(day, @schedule_prev_date, @end_date) * @daily_interest, DATEDIFF(day, @schedule_prev_date, @end_date) * @daily_interest_
		END
		ELSE 
		BEGIN
            IF @last_day = 1
            BEGIN
				INSERT INTO @helper(SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_)
				SELECT @schedule_date, DATEDIFF(day, @schedule_prev_date, @schedule_date) * @daily_interest , DATEDIFF(day, @schedule_prev_date, @schedule_date) * @daily_interest_

				INSERT INTO @helper (SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_)
				SELECT @end_date, DATEDIFF(day, @schedule_date, @end_date) * @daily_interest - @daily_interest, DATEDIFF(day, @schedule_date, @end_date) * @daily_interest_ - @daily_interest_
				SET @schedule_date = @end_date
            END
			ELSE
			BEGIN				
				INSERT INTO @helper(SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_)
				SELECT @schedule_date, DATEDIFF(day, @schedule_prev_date, @schedule_date) * @daily_interest,DATEDIFF(day, @schedule_prev_date, @schedule_date) * @daily_interest_

				INSERT INTO @helper (SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_)
				SELECT @end_date, DATEDIFF(day, @schedule_date, @end_date) * @daily_interest, DATEDIFF(day, @schedule_date, @end_date) * @daily_interest_
				SET @schedule_date = @end_date
			END
		END
	END
END

_skip:
SELECT @payment_count = COUNT(*) FROM @helper

DECLARE
	@P float,
	@S float

DECLARE
	@principal money,
	@period_interest money,
	@balance money,
	@interest money,
	@interest_tax money,
	@tax money

DECLARE	
	@cc_step_id int,
	@cc_schedule_date smalldatetime,
	@cc_period_interest float,
	@cc_period_interest_ float

SET @balance = @depo_amount
SET @reg_payment = $0.00

IF @depo_realize_type IN (1, 2)
BEGIN
	IF (@depo_realize_type = 1) AND (@interest_realize_type = 2) AND (@realize_count_type = 0)
	BEGIN
		SET @interest = @depo_amount * @daily_interest * (DATEDIFF(day, @start_date, @end_date) - 1 + CASE WHEN @first_day = 0 THEN 1 ELSE 0 END + CASE WHEN @last_day = 0 THEN 1 ELSE 0 END) 
		SET @tax = ROUND(@interest * @tax_rate / 100.00, 2) 
		SET @interest_tax = @interest - @tax

		INSERT INTO @schedule(SCHEDULE_DATE, PAYMENT, PRINCIPAL, INTEREST, INTEREST_TAX, TAX, BALANCE)
		VALUES(@end_date, @depo_amount + @interest, @depo_amount, @interest, @interest_tax, @tax, $0.00)
	END
	ELSE
	BEGIN
		SET @principal = @balance

		DECLARE cc_12 CURSOR
		FOR SELECT STEP_ID, SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_
		FROM @helper
		ORDER BY STEP_ID

		OPEN cc_12

		FETCH NEXT FROM cc_12 INTO @cc_step_id, @cc_schedule_date, @cc_period_interest, @cc_period_interest_ 
	 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF (@cc_step_id = @payment_count) AND (@depo_realize_type = 1)
				SET @principal = @balance
			ELSE
				SET @principal = $0.00

			SET @interest = ROUND(@balance * @cc_period_interest, 2)
			SET @tax = ROUND(@interest * @tax_rate / 100.00, 2) 
			SET @interest_tax = @interest - @tax
			
			SET @balance = @balance - @principal

			SET @reg_payment = @principal + @interest

			INSERT INTO @schedule(SCHEDULE_DATE, PAYMENT, PRINCIPAL, INTEREST, INTEREST_TAX, TAX, BALANCE)
			VALUES(@cc_schedule_date, @reg_payment, @principal, @interest, @interest_tax, @tax, @balance)

			FETCH NEXT FROM cc_12 INTO @cc_step_id, @cc_schedule_date, @cc_period_interest, @cc_period_interest_ 
		END
			
		CLOSE cc_12
		DEALLOCATE cc_12
	END
END

IF @depo_realize_type = 3
BEGIN
	SET @principal = ROUND(@depo_amount / @payment_count, 2)

	DECLARE cc_3 CURSOR
	FOR SELECT STEP_ID, SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_
	FROM @helper
	ORDER BY STEP_ID

	OPEN cc_3

	FETCH NEXT FROM cc_3 INTO @cc_step_id, @cc_schedule_date, @cc_period_interest, @cc_period_interest_ 
 
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF @cc_step_id = @payment_count
			SET @principal = @balance

		SET @interest = ROUND(@balance * @cc_period_interest, 2)
		SET @tax = ROUND(@interest * @tax_rate / 100.00, 2) 
		SET @interest_tax = @interest - @tax
		
		SET @balance = @balance - @principal

		SET @reg_payment = @principal + @interest

		INSERT INTO @schedule(SCHEDULE_DATE, PAYMENT, PRINCIPAL, INTEREST, INTEREST_TAX, TAX, BALANCE)
		VALUES(@cc_schedule_date, @reg_payment, @principal, @interest, @interest_tax, @tax, @balance)

		FETCH NEXT FROM cc_3 INTO @cc_step_id, @cc_schedule_date, @cc_period_interest, @cc_period_interest_ 
	END
		
	CLOSE cc_3
	DEALLOCATE cc_3
END

IF @depo_realize_type IN (4, 5) 
BEGIN 
	SET @P = 1
	SET @S = 0

	SELECT @P = @P * (1 + PERIOD_INTEREST_), @S = @S + CASE WHEN STEP_ID > 1 THEN @P ELSE $0.00 END
	FROM @helper 
	ORDER BY STEP_ID DESC

    SET @reg_payment = ROUND(@depo_amount * @P / (1 + @S), 2)   

	DECLARE cc_45 CURSOR
	FOR SELECT STEP_ID, SCHEDULE_DATE, PERIOD_INTEREST, PERIOD_INTEREST_
	FROM @helper
	ORDER BY STEP_ID

	OPEN cc_45

	FETCH NEXT FROM cc_45 INTO @cc_step_id, @cc_schedule_date, @cc_period_interest, @cc_period_interest_ 
 
	WHILE @@FETCH_STATUS = 0
    BEGIN
		SET @interest = ROUND(@balance * @cc_period_interest, 2)
		SET @tax = ROUND(@interest * @tax_rate / 100.00, 2) 
		SET @interest_tax = @interest - @tax


		IF @cc_step_id < @payment_count
		BEGIN
			IF @depo_realize_type = 4 
				SET @principal = @reg_payment - @interest
			ELSE
				SET @principal = @reg_payment - @interest_tax
		END
		ELSE
		BEGIN
			SET @principal = @balance 
			IF @depo_realize_type = 4 
				SET @reg_payment = @principal + @interest
			ELSE
				SET @reg_payment = @principal + @interest_tax
		END

		SET @balance = @balance - @principal

		IF (@principal < 0) OR (@principal < 0) BEGIN CLOSE cc_45 DEALLOCATE cc_45 RETURN 1 END

		INSERT INTO @schedule(SCHEDULE_DATE, PAYMENT, PRINCIPAL, INTEREST, INTEREST_TAX, TAX, BALANCE)
		VALUES(@cc_schedule_date, @reg_payment, @principal, @interest, @interest_tax, @tax, @balance)

		FETCH NEXT FROM cc_45 INTO @cc_step_id, @cc_schedule_date, @cc_period_interest, @cc_period_interest_ 
	END
		
	CLOSE cc_45
	DEALLOCATE cc_45
END

SELECT TOP 1 @reg_payment = CASE WHEN @depo_realize_type in (4, 5) THEN PAYMENT ELSE PRINCIPAL END
FROM @schedule

IF (@schedule_extra_date IS NOT NULL) AND (@schedule_extra_date < @end_date)
BEGIN
	DECLARE
		@schedule_extra_balance money,
		@schedule_extra_interest money
		
	SET @schedule_extra_balance =ISNULL((SELECT TOP 1 BALANCE FROM @schedule WHERE SCHEDULE_DATE < @schedule_extra_date ORDER BY SCHEDULE_DATE DESC), @depo_amount)    
	SET @schedule_extra_interest =ROUND((SELECT INTEREST FROM @schedule WHERE SCHEDULE_DATE = @end_date) - @schedule_extra_balance * DATEDIFF(day ,@schedule_extra_date, @end_date) * @daily_interest, 2)
	
	INSERT INTO @schedule(SCHEDULE_DATE, PAYMENT, PRINCIPAL, INTEREST, INTEREST_TAX, TAX, BALANCE)
	VALUES (@schedule_extra_date, @schedule_extra_interest, 0, @schedule_extra_interest, ROUND(@schedule_extra_interest * (100.00 - @tax_rate) / 100.00,2 ), ROUND(@schedule_extra_interest * @tax_rate / 100.00, 2), @schedule_extra_balance)
	
	UPDATE @schedule
	SET PAYMENT = PAYMENT - CASE  WHEN @depo_realize_type = 5 THEN @schedule_extra_interest * (100.00 - @tax_rate) / 100.00 ELSE @schedule_extra_interest END,
	    INTEREST = INTEREST - @schedule_extra_interest,
	    INTEREST_TAX = INTEREST_TAX - ROUND(@schedule_extra_interest * (100.00 - @tax_rate) / 100.00, 2),
	    TAX = TAX - ROUND((@schedule_extra_interest * @tax_rate / 100.00), 2)
	WHERE SCHEDULE_DATE = @end_date
END

  
IF @result_type = 0
	SELECT @reg_payment AS REG_PAYMENT
ELSE
IF @result_type = 1
BEGIN
	INSERT INTO @schedule(SCHEDULE_DATE, PAYMENT, PRINCIPAL, INTEREST, INTEREST_TAX, TAX, BALANCE)
	SELECT '20790101', SUM(PAYMENT), SUM(PRINCIPAL), SUM(INTEREST), SUM(INTEREST_TAX), SUM(TAX), NULL
	FROM @schedule

	SELECT *
	FROM @schedule
	WHERE SCHEDULE_DATE >= @date
	ORDER BY SCHEDULE_DATE
END
ELSE
IF @result_type IN (2, 3)
BEGIN
	IF EXISTS(SELECT * FROM @schedule WHERE SCHEDULE_DATE = @date)
		SET @date_exists = 1
	ELSE
		SET @date_exists = 0

	IF @result_type = 2
		SELECT @date_exists AS DATE_EXISTS
END

RETURN 0
GO
