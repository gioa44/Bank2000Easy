SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[so_calc_transaction_amount]
	@date datetime, 
	@balance money, 
	@lim_amount money, 
	@is_percent bit,
	@iso TISO,
	@equ_iso TISO,
	@debt_action int,
	@transaction_amount money OUTPUT,
	@is_partial bit OUTPUT,
	@error_code int OUTPUT,
	@error_msg varchar(250) OUTPUT,
	@error_msg_lat varchar(250) OUTPUT
AS

SET @is_partial = 0
SET @error_code = NULL
SET @error_msg = NULL


IF @debt_action = 3 AND (ISNULL(@is_percent, 0) = 0)
BEGIN
	IF (@equ_iso IS NOT NULL AND @lim_amount IS NOT NULL)
		SET @balance = dbo.get_cross_amount(@lim_amount, @equ_iso, @iso, @date)
	ELSE
		SET @balance = ISNULL(@lim_amount, @balance)
END

IF (@lim_amount IS NULL)
BEGIN
	IF (@balance IS NOT NULL)
		SET @transaction_amount = @balance
	ELSE
	BEGIN
		SET @error_code = -1
		SET @error_msg = '<ERR>ÃÀÅÀËÄÁÀ ÀÒÀÓßÏÒÉ ÐÀÒÀÌÄÔÒÄÁÉÈ!</ERR>'
		SET @error_msg_lat = '<ERR>Invalid task parameters!</ERR>'
		RETURN @error_code
	END
	
	RETURN 0
END
	
IF (ISNULL(@is_percent, 0) = 0)
	SET @transaction_amount = @lim_amount
ELSE
	SET @transaction_amount = @balance * (@lim_amount / $100.00)

IF (@equ_iso IS NOT NULL)
	SET @transaction_amount = dbo.get_cross_amount(@transaction_amount, @equ_iso, @iso, @date)

IF (@balance IS NOT NULL)
	IF (@transaction_amount > @balance)
	BEGIN
		SET @transaction_amount = @balance
		SET @is_partial = 1
	END

RETURN 0
GO
