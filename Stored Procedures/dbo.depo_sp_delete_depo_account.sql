SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_delete_depo_account]
	@acc_id int,
	@delete_account bit = 1
AS
SET NOCOUNT ON;

DECLARE
	@r int

DECLARE
	@dt smalldatetime,
	@shadow_level smallint,
	@saldo money,
	@saldo_equ money

SET @dt = '20790101'
SET @shadow_level = 0

EXEC @r = dbo.GET_ACC_SALDO4
	@acc_id = @acc_id,
	@dt = @dt,
	@shadow_level = @shadow_level,
	@saldo = @saldo OUTPUT,
	@saldo_equ = @saldo_equ OUTPUT

IF @@ERROR <> 0 OR @r <> 0
	RETURN 101


IF ISNULL(@saldo, $0.00) <> $0.00 OR ISNULL(@saldo_equ, $0.00) <> $0.00
	RETURN 1

IF EXISTS(SELECT * FROM dbo.OPS_HELPER (NOLOCK) WHERE ACC_ID = @acc_id)
	RETURN 2

IF EXISTS(SELECT * FROM dbo.OPS_HELPER_ARC (NOLOCK) WHERE ACC_ID = @acc_id)
	RETURN 2

IF EXISTS(SELECT * FROM dbo.DEPO_DEPOSITS_HISTORY (NOLOCK) WHERE @acc_id IN (DEPO_ACC_ID, LOSS_ACC_ID, ACCRUAL_ACC_ID))
	RETURN 3

IF EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id AND CLIENT_NO IS NULL)
	RETURN 4

IF @delete_account = 1
BEGIN
	DELETE FROM dbo.ACCOUNTS
	WHERE ACC_ID = @acc_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 
		RETURN 102
END

RETURN 0
GO
