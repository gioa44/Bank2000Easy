SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[payments_get_tariff](@provider_id int, @service_id varchar(20), @chanel_id int, @amount money, @is_full_amount bit = 0)
RETURNS money
AS
BEGIN
	
	DECLARE
		@tariff_percent TPERCENT,
		@tariff_min_amount money,
		@tariff_amount money,
		@multiplier money

	SELECT @multiplier = CHANNEL_PERCENT
	FROM	dbo.PAYMENT_CHANNELS (NOLOCK)
	WHERE CHANNEL_ID = @chanel_id

	SET @multiplier = $1.00 + ISNULL(@multiplier, $0) / $100

	SELECT	@tariff_percent = TARIFF_PERCENT, @tariff_min_amount = TARIFF_MIN_AMOUNT
	FROM	dbo.PAYMENT_PROVIDER_SERVICES (NOLOCK)
	WHERE	PROVIDER_ID = @provider_id AND SERVICE_ALIAS = @service_id

	SET @tariff_percent = ISNULL(@tariff_percent, $0.0000) * @multiplier
	SET @tariff_min_amount = ISNULL(@tariff_min_amount, $0.0000) * @multiplier

	IF @is_full_amount = 0
		SET @tariff_amount = @amount * @tariff_percent / 100
	ELSE
		BEGIN
			SET @tariff_amount = @tariff_min_amount
			IF @tariff_percent > $0 AND @amount > @tariff_min_amount * (1 + 100 / @tariff_percent)
				SET @tariff_amount = (@amount * @tariff_percent) / 100
		END

	IF @tariff_amount < @tariff_min_amount
		SET @tariff_amount = @tariff_min_amount
	SET @tariff_amount = ROUND(@tariff_amount, 2)
	IF @tariff_amount < $0.000
		SET @tariff_amount = $0.0000

	RETURN @tariff_amount
END
GO
