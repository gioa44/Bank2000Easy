SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[acc_get_usable_amount]
	@acc_id int,
	@usable_amount money OUTPUT,
	@use_overdraft bit = 1
AS

SET NOCOUNT ON

DECLARE
	@min money,
	@block money,
	@min_amount_check_date smalldatetime,
	@actpas tinyint,
	@today smalldatetime

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

SELECT @usable_amount = ISNULL(SALDO, $0) + ISNULL(SHADOW_DBO, $0) - ISNULL(SHADOW_CRO, $0),
		@min = ISNULL(MIN_AMOUNT, $0), @block = ISNULL(BLOCKED_AMOUNT, $0), @actpas = ACT_PAS,
		@min_amount_check_date = MIN_AMOUNT_CHECK_DATE
FROM dbo.ACCOUNTS A (NOLOCK)
	INNER JOIN dbo.ACCOUNTS_DETAILS AD (NOLOCK) ON AD.ACC_ID = A.ACC_ID
WHERE A.ACC_ID = @acc_id

IF @today >= @min_amount_check_date AND @min < $0.0000
   SET @min = $0.0000

IF @actpas <> 2
	SET @usable_amount = -@usable_amount 

SET @usable_amount = @usable_amount - @block

IF @min > 0 OR @use_overdraft <> 0
	SET @usable_amount = @usable_amount - @min

RETURN (0)
GO
