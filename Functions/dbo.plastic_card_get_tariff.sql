SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[plastic_card_get_tariff](@card_type tinyint, @card_category char(3), @client_category char(3), @merchant_id int, @amount TAMOUNT, @ccy TISO, @dt smalldatetime)
RETURNS TAMOUNT
BEGIN
	DECLARE
		@result TAMOUNT,
		@percent TAMOUNT,
		@min_amount TAMOUNT,
		@fee_amount TAMOUNT,
		@atm_fee smallint,
		@pos_fee smallint,
		@imprinter_fee smallint,
		@merchant_type tinyint

	SELECT	@percent = FEE_PERCENT, @min_amount = FEE_MIN_AMOUNT, @merchant_type = MERCHANT_TYPE
	FROM dbo.PLASTIC_CARD_MERCHANTS
	WHERE MERCHANT_ID = @merchant_id

	SET @min_amount = @min_amount * dbo.get_cross_rate('GEL', @ccy, @dt)
	SET @result = $0.00
	SET @fee_amount = @amount * @percent / 100
	IF @fee_amount < @min_amount
		SET @fee_amount = @min_amount

	SET @result = @fee_amount

	IF @card_category <> '000'
	BEGIN
		SELECT @atm_fee=ATM_FEE, @pos_fee=POS_FEE, @imprinter_fee=IMPRINTER_FEE
		FROM dbo.PLASTIC_CARD_CATEGORY
		WHERE CARD_CATEGORY = @card_category

		IF @merchant_type = 1
			SET @result = @result + @fee_amount * @atm_fee / 100
		ELSE
		IF @merchant_type = 2
			SET @result = @result + @fee_amount * @pos_fee / 100
		ELSE
		IF @merchant_type = 3
			SET @result = @result + @fee_amount * @imprinter_fee / 100
	END

	IF @client_category <> '000'
	BEGIN
		SELECT @atm_fee=ATM_FEE, @pos_fee=POS_FEE, @imprinter_fee=IMPRINTER_FEE
		FROM dbo.PLASTIC_CARD_CLIENT_CATEGORY
		WHERE CLIENT_CATEGORY = @client_category

		IF @merchant_type = 1
			SET @result = @result + @fee_amount * @atm_fee / 100
		ELSE
		IF @merchant_type = 2
			SET @result = @result + @fee_amount * @pos_fee / 100
		ELSE
		IF @merchant_type = 3
			SET @result = @result + @fee_amount * @imprinter_fee / 100
	END

	IF @card_type > 0
	BEGIN
		SELECT @atm_fee=ATM_FEE, @pos_fee=POS_FEE, @imprinter_fee=IMPRINTER_FEE
		FROM dbo.CCARD_TYPES
		WHERE REC_ID = @card_type

		IF @merchant_type = 1
			SET @result = @result + @fee_amount * @atm_fee / 100
		ELSE
		IF @merchant_type = 2
			SET @result = @result + @fee_amount * @pos_fee / 100
		ELSE
		IF @merchant_type = 3
			SET @result = @result + @fee_amount * @imprinter_fee / 100
	END

	IF @result < 0
		SET @result = 0

	RETURN @result

END
GO
