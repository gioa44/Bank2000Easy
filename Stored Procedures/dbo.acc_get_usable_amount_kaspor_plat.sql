SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[acc_get_usable_amount_kaspor_plat]
  @acc_id int,
  @usable_amount TAMOUNT OUTPUT,
  @use_overdraft bit = 1
AS

SET NOCOUNT ON

DECLARE
  @min TAMOUNT,
  @block TAMOUNT,
  @actpas tinyint,
  @client_no int,
  @today smalldatetime,
  @min_amount_check_date smalldatetime

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

SELECT	@client_no=CLIENT_NO, @usable_amount = ISNULL(SALDO, $0) + ISNULL(SHADOW_DBO, $0) - ISNULL(SHADOW_CRO, $0),
		@min = ISNULL(MIN_AMOUNT, $0), @block = ISNULL(BLOCKED_AMOUNT, $0), @actpas = ACT_PAS,
		@min_amount_check_date = MIN_AMOUNT_CHECK_DATE
FROM	dbo.ACC_VIEW (NOLOCK)
WHERE	ACC_ID = @acc_id

IF @today >= @min_amount_check_date AND @min < $0.0000
   SET @min = $0.0000

IF @actpas <> 2
	SET @usable_amount = -@usable_amount 

SET @usable_amount = @usable_amount - @block

IF @min < 0 OR @use_overdraft <> 0
	SET @usable_amount = @usable_amount - @min

IF @client_no IS NULL
  SET @usable_amount = 0

RETURN (0)

GO
