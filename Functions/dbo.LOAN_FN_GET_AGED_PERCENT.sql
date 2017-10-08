SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[LOAN_FN_GET_AGED_PERCENT](
	@loan_id				int,
	@date					smalldatetime,
	@l_ovdpercwroff_days	tinyint)
RETURNS money
AS
BEGIN
	DECLARE
		@aged_percent money,
		@payd_percent money

	SET @aged_percent = $0.00

	IF @l_ovdpercwroff_days = -1
		GOTO _ret

	SELECT @aged_percent = SUM(ISNULL(INTEREST_DAILY, $0.00))
	FROM dbo.LOAN_DETAILS_HISTORY (NOLOCK)
	WHERE LOAN_ID = @loan_id AND CALC_DATE <= DATEADD(DAY, -@l_ovdpercwroff_days, @date)

	SELECT @payd_percent = SUM(INTEREST) + SUM(NU_INTEREST)
	FROM dbo.LOAN_VW_LOAN_OP_PAYMENT_DETAILS (NOLOCK)
	WHERE LOAN_ID = @loan_id

_ret:
	RETURN @aged_percent
END
GO
