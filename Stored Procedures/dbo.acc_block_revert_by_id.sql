SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[acc_block_revert_by_id] (
	@acc_id int,
	@user_id int,
	@block_id int
)
AS

SET NOCOUNT ON;

DECLARE
	@amount money,
	@fee money

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

UPDATE dbo.ACCOUNTS_BLOCKS 
SET @amount = AMOUNT, @fee = FEE, IS_ACTIVE = 1, UNBLOCKED_BY_USER = null, UNBLOCK_DATE_TIME = null
WHERE ACC_ID = @acc_id AND BLOCK_ID = @block_id AND IS_ACTIVE = 0
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @amount IS NULL
BEGIN
	RAISERROR('Account Block not found',16,1) 
	IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
	RETURN 1
END

UPDATE dbo.ACCOUNTS
SET BLOCKED_AMOUNT = ISNULL(BLOCKED_AMOUNT, $0.00) + ISNULL(@amount, $0.00) + ISNULL(@fee, $0.00),
	BLOCK_CHECK_DATE = (SELECT MIN(AUTO_UNBLOCK_DATE) FROM dbo.ACCOUNTS_BLOCKS WHERE ACC_ID = @acc_id AND IS_ACTIVE = 1)
WHERE ACC_ID = @acc_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
