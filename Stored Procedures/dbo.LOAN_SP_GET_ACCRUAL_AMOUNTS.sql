SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GET_ACCRUAL_AMOUNTS]
	@loan_id									int,
	@disburse_type								int,
    @date										smalldatetime,
	@schedule_control							bit = 1, -- დარიცხული პროცენტი დაანგარიშდეს გრაფიკის პროცენტიდან  1, თუ დარჩენილი ძირიდან 0
	@schedule_date								smalldatetime,
	@end_date									smalldatetime, 
	@schedule_interest							money,
	@schedule_nu_interest						money,
	@schedule_balance							money,
	@schedule_pay_interest						bit,
	@schedule_nu_interest_correction			money,
	@schedule_interest_correction				money,	


	@calc_date									smalldatetime,
	@prev_step									smalldatetime,
	@interest_flags								int,
	@penalty_flags								int,
	@nu_intrate									money, -- გამოუყენებელ თანხაზე დარიცხული პროცენტი
	@intrate									money, -- საპროცენტო განაკვეთი
	@basis										int,
	@penalty_intrate							money, -- საჯარიმო პროცენტი
	@penalty_delta								bit = 0,


	/*ძირითადი თანხები */
	@nu_principal								money,
	@principal									money,
	@late_principal								money,
	@overdue_principal							money,
	@calloff_principal							money,
	@writeoff_principal							money,
	/*End ძირითადი თანხები */

	/*პროცენტები*/
	@late_percent								money,
	@overdue_percent							money,
	@calloff_percent							money,
	@writeoff_percent							money,
	/*End პროცენტები*/

	@nu_interest								money OUTPUT, 
	@nu_interest_daily							money OUTPUT,
	@nu_interest_fraction						TFRACTION OUTPUT,

	@interest									money OUTPUT,
	@interest_daily								money OUTPUT,
	@interest_fraction							TFRACTION OUTPUT, 
	
	@overdue_principal_interest					money OUTPUT,
	@overdue_principal_interest_daily			money OUTPUT,
	@overdue_principal_interest_fraction		TFRACTION OUTPUT,
	@overdue_principal_penalty					money OUTPUT,
	@overdue_principal_penalty_daily			money OUTPUT,
	@overdue_principal_penalty_fraction			TFRACTION OUTPUT,
	@overdue_percent_penalty					money OUTPUT,
	@overdue_percent_penalty_daily				money OUTPUT,
	@overdue_percent_penalty_fraction			TFRACTION OUTPUT,

	@calloff_principal_interest					money OUTPUT,
	@calloff_principal_interest_daily			money OUTPUT,
	@calloff_principal_interest_fraction		TFRACTION OUTPUT,
	@calloff_principal_penalty					money OUTPUT,
	@calloff_principal_penalty_daily			money OUTPUT,
	@calloff_principal_penalty_fraction			TFRACTION OUTPUT,
	@calloff_percent_penalty					money OUTPUT,
	@calloff_percent_penalty_daily				money OUTPUT,
	@calloff_percent_penalty_fraction			TFRACTION OUTPUT,

	@writeoff_principal_penalty					money OUTPUT,
	@writeoff_principal_penalty_daily			money OUTPUT,
	@writeoff_principal_penalty_fraction		TFRACTION OUTPUT,
	@writeoff_percent_penalty					money OUTPUT,
	@writeoff_percent_penalty_daily				money OUTPUT,	
	@writeoff_percent_penalty_fraction			TFRACTION OUTPUT
AS
SET NOCOUNT ON

DECLARE
	@tmp_money money,
	@fraction decimal(28, 15)

IF (@calc_date > @date) OR (@prev_step > @date)
	RETURN 0

