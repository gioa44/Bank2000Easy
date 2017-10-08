SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[acc_unblock_amount] (
	@acc_id int,
	@product_id varchar(20),
	@iso TISO,
	@amount money,
	@fee money,
	@user_id int,
	@doc_rec_id int
)
AS

SET NOCOUNT ON;

DECLARE 
	@block_id int,
	@r int

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

SELECT TOP 1 @block_id = BLOCK_ID
FROM dbo.ACCOUNTS_BLOCKS 
WHERE ACC_ID = @acc_id AND BLOCKED_BY_PRODUCT = @product_id AND ISO = @iso AND AMOUNT = @amount AND FEE = @fee
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

EXEC @r = dbo.acc_unblock_amount_by_id @acc_id, @block_id, @user_id, @doc_rec_id
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
