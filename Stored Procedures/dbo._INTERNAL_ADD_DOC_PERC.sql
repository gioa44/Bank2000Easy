SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[_INTERNAL_ADD_DOC_PERC]
	@perc_type tinyint,			-- არის თუ არა დარიცხვა დებეტურ ნაშთზე (= 0 კრედიტული დარიცხვა)
	@debit_id int,				-- დებეტის ანგარიში თუ დებეტური დარიცხვაა, თუარადა კრედიტის ანგარიშჲ
	@credit_id int,				-- კრედიტის ანგარიში თუ დებეტური დარიცხვაა, თუარადა დებეტის ანგარიში 
	@amount money,				-- თანხა (თუ უარყოფითია, დებეტი და კრედიტი იცვლიან ადგილს), დამრგვალება 4 ნიშნამდე
	@op_code TOPCODE = '*%%%*',	-- ოპერაციის კოდი
	@descrip varchar(150),		-- დანიშნულება
	@main_acc_id int = null,	-- ძირითადი ანგარიში
	@need_trail bit = 0,		-- ჭირდება თუ არა კვალის დატოვება (როცა @op_code = '*%RL*')
	@tax_rate money = $0.00,	-- დასაბეგრი % (კრედიტული დარიცხვებისათვის)
	@tax_acc_id int = null,		-- დაბეგვრის დარიცხვის ანგარიში (კრედიტული დარიცხვებისათვის)
	@tax_payed money = null,	-- გადახდილი დაბეგრილი სარგებელი (კრედიტული დარიცხვებისათვის)
	@sign smallint = 1			-- არის თუ არა შეტრიალებული
AS

SET NOCOUNT ON

IF @amount = $0.0000
	RETURN

DECLARE @acc_id int

-- ანგარიშების შეცვლა
IF (@perc_type = 1 AND @amount < $0.0000) OR (@perc_type <> 1 AND @amount > $0.0000) 
BEGIN
	SET @acc_id = @debit_id
	SET @debit_id = @credit_id
	SET @credit_id = @acc_id
END

SET @sign = 1
IF (@perc_type = 1 AND @amount > $0.0000) OR (@perc_type <> 1 AND @amount < $0.0000) 
	SET @sign = -1

SET @amount = ABS(@amount)
IF @amount <= $0.0000 RETURN 0

IF @need_trail <> 0		-- კვალის დატოვება
BEGIN
	INSERT INTO #accruals
	SELECT @debit_id, @main_acc_id, @amount, '*%TR*', 'ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉÓ ÒÄÀËÉÆÀÝÉÀ (ÊÅÀËÉ)', @sign

	INSERT INTO #accruals
	SELECT @main_acc_id, @credit_id, @amount, @op_code, @descrip, @sign
END
ELSE
	INSERT INTO #accruals
	SELECT @debit_id, @credit_id, @amount, @op_code, @descrip, @sign

IF @perc_type = 0 AND @op_code = '*%RL*' AND ISNULL(@tax_rate, $0.00) <> $0.00
BEGIN
	SET @amount = ROUND(@amount / $100.0 * @tax_rate, 2)

	IF @tax_payed IS NOT NULL
		SET @amount = @amount - @tax_payed
	IF @amount > $0.0000
	BEGIN
		INSERT INTO #accruals
		SELECT @credit_id, @tax_acc_id, @amount, '*%TX*', 'ÃÀÒÉÝáÖËÉ ÓÀÒÂÄÁËÉÓ ÃÀÁÄÂÅÒÀ', @sign
	END
END
GO