IF @interest_flags & 0x0001 <> 0  --ძირითად თანხაზე პროცენტის დარიცხვა
BEGIN
	IF @prev_step < '20070921' AND @loan_id <= 100112421 AND @schedule_control = 1 AND @disburse_type <> 4
	BEGIN
		IF (@schedule_date IS NULL) OR (@schedule_date > @date)
		BEGIN
			SET @nu_interest = ISNULL(@nu_interest, $0.00)
			SET @interest = ISNULL(@interest, $0.00)

			SET @fraction = convert(decimal(28, 15), @nu_principal) * DATEDIFF(dd, @calc_date, @date) * @nu_intrate / @basis / 100 + @nu_interest_fraction
			SET @nu_interest_daily = ROUND(@fraction, 2, 1)
			SET @nu_interest = @nu_interest + @nu_interest_daily
			SET @nu_interest_fraction = @fraction - ROUND(@fraction, 2, 1)

			SET @fraction = convert(decimal(28, 15), @principal) * DATEDIFF(dd, @calc_date, @date) * @intrate / @basis / 100 + @interest_fraction
			SET @interest_daily = ROUND(@fraction, 2, 1)
			SET @interest = @interest + @interest_daily
			SET @interest_fraction = @fraction - ROUND(@fraction, 2, 1)
		END
		ELSE
		BEGIN
			SET @tmp_money = @nu_interest
			SET @nu_interest = ISNULL(@schedule_nu_interest, $0.00)
			SET @nu_interest_daily = ISNULL(@schedule_nu_interest, $0.00) - @tmp_money
			SET @nu_interest_fraction = $0.00
			
			SET @tmp_money = @interest
			SET @interest = ISNULL(@schedule_interest, $0.00)
			SET @interest_daily = ISNULL(@schedule_interest, $0.00) - @tmp_money
			SET @interest_fraction = $0.00
		END
	END
	ELSE
	BEGIN
	IF @schedule_control = 1 AND @disburse_type <> 4 -- დაერიცხოს გრაფიკის მიხედვით
	BEGIN
		IF @schedule_date > @date
		BEGIN
			SET	@schedule_nu_interest_correction = ISNULL(@schedule_nu_interest_correction, $0.00)
	
			SET @fraction = convert(decimal(28, 15), (@schedule_nu_interest - @schedule_nu_interest_correction)) * DATEDIFF(dd, @prev_step, @date) / DATEDIFF(dd, @prev_step, @schedule_date) + @schedule_nu_interest_correction + @nu_interest_fraction
			SET @tmp_money = @nu_interest
			SET @nu_interest = ROUND(@fraction, 2, 1)
			SET @nu_interest_daily = @nu_interest - @tmp_money
			SET @nu_interest_fraction = @fraction - ROUND(@fraction, 2, 1)

			SET	@schedule_interest_correction = ISNULL(@schedule_interest_correction, $0.00)
			SET @fraction = convert(decimal(28, 15), (@schedule_interest - @schedule_interest_correction)) * DATEDIFF(dd, @prev_step, @date) / DATEDIFF(dd, @prev_step, @schedule_date) + @schedule_interest_correction + @interest_fraction
			SET @tmp_money = @interest
			SET @interest = ROUND(@fraction, 2, 1)
			SET @interest_daily = @interest - @tmp_money
			SET @interest_fraction = @fraction - ROUND(@fraction, 2, 1)
		END
		ELSE
		BEGIN
			SET @tmp_money = @nu_interest
			SET @nu_interest = @schedule_nu_interest
			SET @nu_interest_daily = @schedule_nu_interest - @tmp_money
			SET @nu_interest_fraction = $0.00
			
			SET @tmp_money = @interest
			SET @interest = @schedule_interest
			SET @interest_daily = @schedule_interest - @tmp_money
			SET @interest_fraction = $0.00
		END		
	END
	ELSE
	BEGIN -- დაერიცხოს დღეების მიხედვით
		IF @date < @end_date
		BEGIN
			SET @fraction = convert(decimal(28, 15), @nu_principal) * DATEDIFF(dd, @calc_date, @date) * @nu_intrate / @basis / 100 + @nu_interest_fraction
			SET @nu_interest_daily = ROUND(@fraction, 2, 1)
			SET @nu_interest = @nu_interest + @nu_interest_daily
			SET @nu_interest_fraction = @fraction - ROUND(@fraction, 2, 1)
		END

		SET @fraction = convert(decimal(28, 15), @principal) * DATEDIFF(dd, @calc_date, @date) * @intrate / @basis / 100 + @interest_fraction
		SET @interest_daily = ROUND(@fraction, 2, 1)
		SET @interest = @interest + @interest_daily
		SET @interest_fraction = @fraction - ROUND(@fraction, 2, 1)
	END
	END 
END

IF @interest_flags & 0x0002 <> 0 --ვადაგადაცლებულ ძირითად თანხაზე  პროცენტის დარიცხვა
BEGIN
	SET @fraction = (convert(decimal(28, 15), @late_principal) + convert(decimal(28, 15), @overdue_principal)) * DATEDIFF(dd, @calc_date, @date) * @intrate / @basis / 100 + @overdue_principal_interest_fraction
	SET @overdue_principal_interest_daily = ROUND(@fraction, 2, 1)
	SET @overdue_principal_interest = @overdue_principal_interest + @overdue_principal_interest_daily
	SET @overdue_principal_interest_fraction = @fraction - ROUND(@fraction, 2, 1)
END

IF @interest_flags & 0x0004 <> 0 --გამოთხოვილ ძირითად თანხაზე  პროცენტის დარიცხვა
BEGIN
	SET @fraction = @calloff_principal * DATEDIFF(dd, @calc_date, @date) * @intrate / @basis / 100 + @calloff_principal_interest_fraction
	SET @calloff_principal_interest_daily = ROUND(@fraction, 2, 1)
	SET @calloff_principal_interest = @calloff_principal_interest + @calloff_principal_interest_daily
	SET @calloff_principal_interest_fraction = @fraction - ROUND(@fraction, 2, 1)
END

