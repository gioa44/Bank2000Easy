SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[get_cross_rate] (@iso1 TISO, @iso2 TISO, @dt smalldatetime)
RETURNS DECIMAL(12,8)
BEGIN
	DECLARE
		@result DECIMAL(12,4),
		@rate_amount DECIMAL(12,4),
		@iso TISO

IF @iso1 = 'GEL' AND @iso2 = 'GEL'
	RETURN 1

IF @iso1 = 'GEL' OR @iso2 = 'GEL'
BEGIN
	IF @iso1 = 'GEL'
		SELECT @result = 1 / (AMOUNT / ITEMS)
		FROM  dbo.VAL_RATES
		WHERE ISO = @iso2 AND DT = (SELECT MAX(DT) FROM VAL_RATES WHERE (ISO = @iso2) AND (DT <= @dt))
	ELSE
		SELECT @result = AMOUNT / ITEMS
		FROM  dbo.VAL_RATES
		WHERE ISO = @iso1 AND DT = (SELECT MAX(DT) FROM VAL_RATES WHERE (ISO = @iso1) AND (DT <= @dt))

END
ELSE
BEGIN
	SELECT @result = AMOUNT / ITEMS
	FROM  dbo.VAL_RATES
	WHERE ISO = @iso1 AND DT = (SELECT MAX(DT) FROM VAL_RATES WHERE (ISO = @iso1) AND (DT <= @dt))

	SELECT @rate_amount = AMOUNT / ITEMS
	FROM  dbo.VAL_RATES
	WHERE ISO = @iso2 AND DT = (SELECT MAX(DT) FROM VAL_RATES WHERE (ISO = @iso2) AND (DT <= @dt))

	SET @result = @result / @rate_amount

END

	RETURN @result

END
GO
