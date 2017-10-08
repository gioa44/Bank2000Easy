SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[acc_unblock_amount_by_id_partial] (
	@acc_id int,
	@block_id int,
	@user_id int,
	@amount money
)
AS

SET NOCOUNT ON;

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE 
	@r int,
	@e int

UPDATE dbo.ACCOUNTS_BLOCKS
SET AMOUNT = AMOUNT - @amount
WHERE BLOCK_ID = @block_id

SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
IF @r = 0
BEGIN
	RAISERROR('Account Block not found',16,1) 
	IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
	RETURN 1
END

UPDATE dbo.ACCOUNTS_BLOCKS
SET IS_ACTIVE = 0, UNBLOCKED_BY_USER = @user_id, UNBLOCK_DATE_TIME = GETDATE()
WHERE BLOCK_ID = @block_id AND AMOUNT = $0.00

IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN 1; END

UPDATE dbo.ACCOUNTS
SET BLOCKED_AMOUNT = ISNULL(BLOCKED_AMOUNT, $0.00) - ISNULL(@amount, $0.00)
WHERE ACC_ID = @acc_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
