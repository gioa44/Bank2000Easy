SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[LOAN_FN_PAYMENT_MUST_BE_DELAYED]
(@loan_id int,
 @payment_date smalldatetime,
 @next_payment_date smalldatetime)

RETURNS bit

AS
BEGIN

DECLARE
    @delay bit,
	@days_remaining int,
	@payment_interval money,
	@interval_days int

SELECT @payment_interval = lpi.INTERVAL FROM dbo.LOANS l
INNER JOIN dbo.LOAN_PAYMENT_INTERVALS lpi ON l.PAYMENT_INTERVAL_TYPE = lpi.TYPE_ID
WHERE l.LOAN_ID = @loan_id

SET @days_remaining = DATEDIFF(DAY, @payment_date, @next_payment_date)

IF @payment_interval < 1
	SET @interval_days = CONVERT(int, FLOOR(@payment_interval * 100))
ELSE 
	SET @interval_days = CONVERT(int, FLOOR(@payment_interval * 30))

IF @days_remaining < CONVERT(int, FLOOR(@interval_days / 2))
	SET @delay = 1
ELSE 
	SET @delay = 0

  RETURN (@delay)
END
GO