IF @penalty_flags & 0x0001 <> 0 --ვადაგადაცლებულ ძირითად თანხაზე  ჯარიმის დარიცხვა
BEGIN
	IF @penalty_delta = 1
	BEGIN
		SET @fraction = (convert(decimal(28, 15), @late_principal) + convert(decimal(28, 15), @overdue_principal)) * DATEDIFF(dd, @calc_date, @date) * ABS(@penalty_intrate - (@intrate / @basis)) / 100 + @overdue_principal_penalty_fraction
		SET @overdue_principal_penalty_daily = ROUND(@fraction, 2, 1)
		SET @overdue_principal_penalty = @overdue_principal_penalty + @overdue_principal_penalty_daily
		SET @overdue_principal_penalty_fraction = @fraction - ROUND(@fraction, 2, 1)
	END
	ELSE
	BEGIN
		SET @fraction = (convert(decimal(28, 15), @late_principal) + convert(decimal(28, 15), @overdue_principal)) * DATEDIFF(dd, @calc_date, @date) * @penalty_intrate / 100 + @overdue_principal_penalty_fraction
		SET @overdue_principal_penalty_daily = ROUND(@fraction, 2, 1)
		SET @overdue_principal_penalty = @overdue_principal_penalty + @overdue_principal_penalty_daily
		SET @overdue_principal_penalty_fraction = @fraction - ROUND(@fraction, 2, 1)
	END
END

IF @penalty_flags & 0x0002 <> 0 --ვადაგადაცილებულ პროცენტზე ჯარიმის დარიცხვა
BEGIN
	SET @fraction = (convert(decimal(28, 15), @late_percent) + convert(decimal(28, 15), @overdue_percent)) * DATEDIFF(dd, @calc_date, @date) * @penalty_intrate / 100 + @overdue_percent_penalty_fraction
	SET @overdue_percent_penalty_daily = ROUND(@fraction, 2, 1)
	SET @overdue_percent_penalty = @overdue_percent_penalty + @overdue_percent_penalty_daily
	SET @overdue_percent_penalty_fraction = @fraction - ROUND(@fraction, 2, 1)
END

IF @penalty_flags & 0x0004 <> 0 --გამოთხოვილ ძირითად თანხაზე  ჯარიმის დარიცხვა
BEGIN
	IF @penalty_delta = 1
	BEGIN
		SET @fraction = @calloff_principal * DATEDIFF(dd, @calc_date, @date) * ABS(@penalty_intrate - (@intrate / @basis)) / 100 + @calloff_principal_penalty_fraction
		SET @calloff_principal_penalty_daily = ROUND(@fraction, 2, 1)
		SET @calloff_principal_penalty = @calloff_principal_penalty + @calloff_principal_penalty_daily
		SET @calloff_principal_penalty_fraction = @fraction - ROUND(@fraction, 2, 1)
	END
	ELSE
	BEGIN
		SET @fraction = @calloff_principal * DATEDIFF(dd, @calc_date, @date) * @penalty_intrate / 100 + @calloff_principal_penalty_fraction
		SET @calloff_principal_penalty_daily = ROUND(@fraction, 2, 1)
		SET @calloff_principal_penalty = @calloff_principal_penalty + @calloff_principal_penalty_daily
		SET @calloff_principal_penalty_fraction = @fraction - ROUND(@fraction, 2, 1)
	END
END

IF @penalty_flags & 0x0008 <> 0 --გამოთხოვილ პროცენტზე  ჯარიმის დარიცხვა
BEGIN
	SET @fraction = @calloff_percent * DATEDIFF(dd, @calc_date, @date) * @penalty_intrate / 100 + @calloff_percent_penalty_fraction
	SET @calloff_percent_penalty_daily = ROUND(@fraction, 2, 1)
	SET @calloff_percent_penalty = @calloff_percent_penalty + @calloff_percent_penalty_daily
	SET @calloff_percent_penalty_fraction = @fraction - ROUND(@fraction, 2, 1)
END

IF @penalty_flags & 0x0010 <> 0 --ჩამოწერილ ძირითად თანხაზე  ჯარიმის დარიცხვა
BEGIN
	SET @fraction = @writeoff_principal * DATEDIFF(dd, @calc_date, @date) * @penalty_intrate / 100 + @writeoff_principal_penalty_fraction
	SET @writeoff_principal_penalty_daily = ROUND(@fraction, 2, 1)
	SET @writeoff_principal_penalty = @writeoff_principal_penalty + @writeoff_principal_penalty_daily
	SET @writeoff_principal_penalty_fraction = @fraction - ROUND(@fraction, 2, 1)
END

IF @penalty_flags & 0x0020 <> 0 --ჩამოწერილ პროცენტზე  ჯარიმის დარიცხვა
BEGIN
	SET @fraction = @writeoff_percent * DATEDIFF(dd, @calc_date, @date) * @penalty_intrate / 100 + @writeoff_percent_penalty_fraction
	SET @writeoff_percent_penalty_daily = ROUND(@fraction, 2, 1)
	SET @writeoff_percent_penalty = @writeoff_percent_penalty + @writeoff_percent_penalty_daily
	SET @writeoff_percent_penalty_fraction = @fraction - ROUND(@fraction, 2, 1)
END

GO
