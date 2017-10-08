SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CHECK_SALDO]
	@acc_id int,
	@doc_date smalldatetime,
	@op_code TOPCODE = null,
	@doc_type smallint = 0,
	@doc_rec_id int = null,
	@lat bit = 0
AS

SET NOCOUNT ON

DECLARE 
	@r int,
	@effective_saldo money

DECLARE
	@need_check bit,
	@min money,
	@block money,
	@min_amount_check_date smalldatetime,
	@is_offbalance bit,
	@act_pas tinyint

SELECT 
	@need_check = CASE WHEN MIN_AMOUNT IS NULL THEN 0 ELSE 1 END,
	@min = ISNULL(MIN_AMOUNT, $0.0000), 
	@block = ISNULL(BLOCKED_AMOUNT, $0.0000),
	@act_pas = ACT_PAS,
	@is_offbalance = IS_OFFBALANCE,
	@min_amount_check_date = MIN_AMOUNT_CHECK_DATE
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

--IF @need_check = 0 /* OR @is_offbalance = 1 */ RETURN (0)
IF @need_check = 0 OR @is_offbalance = 1 RETURN (0)

IF @doc_date >= @min_amount_check_date AND @min < $0.0000
   SET @min = $0.0000

SET @effective_saldo = NULL
EXEC @r = dbo.ON_USER_BEFORE_CHECK_SALDO @effective_saldo OUTPUT, @acc_id, @doc_date, @op_code, @doc_type, @doc_rec_id, @lat
IF @@ERROR <> 0 OR @r <> 0 RETURN (1)

IF @effective_saldo IS NULL
BEGIN
	SELECT @effective_saldo = ISNULL(SALDO_AVAILABLE, $0.0000)
	FROM dbo.ACCOUNTS_DETAILS(NOLOCK)
	WHERE ACC_ID = @acc_id
END

IF @act_pas <> 2 /*  not Active account */
  SET @effective_saldo = - @effective_saldo

--IF (@is_credit = 0) AND (@act_pas <> 2)
--  SET @delta = $0
--ELSE
--IF (@is_credit = 1) AND (@act_pas = 2)
--  SET @delta = 0

IF @effective_saldo - @block < @min
BEGIN
	DECLARE @acc_str varchar(30)
	SET @acc_str = dbo.acc_get_account_ccy(@acc_id)
	IF @lat = 0
		RAISERROR ('<ERR>ÀÍÂÀÒÉÛÆÄ %s ÀÒ ÀÒÉÓ ÓÀÊÌÀÒÉÓÉ ÍÀÛÈÉ</ERR>',16,1,@acc_str)
	ELSE RAISERROR ('<ERR>There''s not enough funds on account %s to complete operation</ERR>',16,1,@acc_str)
  RETURN (1)
END
RETURN (0)


GO
